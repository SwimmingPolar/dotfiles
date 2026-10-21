#!/usr/bin/env node
// Installs claude-codex-bridge for Claude Desktop and Codex on this Mac.
//
//   node install.mjs             show the plan, ask, then install
//   node install.mjs --yes       install without asking
//   node install.mjs --dry-run   only show the plan
//   node install.mjs --uninstall remove the bridge from both apps
//
// Every config file it touches is backed up first (<file>.bak-<timestamp>).

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SERVER = path.join(HERE, 'server.mjs');
const CONFIG = path.join(HERE, 'bridge.config.json');
const HOME = os.homedir();
const DESKTOP_CONFIG = path.join(HOME, 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json');
const CODEX_HOME = process.env.CODEX_HOME || path.join(HOME, '.codex');
const CODEX_CONFIG = path.join(CODEX_HOME, 'config.toml');
const SKILL_SRC_DIR = path.join(HERE, 'skills', 'work-with-claude');
const SKILL_DEST_DIR = path.join(HOME, '.agents', 'skills', 'work-with-claude');
const OLD_SKILL_DIRS = [path.join(HOME, '.agents', 'skills', 'consult-claude')]; // earlier name of the same skill
const DESKTOP_NAME = 'codex_bridge';
const CODEX_NAME = 'claude_bridge';
const STAMP = new Date().toISOString().replace(/[:.]/g, '-');

const args = new Set(process.argv.slice(2));
const DRY = args.has('--dry-run');
const YES = args.has('--yes') || args.has('-y');
const UNINSTALL = args.has('--uninstall');

const say = (s = '') => process.stdout.write(s + '\n');
const ok = (s) => say(`  ✓ ${s}`);
const warn = (s) => say(`  ! ${s}`);

function findExecutable(name) {
  const dirs = (process.env.PATH || '').split(':').filter(Boolean);
  const extra = [
    path.join(HOME, '.local', 'bin'), path.join(HOME, '.claude', 'local'), path.join(HOME, '.npm-global', 'bin'),
    path.join(HOME, '.homebrew', 'bin'), '/opt/homebrew/bin', '/usr/local/bin', path.join(HOME, '.bun', 'bin'),
  ];
  for (const dir of [...dirs, ...extra]) {
    const p = path.join(dir, name);
    try {
      fs.accessSync(p, fs.constants.X_OK);
      if (fs.statSync(p).isFile()) return p;
    } catch { /* keep looking */ }
  }
  return null;
}

function version(bin, envPath) {
  try {
    return execFileSync(bin, ['--version'], { encoding: 'utf8', timeout: 20000, stdio: ['ignore', 'pipe', 'ignore'], env: { ...process.env, PATH: envPath } }).trim().split('\n')[0];
  } catch (err) {
    return null;
  }
}

function backup(file) {
  if (!fs.existsSync(file)) return null;
  const dest = `${file}.bak-${STAMP}`;
  fs.copyFileSync(file, dest);
  return dest;
}

function tomlString(s) {
  return JSON.stringify(s); // JSON escapes are valid TOML basic-string escapes
}

// Remove [mcp_servers.<name>] and its sub-tables from a TOML document.
function removeTomlServer(text, name) {
  const lines = text.split('\n');
  const out = [];
  const header = /^\s*\[\[?\s*([^\]]+?)\s*\]\]?\s*(#.*)?$/;
  const keys = new Set([`mcp_servers.${name}`, `mcp_servers."${name}"`]);
  let skipping = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const m = header.exec(line);
    if (m) {
      const key = m[1].replace(/\s+/g, '');
      skipping = [...keys].some((k) => key === k || key.startsWith(k + '.'));
      if (skipping) {
        // also drop our own marker comment right above the table
        if (out.length && out[out.length - 1].startsWith('# Added by claude-codex-bridge')) out.pop();
        continue;
      }
    }
    if (!skipping) out.push(line);
  }
  return out.join('\n').replace(/\n{3,}/g, '\n\n');
}

function codexBlock(node) {
  return [
    '# Added by claude-codex-bridge (install.mjs). Lets Codex consult Claude.',
    `[mcp_servers.${CODEX_NAME}]`,
    `command = ${tomlString(node)}`,
    `args = [${[SERVER, '--caller', 'codex', '--max-wait', '840'].map(tomlString).join(', ')}]`,
    'startup_timeout_sec = 20',
    'tool_timeout_sec = 900',
    '# "approve": the calling agent decides when to delegate; Codex does not prompt for these tools.',
    'default_tools_approval_mode = "approve"',
    '',
  ].join('\n');
}

