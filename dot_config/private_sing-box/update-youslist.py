#!/usr/bin/env python3
"""Build a deduplicated Pi-hole list from the two YousList source files."""

import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import urllib.request
from datetime import datetime, timezone


SOURCES = {
    "hosts": "https://raw.githubusercontent.com/yous/YousList/master/hosts.txt",
    "browser": "https://raw.githubusercontent.com/yous/YousList/master/youslist.txt",
}
DATABASE = Path("/etc/pihole/gravity.db")
OUTPUT = Path("/etc/pihole/local-adlists/youslist-korea.txt")
ADDRESS = OUTPUT.as_uri()
COMMENT = "Korean ads - YousList sources only - deduplicated domain snapshot"
DOMAIN = re.compile(r"(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?")


def valid_domain(value):
    value = value.lower()
    if not DOMAIN.fullmatch(value):
        return None
    try:
        ipaddress.ip_address(value)
    except ValueError:
        return value
    return None


def extract(hosts_text, browser_text):
    hosts = set()
    for line in hosts_text.splitlines():
        parts = line.split("#", 1)[0].split()
        if parts and parts[0] in {"0.0.0.0", "127.0.0.1", "::", "::1"}:
            hosts.update(d for raw in parts[1:] if (d := valid_domain(raw)))
    browser = set()
    exceptions = set()
    for line in browser_text.splitlines():
        line = line.strip()
        # Do not broaden paths, wildcards, resource/site restrictions, or cosmetics.
        match = re.fullmatch(r"\|\|([A-Za-z0-9.-]+)\^", line)
        if match and (domain := valid_domain(match.group(1))):
            browser.add(domain)
        match = re.match(r"@@\|\|([A-Za-z0-9.-]+)(?:\^|/|\$|$)", line)
        if match and (domain := valid_domain(match.group(1))):
            exceptions.add(domain)
    # Keep the maintainer's explicit hosts export. Conservatively omit browser-only
    # additions whose domain tree has an exception in the browser source.
    additions = {
        d for d in browser - hosts
        if not any(d == e or d.endswith("." + e) or e.endswith("." + d)
                   for e in exceptions)
    }
    return hosts | additions, {"hosts_domains": len(hosts),
                              "unconditional_browser_domains": len(browser),
                              "browser_only_additions": len(additions)}


def fetch_sources():
    data = {}
    for name, url in SOURCES.items():
        request = urllib.request.Request(url, headers={"User-Agent": "YousList-Pi-hole-converter/1"})
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read(4 * 1024 * 1024 + 1)
        if len(raw) > 4 * 1024 * 1024:
            raise RuntimeError("Unexpectedly large source: " + name)
        data[name] = raw.decode("utf-8-sig")
    candidates, counts = extract(data["hosts"], data["browser"])
    if len(candidates) < 100:
        raise RuntimeError("Unexpectedly small source; existing list was not changed")
    counts["source_unique_domains"] = len(candidates)
    counts["source_sha256"] = {
        name: hashlib.sha256(text.encode()).hexdigest() for name, text in data.items()
    }
    return candidates, counts


def other_blocks(connection, own_id):
    domains = {r[0] for r in connection.execute(
        "SELECT DISTINCT domain FROM vw_gravity WHERE adlist_id != ? "
        "AND (group_id=0 OR group_id IS NULL)", (own_id,))}
    domains.update(r[0] for r in connection.execute(
        "SELECT DISTINCT d.domain FROM domainlist d "
        "JOIN domainlist_by_group g ON g.domainlist_id=d.id "
        "WHERE d.enabled=1 AND d.type=1 AND g.group_id=0"))
    return domains


def write_list(domains, counts):
    OUTPUT.parent.mkdir(mode=0o755, exist_ok=True)
    os.chmod(OUTPUT.parent, 0o755)
    header = [
        "# Korean ads: YousList - exact hostnames for Pi-hole",
        "# Attribution: YousList contributors; https://github.com/yous/YousList",
        "# License: CC BY 4.0; https://creativecommons.org/licenses/by/4.0/",
        "# Source: " + SOURCES["hosts"],
        "# Source: " + SOURCES["browser"],
        "# Generated UTC: " + datetime.now(timezone.utc).isoformat(),
        "# Regenerate: sudo /usr/local/sbin/update-youslist",
        "# " + json.dumps(counts, sort_keys=True),
        "# Plain hostnames only; no localhost, paths, cosmetics, or conditional rules.",
    ]
    fd, temporary = tempfile.mkstemp(prefix=".youslist-", dir=OUTPUT.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write("\n".join(header + sorted(domains)) + "\n")
        os.chmod(temporary, 0o644)
        os.replace(temporary, OUTPUT)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def rebuild():
    result = subprocess.run(["pihole", "-g"], text=True, capture_output=True, timeout=180)
    if result.returncode:
        raise RuntimeError("Pi-hole gravity rebuild failed: " + result.stdout[-2500:] + result.stderr[-1000:])


def main():
    if os.geteuid() != 0:
        raise SystemExit("Run with sudo on an OCI Pi-hole server")
    candidates, counts = fetch_sources()
    with sqlite3.connect(DATABASE, timeout=30) as connection:
        assert connection.execute('SELECT enabled FROM "group" WHERE id=0').fetchone() == (1,)
        row = connection.execute("SELECT id FROM adlist WHERE address=? AND type=0", (ADDRESS,)).fetchone()
        own_id = row[0] if row else -1
        selected = candidates - other_blocks(connection, own_id)
    counts["already_blocked"] = len(candidates) - len(selected)
    counts["output_domains"] = len(selected)
    write_list(selected, counts)
    with sqlite3.connect(DATABASE, timeout=30) as connection:
        connection.execute(
            "INSERT INTO adlist(address,enabled,comment,type) VALUES(?,1,?,0) "
            "ON CONFLICT(address,type) DO UPDATE SET enabled=1,comment=excluded.comment",
            (ADDRESS, COMMENT))
        own_id = connection.execute("SELECT id FROM adlist WHERE address=? AND type=0", (ADDRESS,)).fetchone()[0]
        connection.execute("INSERT OR IGNORE INTO adlist_by_group(adlist_id,group_id) VALUES(?,0)", (own_id,))
    # A rebuild may update other subscribed lists. Recalculate overlap against
    # the newly downloaded data before accepting the result.
    for attempt in range(3):
        rebuild()
        with sqlite3.connect(DATABASE, timeout=30) as connection:
            revised = candidates - other_blocks(connection, own_id)
            rows = [r[0] for r in connection.execute("SELECT domain FROM gravity WHERE adlist_id=?", (own_id,))]
            if revised == selected:
                if len(rows) != len(set(rows)) or set(rows) != selected:
                    raise RuntimeError("Imported list does not match the generated file")
                counts["adlist_id"] = own_id
                print(json.dumps(counts, sort_keys=True))
                return
        selected = revised
        counts["already_blocked"] = len(candidates) - len(selected)
        counts["output_domains"] = len(selected)
        write_list(selected, counts)
    raise RuntimeError("Other subscriptions kept changing; run the refresh command again")


if __name__ == "__main__":
    main()