async function confirm(question) {
  if (YES) return true;
  if (DRY) return false;
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = (await rl.question(`${question} [y/N] `)).trim().toLowerCase();
  rl.close();
  return answer === 'y' || answer === 'yes';
}

async function install() {
  say('claude-codex-bridge installer\n');

  const node = process.execPath;
  const nodeMajor = Number(process.versions.node.split('.')[0]);
  if (nodeMajor < 18) { say(`Node ${process.versions.node} is too old; the bridge needs Node 18 or newer.`); process.exit(1); }
  const claude = findExecutable('claude');
  const codex = findExecutable('codex');
  const pathDirs = [path.dirname(node), claude && path.dirname(claude), codex && path.dirname(codex), ...(process.env.PATH || '').split(':'), '/usr/bin', '/bin', '/usr/sbin', '/sbin']
    .filter(Boolean);
  const childPath = [...new Set(pathDirs)].join(':');

  say('Found:');
  say(`  node   ${node} (v${process.versions.node})`);
  say(`  claude ${claude || 'NOT FOUND'}${claude ? `  (${version(claude, childPath) || 'version check failed'})` : ''}`);
  say(`  codex  ${codex || 'NOT FOUND'}${codex ? `  (${version(codex, childPath) || 'version check failed'})` : ''}`);
  if (!claude || !codex) {
    say('\nInstall the missing CLI first (and make sure it runs in this terminal), then run this again.');
    process.exit(1);
  }

  say('\nThis will:');
  say(`  1. write ${CONFIG}`);
  say(`  2. add "${DESKTOP_NAME}" to Claude Desktop: ${DESKTOP_CONFIG}`);
  say(`  3. add "${CODEX_NAME}" to Codex (CLI, IDE extension and ChatGPT desktop app share it): ${CODEX_CONFIG}`);
  say(`  4. install the Codex skill "work-with-claude" to ${SKILL_DEST_DIR}`);
  say('  Existing files are backed up first.');
  if (DRY) { say('\nDry run: nothing changed.'); say('\n--- Codex block ---\n' + codexBlock(node)); return; }
  if (!(await confirm('\nGo ahead?'))) { say('Nothing changed.'); return; }
  say('');

  // 1. bridge config (keep any edits the user made)
  let existing = {};
  try { existing = JSON.parse(fs.readFileSync(CONFIG, 'utf8')); } catch { /* new file */ }
  const cfg = {
    cancelOnStop: true, // stopping the calling agent stops the sub-agent
    useApiKeys: false, // sub-agents run on your subscriptions
    ...existing,
    claude: { model: null, effort: null, blockOutsideReads: true, ...(existing.claude || {}) },
    codex: { model: null, effort: null, bridgeServerName: CODEX_NAME, ...(existing.codex || {}) },
    claudePath: claude,
    codexPath: codex,
    childPath,
  };
  // Settings from earlier versions that no longer exist: limits, access levels and ceilings are gone.
  for (const k of ['access', 'allowedRoots', 'defaultAccess', 'maxAccess', 'limits', 'maxConcurrentJobs', 'jobTimeoutMinutes', 'maxResultChars']) delete cfg[k];
  delete cfg.claude.sandboxedCommands; delete cfg.claude.extraAllowedTools; delete cfg.codex.network;
  fs.writeFileSync(CONFIG, JSON.stringify(cfg, null, 2) + '\n');
  ok(`wrote ${path.basename(CONFIG)}`);

  // 2. Claude Desktop
  try {
    let desktop = {};
    if (fs.existsSync(DESKTOP_CONFIG)) {
      const raw = fs.readFileSync(DESKTOP_CONFIG, 'utf8');
      desktop = raw.trim() ? JSON.parse(raw) : {};
      const b = backup(DESKTOP_CONFIG);
      if (b) ok(`backed up Claude Desktop config -> ${path.basename(b)}`);
    } else {
      fs.mkdirSync(path.dirname(DESKTOP_CONFIG), { recursive: true });
    }
    desktop.mcpServers = desktop.mcpServers || {};
    desktop.mcpServers[DESKTOP_NAME] = { command: node, args: [SERVER, '--caller', 'claude', '--max-wait', '50'] };
    fs.writeFileSync(DESKTOP_CONFIG, JSON.stringify(desktop, null, 2) + '\n');
    ok(`added "${DESKTOP_NAME}" to Claude Desktop`);
  } catch (err) {
    warn(`could not update Claude Desktop config (${err.message}). Add this under "mcpServers" yourself:`);
    say(JSON.stringify({ [DESKTOP_NAME]: { command: node, args: [SERVER, '--caller', 'claude', '--max-wait', '50'] } }, null, 2));
  }

  // 3. Codex
  try {
    fs.mkdirSync(CODEX_HOME, { recursive: true });
    const before = fs.existsSync(CODEX_CONFIG) ? fs.readFileSync(CODEX_CONFIG, 'utf8') : '';
    const b = backup(CODEX_CONFIG);
    if (b) ok(`backed up Codex config -> ${path.basename(b)}`);
    let text = removeTomlServer(before, CODEX_NAME).replace(/\s*$/, '');
    text = (text ? text + '\n\n' : '') + codexBlock(node);
    fs.writeFileSync(CODEX_CONFIG, text);
    ok(`added "${CODEX_NAME}" to Codex`);
  } catch (err) {
    warn(`could not update Codex config (${err.message}). Add this to ${CODEX_CONFIG} yourself:`);
    say(codexBlock(node));
  }

  // 4. Codex skill (SKILL.md + agents/openai.yaml, which turns off implicit invocation)
  for (const dir of OLD_SKILL_DIRS) {
    try {
      if (fs.existsSync(dir) && fs.readdirSync(dir).every((f) => f === 'SKILL.md' || f === 'agents' || f.startsWith('SKILL.md.bak-'))) {
        fs.rmSync(dir, { recursive: true, force: true });
        ok(`removed the old Codex skill "${path.basename(dir)}" (renamed to "work-with-claude")`);
      }
    } catch { /* leave it */ }
  }
  try {
    for (const rel of ['SKILL.md', path.join('agents', 'openai.yaml')]) {
      const src = path.join(SKILL_SRC_DIR, rel);
      const dest = path.join(SKILL_DEST_DIR, rel);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      if (fs.existsSync(dest) && fs.readFileSync(dest, 'utf8') !== fs.readFileSync(src, 'utf8')) {
        const b = backup(dest);
        if (b) ok(`backed up existing ${rel} -> ${path.basename(b)}`);
      }
      fs.copyFileSync(src, dest);
    }
    ok('installed Codex skill "work-with-claude" (manual use only: type $work-with-claude)');
  } catch (err) {
    warn(`could not install the Codex skill (${err.message}).`);
  }

  say('\nSub-agents get the calling agent\'s permissions: Claude mirrors the calling Codex session; Codex uses its own settings (as in the Codex app).');
  say('\nNext:');
  say(`  1. Test both directions with the real CLIs:  node ${path.join(HERE, 'selftest.mjs')}`);
  say('  2. Quit Claude Desktop completely (Cmd+Q) and reopen it.');
  say('  3. Quit and reopen the Codex / ChatGPT desktop app (and any running `codex` CLI).');
  say('  4. Save the "work-with-codex" skill in Claude Desktop (Claude offers it in the chat).');
}

async function uninstall() {
  say('Removing claude-codex-bridge from Claude Desktop and Codex.\n');
  if (!(await confirm('Go ahead?'))) { say('Nothing changed.'); return; }
  if (fs.existsSync(DESKTOP_CONFIG)) {
    try {
      const desktop = JSON.parse(fs.readFileSync(DESKTOP_CONFIG, 'utf8'));
      if (desktop.mcpServers?.[DESKTOP_NAME]) {
        backup(DESKTOP_CONFIG);
        delete desktop.mcpServers[DESKTOP_NAME];
        fs.writeFileSync(DESKTOP_CONFIG, JSON.stringify(desktop, null, 2) + '\n');
        ok('removed from Claude Desktop');
      } else ok('not in Claude Desktop config');
    } catch (err) { warn(`Claude Desktop config: ${err.message}`); }
  }
  if (fs.existsSync(CODEX_CONFIG)) {
    const before = fs.readFileSync(CODEX_CONFIG, 'utf8');
    const after = removeTomlServer(before, CODEX_NAME);
    if (after !== before) { backup(CODEX_CONFIG); fs.writeFileSync(CODEX_CONFIG, after.replace(/\s*$/, '\n')); ok('removed from Codex'); } else ok('not in Codex config');
  }
  for (const dir of [SKILL_DEST_DIR, ...OLD_SKILL_DIRS]) {
    if (!fs.existsSync(dir)) continue;
    const ours = fs.readdirSync(dir).every((f) => f === 'SKILL.md' || f === 'agents' || f.startsWith('SKILL.md.bak-'));
    if (ours) { fs.rmSync(dir, { recursive: true, force: true }); ok(`removed Codex skill "${path.basename(dir)}"`); }
    else warn(`left ${dir} in place because it has other files in it`);
  }
  say('\nRestart both apps. In Claude Desktop, remove the "work-with-codex" skill under Customize > Skills if you saved it.');
}

(UNINSTALL ? uninstall() : install()).catch((err) => { say(`\nError: ${err.message || err}`); process.exit(1); });
