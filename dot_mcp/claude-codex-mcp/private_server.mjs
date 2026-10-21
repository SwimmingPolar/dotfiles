#!/usr/bin/env node
// claude-codex-bridge
// A small, dependency-free MCP (stdio) server that lets Claude and Codex delegate tasks to each
// other. The calling agent sends a Title and a Content; the sub-agent - the other agent's own
// headless engine (`claude -p` or `codex exec`) on its own sign-in - replies with an Answer.
// One exchange per call. A sub-agent never delegates further.
//
//   node server.mjs --caller codex    -> exposes ask_claude  (added to Codex)
//   node server.mjs --caller claude   -> exposes ask_codex   (added to Claude Desktop)
//   node server.mjs --try claude|codex --folder DIR --title "..." [--session ID] [--level read|auto|full] "content"
//   node server.mjs --sessions [--folder DIR]
//
// Nothing is written to the bridge's own folder while it runs (only `set_models` updates its
// config). Each task folder gets a .session/ folder - sessions.json, history.jsonl and one record
// per delegation in jobs/ - which is added to that folder's .gitignore. A small cross-app index of
// running jobs, stop markers and a diagnostic log live in ~/Library/Caches/claude-codex-bridge.
// Secrets are redacted everywhere.

import { spawn, execFile } from 'node:child_process';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const VERSION = '0.3.0';
const HERE = path.dirname(fileURLToPath(import.meta.url));
const CONFIG_PATH = process.env.CLAUDE_CODEX_BRIDGE_CONFIG || path.join(HERE, 'bridge.config.json');
// Runtime state shared by every bridge process (Claude Desktop's and Codex's), outside this folder.
const STATE_DIR = process.env.CLAUDE_CODEX_BRIDGE_STATE_DIR || process.env.CLAUDE_CODEX_BRIDGE_LOG_DIR
  || (process.platform === 'darwin'
    ? path.join(os.homedir(), 'Library', 'Caches', 'claude-codex-bridge')
    : path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'claude-codex-bridge'));
const LOG_DIR = STATE_DIR; // bridge.log (diagnostics) and cancel/ markers
const JOB_DIR = path.join(STATE_DIR, 'jobs'); // one small pointer per job: where its record is, and whether it runs
const PROJECTS_INDEX = path.join(STATE_DIR, 'projects.json');
const REG_DIR_NAME = '.session'; // per task folder
const DEPTH_VAR = 'CLAUDE_CODEX_BRIDGE_DEPTH';
const DEPTH = Number(process.env[DEPTH_VAR] || 0);

// ---------------------------------------------------------------- config ---

const DEFAULTS = {
  claudePath: 'claude',
  codexPath: 'codex',
  childPath: process.env.PATH || '/usr/bin:/bin:/usr/sbin:/sbin',
  cancelOnStop: true, // stopping the calling agent stops the sub-agent (unless the app only timed out)
  useApiKeys: false, // false = sub-agents always run on your subscriptions (API-key env vars are removed)
  claude: { model: null, effort: null, blockOutsideReads: true },
  codex: { model: null, effort: null, bridgeServerName: 'claude_bridge' },
};

function loadConfig() {
  let user = {};
  try { user = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')); } catch (err) {
    if (err.code !== 'ENOENT') logEvent('config_error', { error: String(err.message || err) });
  }
  return {
    ...DEFAULTS,
    ...user,
    claude: { ...DEFAULTS.claude, ...(user.claude || {}) },
    codex: { ...DEFAULTS.codex, ...(user.codex || {}) },
  };
}

// -------------------------------------------------------------- redaction ---
// Tracking files (job logs, history, registry) must never hold credentials.

const SECRET_PATTERNS = [
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, '[REDACTED PRIVATE KEY]'],
  [/\bsk-(?:ant-|proj-)?[A-Za-z0-9_-]{16,}\b/g, '[REDACTED KEY]'],
  [/\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b/g, '[REDACTED TOKEN]'],
  [/\bgithub_pat_[A-Za-z0-9_]{20,}\b/g, '[REDACTED TOKEN]'],
  [/\bglpat-[A-Za-z0-9_-]{16,}\b/g, '[REDACTED TOKEN]'],
  [/\bxox[abprs]-[A-Za-z0-9-]{10,}\b/g, '[REDACTED TOKEN]'],
  [/\bAKIA[0-9A-Z]{16}\b/g, '[REDACTED KEY]'],
  [/\bAIza[0-9A-Za-z_-]{30,}\b/g, '[REDACTED KEY]'],
  [/\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g, '[REDACTED JWT]'],
  [/\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{16,}/gi, '$1 [REDACTED]'],
  [/((?:api[_-]?key|secret|token|passw(?:or)?d|auth(?:orization)?|client[_-]?secret|access[_-]?key)["']?\s*[:=]\s*["']?)[^\s"',;]{8,}/gi, '$1[REDACTED]'],
  [/(\/\/[^/\s:@]+:)[^@\s/]{4,}@/g, '$1[REDACTED]@'],
];

function redact(value) {
  if (value === null || value === undefined) return value;
  if (typeof value === 'string') {
    let s = value;
    for (const [re, rep] of SECRET_PATTERNS) s = s.replace(re, rep);
    return s;
  }
  if (Array.isArray(value)) return value.map(redact);
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = redact(v);
    return out;
  }
  return value;
}

// --------------------------------------------------------------- logging ---

function ensureDir(dir) { try { fs.mkdirSync(dir, { recursive: true }); } catch { /* best effort */ } }

function writeJsonAtomic(file, data) {
  ensureDir(path.dirname(file));
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + '\n');
  fs.renameSync(tmp, file);
}

function logEvent(event, data = {}) {
  ensureDir(LOG_DIR);
  const line = JSON.stringify(redact({ time: new Date().toISOString(), pid: process.pid, event, ...data }));
  try { fs.appendFileSync(path.join(LOG_DIR, 'bridge.log'), line + '\n'); } catch { /* ignore */ }
}

// The full record (title, content, answer) is kept with the task, in <folder>/.session/jobs/.
// The pointer in the state dir lets check_job, cancel_job and --jobs find it from any app.
function saveJob(job) {
  const record = { ...job };
  delete record.proc;
  delete record.done;
  if (job.folder) {
    try { writeJsonAtomic(path.join(sessionDir(job.folder).dir, 'jobs', `${job.id}.json`), redact(record)); } catch { /* ignore */ }
  }
  const pointer = { id: job.id, agent: job.agent, folder: job.folder, records: job.folder ? sessionDir(job.folder).dir : null, session: job.session, title: job.title, status: job.status, pid: job.pid || null, startedAt: job.startedAt, endedAt: job.endedAt || null };
  try { writeJsonAtomic(path.join(JOB_DIR, `${job.id}.json`), redact(pointer)); } catch { /* ignore */ }
}

function loadJobFromDisk(id) {
  if (!/^[a-f0-9]{8}$/.test(id)) return null;
  let pointer;
  try { pointer = JSON.parse(fs.readFileSync(path.join(JOB_DIR, `${id}.json`), 'utf8')); } catch { return null; }
  try {
    const full = JSON.parse(fs.readFileSync(path.join(pointer.records || path.join(pointer.folder, REG_DIR_NAME), 'jobs', `${id}.json`), 'utf8'));
    return { ...full, pid: full.pid || pointer.pid };
  } catch { return pointer; } // the task folder moved or its .session/ was deleted
}

// ------------------------------------------------------------- registry ---
// <folder>/.session/sessions.json : the sessions started in this folder, by session id
// <folder>/.session/history.jsonl : one line per delegation
// <folder>/.session/jobs/<id>.json : each delegation's full record

// Records for a folder go in <folder>/.session. The bridge checks it can create and write that
// folder; when it can't (a read-only folder, or macOS privacy settings blocking the app), the
// records go to the state dir instead, and the result says where.
const sessionDirs = new Map(); // folder -> { dir, inFolder, reason }
function sessionDir(folder) {
  if (sessionDirs.has(folder)) return sessionDirs.get(folder);
  const own = path.join(folder, REG_DIR_NAME);
  let out;
  try {
    fs.mkdirSync(own, { recursive: true });
    fs.accessSync(own, fs.constants.W_OK);
    out = { dir: own, inFolder: true, reason: null };
  } catch (err) {
    const key = crypto.createHash('sha256').update(folder).digest('hex').slice(0, 16);
    const dir = path.join(STATE_DIR, 'folders', `${path.basename(folder) || 'root'}-${key}`, REG_DIR_NAME);
    try { fs.mkdirSync(dir, { recursive: true }); } catch { /* reported when used */ }
    out = { dir, inFolder: false, reason: `could not create ${own} (${err.code || err.message})` };
    try { fs.writeFileSync(path.join(path.dirname(dir), 'folder.txt'), folder + '\n'); } catch { /* ignore */ }
  }
  sessionDirs.set(folder, out);
  return out;
}

function regPaths(folder) {
  const dir = sessionDir(folder).dir;
  return { dir, sessions: path.join(dir, 'sessions.json'), history: path.join(dir, 'history.jsonl') };
}

function loadRegistry(folder) {
  const p = regPaths(folder);
  try {
    const reg = JSON.parse(fs.readFileSync(p.sessions, 'utf8'));
    if (reg && reg.version === 2 && reg.sessions && typeof reg.sessions === 'object') return reg;
  } catch { /* missing, damaged or an older format: start a new one */ }
  return { version: 2, folder, sessions: {} };
}

function saveRegistry(cfg, folder, reg) {
  const p = regPaths(folder);
  const fresh = !fs.existsSync(path.join(p.dir, 'README.md'));
  writeJsonAtomic(p.sessions, redact(reg));
  if (fresh) {
    try {
      fs.writeFileSync(path.join(p.dir, 'README.md'), '# .session (claude-codex-bridge)\n\nWritten by claude-codex-bridge for the delegations started in this folder. `sessions.json` lists the sessions (id, title, the agent\'s own session id), `history.jsonl` has one line per delegation, and `jobs/` has each delegation\'s full record. Secrets are redacted. Agents should not edit these files. The folder is listed in .gitignore; delete it whenever you like.\n');
    } catch { /* ignore */ }
  }
  if (sessionDir(folder).inFolder) gitIgnore(cfg, folder);
  try {
    let idx = {};
    try { idx = JSON.parse(fs.readFileSync(PROJECTS_INDEX, 'utf8')); } catch { /* new */ }
    idx[folder] = new Date().toISOString();
    writeJsonAtomic(PROJECTS_INDEX, idx);
  } catch { /* ignore */ }
}

function appendHistory(folder, entry) {
  const p = regPaths(folder);
  try { ensureDir(p.dir); fs.appendFileSync(p.history, JSON.stringify(redact(entry)) + '\n'); } catch { /* ignore */ }
}

// Keep .session/ out of git: add it to the task folder's .gitignore when the folder is in a repository.
const gitIgnored = new Set();
function gitIgnore(cfg, folder) {
  if (gitIgnored.has(folder)) return;
  gitIgnored.add(folder);
  execFile('git', ['-C', folder, 'rev-parse', '--is-inside-work-tree'], { timeout: 4000, env: { ...process.env, PATH: cfg.childPath } }, (err, stdout) => {
    if (err || !String(stdout).trim().startsWith('true')) return;
    const file = path.join(folder, '.gitignore');
    try {
      const cur = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
      const listed = cur.split('\n').some((l) => ['.session', '.session/', '/.session', '/.session/'].includes(l.trim()));
      if (!listed) fs.appendFileSync(file, `${cur && !cur.endsWith('\n') ? '\n' : ''}# claude-codex-bridge delegation records\n${REG_DIR_NAME}/\n`);
    } catch { /* ignore */ }
  });
}

function pidAlive(pid) {
  if (!pid || pid === process.pid) return false;
  try { process.kill(pid, 0); return true; } catch { return false; }
}

// --------------------------------------------------------------- helpers ---

class UserError extends Error {}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function tail(text, n = 4000) { return text && text.length > n ? text.slice(-n) : text || ''; }

function firstLine(text, n = 300) {
  const s = String(text || '').trim().replace(/\s+/g, ' ');
  return s.length > n ? s.slice(0, n - 3) + '...' : s;
}

// If the bridge itself was started from inside a Claude Code session (for example `codex` run in a
// Claude Code terminal), these would make the delegated run reuse that session's identity.
const PARENT_SESSION_VARS = ['CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_REMOTE_SESSION_ID', 'CLAUDE_CODE_CHILD_SESSION',
  'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_PID'];

function childEnv(cfg, agent) {
  const env = { ...process.env, PATH: cfg.childPath, [DEPTH_VAR]: String(DEPTH + 1) };
  for (const k of PARENT_SESSION_VARS) delete env[k];
  if (!cfg.useApiKeys) {
    if (agent === 'claude') { delete env.ANTHROPIC_API_KEY; delete env.ANTHROPIC_AUTH_TOKEN; }
    else { delete env.CODEX_API_KEY; delete env.OPENAI_API_KEY; }
  }
  return env;
}

function runGit(cfg, folder, args, timeout = 8000) {
  return new Promise((resolve) => {
    execFile('git', ['-C', folder, ...args], { timeout, maxBuffer: 8 * 1024 * 1024, env: { ...process.env, PATH: cfg.childPath } },
      (err, stdout, stderr) => resolve({ ok: !err, stdout: stdout || '', stderr: stderr || '' }));
  });
}

async function gitStatus(cfg, folder) {
  const inside = await runGit(cfg, folder, ['rev-parse', '--is-inside-work-tree'], 4000);
  if (!inside.ok || !inside.stdout.trim().startsWith('true')) return null;
  const st = await runGit(cfg, folder, ['status', '--short']);
  return st.ok ? (st.stdout.trim() || '(no changes)') : null;
}

async function recentFiles(folder, sinceMs, limit = 50) {
  const skip = new Set(['.git', 'node_modules', '.venv', 'venv', '__pycache__', 'dist', 'build', '.next', 'target', REG_DIR_NAME]);
  const out = [];
  async function walk(dir, depth) {
    if (out.length >= limit || depth > 6) return;
    let entries;
    try { entries = await fsp.readdir(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (out.length >= limit) return;
      if (skip.has(e.name)) continue;
      const full = path.join(dir, e.name);
      if (e.isDirectory()) await walk(full, depth + 1);
      else if (e.isFile()) {
        try { if ((await fsp.stat(full)).mtimeMs >= sinceMs) out.push(path.relative(folder, full)); } catch { /* ignore */ }
      }
    }
  }
  await walk(folder, 0);
  return out;
}

// ----------------------------------------------------------------- folder ---
// A sub-agent works where the calling agent works. The folder comes from the calling Codex
// session (its working folder), or the calling app's MCP roots; a `folder` argument may point
// anywhere inside that. When the calling app shares no folder, the calling agent must name one.

async function realDir(p) {
  let real;
  try { real = await fsp.realpath(p); } catch { return null; }
  try { if (!(await fsp.stat(real)).isDirectory()) return null; } catch { return null; }
  return real;
}

const isInside = (child, parent) => child === parent || child.startsWith(parent.endsWith(path.sep) ? parent : parent + path.sep);

function expandHome(p) {
  const t = String(p).trim();
  return t === '~' || t.startsWith('~/') ? path.join(os.homedir(), t.slice(1)) : t;
}

// A chat "has no folder" when its app gives none, or gives one that isn't a folder the user chose:
// the root, the whole home folder, or an app's own internal folder (Codex runs ChatGPT-project
// chats in ~/.codex/.chatgpt-projects/...). Then the sub-agent works in the system temp folder.
async function appInternalDirs() {
  const home = os.homedir();
  const dirs = [path.join(home, '.codex'), path.join(home, 'Library', 'Application Support', 'Claude'), path.join(home, '.claude')];
  if (process.env.CODEX_HOME) dirs.push(process.env.CODEX_HOME);
  return (await Promise.all(dirs.map(async (d) => (await realDir(d)) || d)));
}

async function notAChosenFolder(dir) {
  const home = (await realDir(os.homedir())) || os.homedir();
  if (dir === path.parse(dir).root || dir === home) return true;
  return (await appInternalDirs()).some((d) => isInside(dir, d));
}

async function tmpFolder() {
  const tmp = (await realDir('/tmp')) || (await realDir(os.tmpdir()));
  if (!tmp) throw new UserError('This chat has no folder and the system temp folder is not available. Pass `folder`.');
  return tmp;
}

async function resolveWorkFolder(args, sandbox, clientRoots) {
  let roots = [];
  let source = null;
  let ignored = null; // a folder the app gave that isn't one the user chose
  if (sandbox?.cwd) {
    const r = await realDir(sandbox.cwd);
    if (r && (await notAChosenFolder(r))) ignored = r;
    else if (r) { roots = [r]; source = 'this Codex session'; }
  }
  if (!roots.length && clientRoots?.length) {
    for (const c of clientRoots) {
      const r = await realDir(c);
      if (!r) continue;
      if (await notAChosenFolder(r)) ignored = ignored || r;
      else roots.push(r);
    }
    if (roots.length) source = 'the calling app';
  }
  const want = args.folder ? expandHome(args.folder) : null;
  if (want && !path.isAbsolute(want)) throw new UserError(`\`folder\` must be an absolute path (got "${args.folder}").`);
  if (!roots.length) {
    if (!want) {
      const tmp = await tmpFolder();
      return { folder: tmp, roots: [tmp], source: ignored ? `the system temp folder, because this chat has no folder of its own (the app gave ${ignored})` : 'the system temp folder, because no folder was set for this chat' };
    }
    const real = await realDir(want);
    if (!real) throw new UserError(`Folder not found: ${want}`);
    return { folder: real, roots: [real], source: 'the calling agent' };
  }
  if (!want) return { folder: roots[0], roots, source };
  const real = await realDir(want);
  if (!real) throw new UserError(`Folder not found: ${want}`);
  if (!roots.some((r) => isInside(real, r))) {
    throw new UserError(`"${real}" is outside the calling agent's working folder (${roots.join(', ')}, from ${source}). A sub-agent can only work where the calling agent can.`);
  }
  return { folder: real, roots, source };
}

// ------------------------------------------------------------ permissions ---
// The sub-agent gets the calling agent's permissions. Codex shares its session's permission
// profile with every tool call, and a Claude sub-agent mirrors it. Claude Desktop shares none,
// so a Codex sub-agent runs with Codex's own settings (~/.codex/config.toml, which the Codex app
// uses too); a Claude sub-agent without a Codex profile likewise uses Claude's own settings.
// Neither sub-agent ever asks the user: `codex exec` never asks for approval, and `claude -p`
// refuses anything that would need a prompt.

function callerPermission(agent, sandbox) {
  if (sandbox && sandbox.level) {
    return { level: sandbox.level, network: sandbox.network !== false, source: `this Codex session (${sandbox.mode || sandbox.level})` };
  }
  return agent === 'claude'
    ? { level: null, network: true, source: 'Claude\'s own settings (~/.claude/settings.json)' }
    : { level: null, network: true, source: 'Codex\'s own settings (~/.codex/config.toml, as in the Codex app)' };
}

function permsText(agent, perm) {
  const web = perm.network ? '' : ' You have no web access.';
  if (perm.level === 'read') return `Read-only: you can read and search files, but not edit files or run commands.${web}`;
  if (perm.level === 'auto') return `You can read and edit files in the working folder and run commands; risky actions are checked automatically and may be refused.${web}`;
  if (perm.level === 'full') return 'Full access, with no permission checks.';
  return agent === 'claude' ? 'Those in your own Claude Code settings.' : 'The sandbox and permissions in your own Codex settings.';
}

// ------------------------------------------------------------- sandbox ---
// Codex shares the calling session's sandbox in tool-call _meta. Current Codex sends
// { permissionProfile, sandboxCwd, ... }; older builds sent { sandboxPolicy, ... }. Both are read.
function profileLevel(prof) {
  if (!prof) return { level: null, network: null };
  if (typeof prof === 'string') {
    const m = prof.toLowerCase();
    if (/danger|full-access|disabled|unrestricted/.test(m)) return { level: 'full', network: true };
    if (/read-?only/.test(m)) return { level: 'read', network: null };
    if (/workspace|write/.test(m)) return { level: 'auto', network: null };
    return { level: null, network: null };
  }
  if (typeof prof !== 'object') return { level: null, network: null };
  const netOf = (n) => (n === undefined || n === null ? null
    : typeof n === 'string' ? /^enabled$/i.test(n)
      : typeof n === 'boolean' ? n
        : typeof n === 'object' && 'enabled' in n ? Boolean(n.enabled) : null);
  const type = String(prof.type || '').toLowerCase();
  if (type === 'disabled') return { level: 'full', network: true };
  const network = netOf(prof.network);
  const fsys = prof.file_system ?? prof.fileSystem;
  if (type === 'external') return { level: 'auto', network };
  if (fsys && typeof fsys === 'object') {
    if (String(fsys.type || '').toLowerCase() === 'unrestricted') return { level: 'full', network: network ?? true };
    const entries = Array.isArray(fsys.entries) ? fsys.entries : [];
    const kindOf = (e) => String(e?.path?.value?.kind ?? e?.path?.value ?? '').toLowerCase();
    const writes = entries.filter((e) => String(e?.access || '').toLowerCase() === 'write');
    if (writes.some((e) => kindOf(e) === 'root')) return { level: 'full', network: network ?? true };
    if (writes.length) return { level: 'auto', network };
    if (entries.length) return { level: 'read', network };
  }
  return { level: null, network };
}

function parseSandboxMeta(meta) {
  if (!meta || typeof meta !== 'object') return null;
  const raw = meta['codex/sandbox-state'] ?? meta['codex/sandbox-state-meta'] ?? meta.sandbox_state ?? meta.sandboxState;
  if (!raw || typeof raw !== 'object') return null;
  const prof = raw.permissionProfile ?? raw.permission_profile ?? null;
  const pol = raw.sandboxPolicy ?? raw.sandbox_policy ?? null;
  let level = null; let network = null; let mode = null;
  if (prof) {
    ({ level, network } = profileLevel(prof));
    mode = typeof prof === 'string' ? prof : `profile:${prof.type || '?'}${prof.file_system?.type ? `/${prof.file_system.type}` : ''}`;
  }
  if (!level) {
    const modeRaw = typeof pol === 'string' ? pol : (pol && (pol.type ?? pol.mode)) ?? raw.sandbox_mode ?? raw.sandboxMode ?? '';
    const m = String(modeRaw).toLowerCase().replace(/_/g, '-');
    if (m) {
      mode = mode || m;
      if (/danger|full-access|fullaccess|unrestricted|disabled/.test(m)) level = 'full';
      else if (/read-?only/.test(m)) level = 'read';
      else if (/workspace|write/.test(m)) level = 'auto';
    }
    if (network === null) {
      const net = (pol && typeof pol === 'object' ? (pol.network_access ?? pol.networkAccess) : undefined)
        ?? raw.network_policy?.network_access ?? raw.networkPolicy?.networkAccess ?? raw.network_access ?? raw.networkAccess;
      if (typeof net === 'boolean') network = net;
      else if (typeof net === 'string') network = !/restricted|disabled|off|false|none/i.test(net);
      else if (net && typeof net === 'object' && 'enabled' in net) network = Boolean(net.enabled);
    }
  }
  if (level === 'full') network = true;
  let cwd = raw.sandboxCwd ?? raw.sandbox_cwd ?? raw.cwd ?? (pol && typeof pol === 'object' ? (pol.cwd ?? null) : null);
  if (cwd && typeof cwd === 'object') cwd = cwd.uri ?? cwd.path ?? null;
  if (typeof cwd === 'string' && cwd.startsWith('file://')) { try { cwd = fileURLToPath(cwd); } catch { cwd = null; } }
  if (typeof cwd !== 'string' || !cwd) cwd = null;
  return { level, network, mode: mode || null, approval: raw.approval_policy ?? raw.approvalPolicy ?? null, cwd };
}

// ------------------------------------------------------------ processes ---

const running = new Map(); // job_id -> job (in this server process)
const SELF = fileURLToPath(import.meta.url);
const ENOENT_MARK = '__CLAUDE_CODEX_BRIDGE_ENOENT__';

// Every delegated agent runs under a small watchdog (this file in --watchdog mode). It leads its
// own process group, so stopping the group stops the agent and anything it started, and it stops
// the agent within a couple of seconds if the bridge itself dies, even from a force quit.
function runProcess({ cmd, args, cwd, env, stdin, timeoutMs, onSpawn }) {
  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';
    let timedOut = false;
    const cap = 32 * 1024 * 1024;
    let child;
    try {
      child = spawn(process.execPath, [SELF, '--watchdog', String(process.pid), '--', cmd, ...args], { cwd, env, stdio: ['pipe', 'pipe', 'pipe'], detached: true });
    } catch (err) {
      resolve({ code: null, signal: null, stdout, stderr, error: err, timedOut });
      return;
    }
    onSpawn?.(child);
    const timer = timeoutMs > 0 ? setTimeout(() => { timedOut = true; killTree(child); }, timeoutMs) : null;
    const done = (r) => { if (timer) clearTimeout(timer); resolve(r); };
    child.stdout.on('data', (d) => { if (stdout.length < cap) stdout += d; });
    child.stderr.on('data', (d) => { if (stderr.length < cap) stderr += d; });
    child.on('error', (err) => done({ code: null, signal: null, stdout, stderr, error: err, timedOut }));
    child.on('close', (code, signal) => {
      if (code === 127 && stderr.includes(ENOENT_MARK)) {
        const err = new Error(`${cmd} not found`);
        err.code = 'ENOENT';
        return done({ code, signal, stdout, stderr: stderr.replace(ENOENT_MARK, ''), error: err, timedOut });
      }
      done({ code, signal, stdout, stderr, timedOut });
    });
    child.stdin.on('error', () => { /* child may exit before reading stdin */ });
    child.stdin.end(stdin ?? '');
  });
}

function killPid(pid) {
  if (!pid) return;
  try { process.kill(-pid, 'SIGTERM'); } catch { try { process.kill(pid, 'SIGTERM'); } catch { /* gone */ } }
  setTimeout(() => { try { process.kill(-pid, 'SIGKILL'); } catch { /* already gone */ } }, 3000).unref();
}

function killTree(child) {
  if (!child || child.exitCode !== null) return;
  killPid(child.pid);
}

function watchdogMode(rest) {
  const parentPid = Number(rest[0]);
  const sep = rest.indexOf('--');
  const cmd = rest[sep + 1];
  const cmdArgs = rest.slice(sep + 2);
  const child = spawn(cmd, cmdArgs, { stdio: 'inherit' });
  let stopping = false;
  const stop = () => {
    if (stopping) return;
    stopping = true;
    try { child.kill('SIGTERM'); } catch { /* gone */ }
    setTimeout(() => { try { process.kill(-process.pid, 'SIGKILL'); } catch { try { child.kill('SIGKILL'); } catch { /* gone */ } } }, 3000).unref();
  };
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
  process.on('SIGHUP', stop);
  const watch = setInterval(() => { try { process.kill(parentPid, 0); } catch { stop(); } }, 2000);
  child.on('error', (err) => {
    clearInterval(watch);
    process.stderr.write(err.code === 'ENOENT' ? ENOENT_MARK : String(err.message || err));
    process.exit(127);
  });
  child.on('exit', (code, signal) => { clearInterval(watch); process.exit(code ?? (signal ? 143 : 0)); });
}

const cancelMarker = (id) => path.join(LOG_DIR, 'cancel', id);

const MISSING_SESSION = /no conversation found|session not found|could not find (?:session|thread|conversation)|no rollout|no such (?:session|thread)|unknown (?:session|thread)|failed to (?:find|load) (?:session|thread|rollout)/i;

// --------------------------------------------------------------- protocol ---
// Calling agent -> sub-agent: Title + Content.   Sub-agent -> calling agent: Answer.
// If the Content is not enough, the Answer starts with "More context needed:" and lists what is
// missing; the calling agent then appends context to the same session, or starts a new one.

const MORE_CONTEXT = 'More context needed:';

function subAgentRules({ agent, caller, folder, perm }) {
  const callerName = caller === 'codex' ? 'Codex' : caller === 'claude' ? 'Claude' : 'Another AI agent';
  return [
    `You are a sub-agent. ${callerName}, the calling agent, works with the user and has delegated one task to you through claude-codex-bridge. It sent you a Title and a Content.`,
    'The Title is a one-line summary of the task. The Content is everything you are given: you cannot see the user or the calling agent\'s conversation, and nobody can answer you while you work.',
    `Do the task the Content describes, and nothing else. Work in ${folder}; do not read, list, search or change anything outside it.`,
    `Your permissions: ${permsText(agent, perm)} Nothing can be approved for you during this run. If an action is refused, carry on without it and say so in your Answer.`,
    'Do not hand any part of the task to another agent.',
    `Leave the ${REG_DIR_NAME}/ folder alone: the bridge keeps its records there.`,
    'Your final message is your Answer. Start it with "Answer:" and give the result: what you did or found, the files you created or changed, the checks you ran and their results, and any assumption you made.',
    `If the Content is not enough to do the task without guessing at something that matters, do not guess. Make no change that depends on the missing information, and make your final message "Answer: ${MORE_CONTEXT}" followed by a numbered list of exactly what you need and why.`,
  ].join('\n');
}

function taskPrompt(title, content, appended) {
  return appended
    ? `Title: ${title}\n\nContent (more context from the calling agent, for the task you asked about):\n${content}`
    : `Title: ${title}\n\nContent:\n${content}`;
}

function parseAnswer(text) {
  const t = String(text || '').trim().replace(/^\*{0,2}\s*answer\s*:\s*\*{0,2}\s*/i, '');
  return { answer: t, moreContext: /^\*{0,2}\s*more context needed\s*:/i.test(t) };
}

function tryParseJson(s) {
  if (typeof s !== 'string') return null;
  try { return JSON.parse(s.trim()); } catch { return null; }
}

// ------------------------------------------------------------- the agents ---

async function runClaude(cfg, job, resumeId) {
  const { folder, title, content, appended } = job.input;
  const perm = job.perm;
  const args = ['-p', '--output-format', 'json'];
  if (cfg.claude.blockOutsideReads !== false) args.push('--settings', JSON.stringify({ permissions: { blockReadsOutsideWorkingDirectories: true } }));
  const disallowed = [];
  if (perm.level === 'read') {
    args.push('--permission-mode', 'dontAsk', '--allowedTools', 'Read', 'Glob', 'Grep', 'TodoWrite', ...(perm.network ? ['WebSearch', 'WebFetch'] : []));
    disallowed.push('Edit', 'Write', 'NotebookEdit', 'Bash');
  } else if (perm.level === 'auto') {
    args.push('--permission-mode', 'auto');
  } else if (perm.level === 'full') {
    args.push('--permission-mode', 'bypassPermissions');
  } // no level: Claude's own settings decide
  if (perm.level && !perm.network) disallowed.push('WebSearch', 'WebFetch');
  if (disallowed.length) args.push('--disallowedTools', ...new Set(disallowed));
  if (cfg.claude.model) args.push('--model', String(cfg.claude.model));
  if (cfg.claude.effort) args.push('--effort', String(cfg.claude.effort));
  if (resumeId) args.push('--resume', resumeId);
  args.push('--append-system-prompt', subAgentRules({ agent: 'claude', caller: job.caller, folder, perm }));
  job.command = [cfg.claudePath, ...args.map((a) => (a.length > 100 ? a.slice(0, 97) + '...' : a))];

  const res = await runProcess({
    cmd: cfg.claudePath, args, cwd: folder, env: childEnv(cfg, 'claude'), stdin: taskPrompt(title, content, appended),
    timeoutMs: 0, onSpawn: (p) => { job.proc = p; job.pid = p.pid; saveJob(job); },
  });
  if (res.error) {
    throw new Error(res.error.code === 'ENOENT'
      ? `Claude Code was not found at "${cfg.claudePath}". Re-run install.mjs, or set claudePath in ${CONFIG_PATH}.`
      : `Could not start Claude Code: ${res.error.message}`);
  }
  let parsed = tryParseJson(res.stdout);
  if (!parsed || parsed.type !== 'result') {
    for (const l of res.stdout.trim().split('\n').reverse()) {
      const o = tryParseJson(l);
      if (o && o.type === 'result') { parsed = o; break; }
    }
  }
  const text = typeof parsed?.result === 'string' ? parsed.result : res.stdout.trim();
  const failed = !parsed || Boolean(parsed.is_error) || (res.code !== 0 && !text);
  const denials = (Array.isArray(parsed?.permission_denials) ? parsed.permission_denials : []).map((d) => {
    const input = d?.tool_input || {};
    const what = input.command || input.file_path || input.url || input.query || input.path || '';
    return firstLine(`${d?.tool_name || 'tool'}${what ? `: ${what}` : ''}`, 160);
  });
  return {
    sessionId: parsed?.session_id || resumeId || null,
    text: text || tail(res.stderr) || `Claude Code exited with code ${res.code}.`,
    denials,
    processFailed: failed,
    missingSession: Boolean(resumeId) && failed && MISSING_SESSION.test(`${res.stdout}\n${res.stderr}`),
    detail: { exitCode: res.code, signal: res.signal, numTurns: parsed?.num_turns, durationMs: parsed?.duration_ms, subtype: parsed?.subtype },
    stderr: tail(res.stderr),
  };
}

// Only disable the bridge inside a Codex sub-agent if the user's Codex config defines it;
// overriding a server that doesn't exist makes Codex reject its config.
function codexHasBridge(cfg) {
  const name = cfg.codex.bridgeServerName;
  if (!name) return false;
  const home = cfg.codex.home || process.env.CODEX_HOME || path.join(os.homedir(), '.codex');
  try {
    const text = fs.readFileSync(path.join(home, 'config.toml'), 'utf8');
    const esc = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return new RegExp(`^\\s*\\[\\s*mcp_servers\\s*\\.\\s*"?${esc}"?\\s*\\]`, 'm').test(text);
  } catch { return false; }
}

async function runCodex(cfg, job, resumeId) {
  const { folder, title, content, appended } = job.input;
  const lastFile = path.join(os.tmpdir(), `claude-codex-bridge-${job.id}-${Date.now()}.txt`);
  // No sandbox or approval flags: Codex's own settings decide, as in the Codex app.
  const shared = ['--json', '--skip-git-repo-check', '-o', lastFile];
  if (codexHasBridge(cfg)) shared.push('-c', `mcp_servers.${cfg.codex.bridgeServerName}.enabled=false`);
  if (cfg.codex.model) shared.push('-m', String(cfg.codex.model));
  if (cfg.codex.effort) shared.push('-c', `model_reasoning_effort="${cfg.codex.effort}"`);
  const args = resumeId ? ['exec', 'resume', ...shared, resumeId, '-'] : ['exec', ...shared, '-C', folder, '-'];
  const prompt = `${subAgentRules({ agent: 'codex', caller: job.caller, folder, perm: job.perm })}\n\n${taskPrompt(title, content, appended)}`;
  job.command = [cfg.codexPath, ...args];

  const res = await runProcess({
    cmd: cfg.codexPath, args, cwd: folder, env: childEnv(cfg, 'codex'), stdin: prompt,
    timeoutMs: 0, onSpawn: (p) => { job.proc = p; job.pid = p.pid; saveJob(job); },
  });
  if (res.error) {
    throw new Error(res.error.code === 'ENOENT'
      ? `Codex was not found at "${cfg.codexPath}". Re-run install.mjs, or set codexPath in ${CONFIG_PATH}.`
      : `Could not start Codex: ${res.error.message}`);
  }
  let threadId = null;
  const errors = [];
  let usage = null;
  for (const line of res.stdout.split('\n')) {
    const t = line.trim();
    if (!t.startsWith('{')) continue;
    let ev;
    try { ev = JSON.parse(t); } catch { continue; }
    if (ev.type === 'thread.started' && ev.thread_id) threadId = ev.thread_id;
    else if (ev.type === 'turn.completed' && ev.usage) usage = ev.usage;
    else if (ev.type === 'turn.failed') errors.push(ev.error?.message || JSON.stringify(ev.error || ev));
    else if (ev.type === 'error') errors.push(ev.message || JSON.stringify(ev));
  }
  if (!threadId) { const m = /"thread_id"\s*:\s*"([^"]+)"/.exec(res.stdout); if (m) threadId = m[1]; }
  let text = '';
  try { text = (await fsp.readFile(lastFile, 'utf8')).trim(); } catch { /* no final message */ }
  fsp.unlink(lastFile).catch(() => {});
  const failed = !text;
  if (!text) text = errors.join('\n') || tail(res.stderr) || `Codex exited with code ${res.code}.`;
  return {
    sessionId: threadId || resumeId || null,
    text,
    denials: [],
    processFailed: failed,
    missingSession: Boolean(resumeId) && failed && MISSING_SESSION.test(`${res.stdout}\n${res.stderr}\n${errors.join('\n')}`),
    detail: { exitCode: res.code, signal: res.signal, usage, errors: errors.length ? errors : undefined },
    stderr: tail(res.stderr),
  };
}

// ------------------------------------------------------------------ jobs ---

const SESSION_ID = /^(claude|codex)-[a-f0-9]{8}$/;
const AGENT_NAME = { claude: 'Claude', codex: 'Codex' };

async function startJob(cfg, { agent, caller, args, perm, where }) {
  if (DEPTH >= 1) throw new UserError('This agent is itself a sub-agent started by claude-codex-bridge, so it cannot delegate further. Do the task yourself and put the result in your Answer.');
  const title = String(args.title ?? '').trim().replace(/\s+/g, ' ');
  const content = typeof args.content === 'string' ? args.content.trim() : '';
  if (!title) throw new UserError('`title` is required: one line that summarizes the task.');
  if (!content) throw new UserError('`content` is required: everything the sub-agent needs to do the task.');
  const Name = AGENT_NAME[agent];
  const folder = where.folder;
  const reg = loadRegistry(folder);
  let sid = args.session ? String(args.session).trim() : '';
  let entry;
  let resumeId = null;
  if (sid) {
    if (!SESSION_ID.test(sid)) throw new UserError(`\`session\` must be a session from an earlier result, like "${agent}-1a2b3c4d" (got "${sid}").`);
    entry = reg.sessions[sid];
    if (!entry) throw new UserError(`There is no session ${sid} in ${folder}. Pass the same folder as the earlier delegation, or start a new session (leave out session) with the full task and the added context. list_sessions shows the sessions in a folder.`);
    if (entry.agent !== agent) throw new UserError(`Session ${sid} belongs to ${AGENT_NAME[entry.agent]}, not ${Name}.`);
    if (entry.running) {
      const own = running.get(entry.running.job);
      if ((own && own.status === 'running') || pidAlive(entry.running.pid)) {
        throw new UserError(`Session ${sid} is still working on job ${entry.running.job}. Get its Answer with check_job before adding more context.`);
      }
      entry.running = null; // stale: the process that ran it is gone
    }
    if (!entry.agentSessionId) throw new UserError(`Session ${sid} has no saved ${Name} conversation (its first run did not finish), so there is nothing to append to. Start a new session with the full task and the added context.`);
    resumeId = entry.agentSessionId;
  } else {
    sid = `${agent}-${crypto.randomBytes(4).toString('hex')}`;
    entry = { agent, title, agentSessionId: null, createdAt: new Date().toISOString(), lastUsedAt: null, running: null, jobs: [] };
  }

  const now = Date.now();
  const job = {
    id: crypto.randomBytes(4).toString('hex'),
    agent,
    caller,
    status: 'running',
    startedAt: new Date(now).toISOString(),
    endedAt: null,
    session: sid,
    title,
    folder,
    folderSource: where.source,
    perm,
    agentSessionId: resumeId,
    input: { folder, title, content, appended: Boolean(resumeId) },
    answer: null,
    moreContext: false,
    error: null,
    denials: [],
  };

  entry.running = { job: job.id, pid: process.pid, since: job.startedAt };
  entry.lastTitle = title;
  reg.sessions[sid] = entry;
  saveRegistry(cfg, folder, reg);
  running.set(job.id, job);
  saveJob(job);
  logEvent('job_started', { job: job.id, agent, caller, folder, session: sid, appended: Boolean(resumeId), perm });

  job.done = (async () => {
    try {
      const run = agent === 'claude' ? runClaude : runCodex;
      const r = await run(cfg, job, resumeId);
      if (job.status !== 'cancelled' && fs.existsSync(cancelMarker(job.id))) markCancelled(job, 'Stopped from the terminal (--cancel).');
      if (r.sessionId) job.agentSessionId = r.sessionId;
      job.denials = r.denials || [];
      job.detail = r.detail;
      job.stderr = r.stderr;
      if (job.status === 'cancelled') return;
      if (r.missingSession) {
        job.status = 'failed';
        job.error = `${Name} no longer has the conversation for session ${sid}, so the context could not be appended. Start a new session (leave out session) with the full task and the added context.`;
      } else if (r.processFailed) {
        job.status = 'failed';
        job.error = firstLine(r.text, 2000) || `${Name} did not finish.`;
      } else {
        const a = parseAnswer(r.text);
        job.status = 'done';
        job.answer = a.answer;
        job.moreContext = a.moreContext;
      }
    } catch (err) {
      if (job.status !== 'cancelled') { job.status = 'failed'; job.error = String(err.message || err); }
    } finally {
      try { fs.rmSync(cancelMarker(job.id), { force: true }); } catch { /* ignore */ }
      job.endedAt = new Date().toISOString();
      job.durationSec = Math.round((Date.now() - now) / 1000);
      delete job.proc;
      try {
        const reg2 = loadRegistry(folder);
        const e2 = reg2.sessions[sid] || entry;
        if (job.agentSessionId) e2.agentSessionId = job.agentSessionId;
        e2.lastUsedAt = job.endedAt;
        e2.running = null;
        e2.jobs = [...(e2.jobs || []), job.id].slice(-50);
        reg2.sessions[sid] = e2;
        saveRegistry(cfg, folder, reg2);
      } catch (err) { logEvent('registry_error', { error: String(err.message || err) }); }
      const result = job.status === 'done' ? (job.moreContext ? 'more context' : 'answer') : job.status === 'failed' ? 'error' : job.status;
      appendHistory(folder, {
        time: job.endedAt, job: job.id, agent, caller, session: sid, agentSessionId: job.agentSessionId, title,
        appended: Boolean(resumeId), result, durationSec: job.durationSec, permissions: perm.source,
        answer: firstLine(job.answer || job.error || ''),
      });
      saveJob(job);
      logEvent('job_finished', { job: job.id, agent, status: job.status, result, durationSec: job.durationSec, session: sid, agentSessionId: job.agentSessionId });
    }
  })();
  return job;
}

async function waitForJob(job, seconds, progress) {
  if (job.status !== 'running' || !job.done) return;
  const deadline = Date.now() + seconds * 1000;
  let tick = 0;
  while (job.status === 'running' && Date.now() < deadline) {
    await Promise.race([job.done, sleep(Math.min(10000, deadline - Date.now()))]);
    if (job.status === 'running') progress?.(++tick, `${AGENT_NAME[job.agent]} is still working (job ${job.id})`);
  }
}

// The result the calling agent reads: Title, then the Answer (or why there is none).
function describeJob(job) {
  const Name = AGENT_NAME[job.agent];
  const lines = [`Title: ${job.title}`];
  if (job.status === 'running') {
    const secs = Math.round((Date.now() - Date.parse(job.startedAt)) / 1000);
    lines.push(`${Name} is still working (job ${job.id}, ${secs}s so far). Call check_job with job_id "${job.id}" to get the Answer.`);
  } else if (job.status === 'cancelled') {
    lines.push(`Cancelled: ${job.error || 'stopped.'} Files ${Name} already changed stay changed.`);
  } else if (job.status === 'failed') {
    lines.push(`Error: ${job.error || `${Name} did not finish.`}`);
  } else {
    lines.push('Answer:', job.answer || '(empty)');
  }
  const rd = job.folder ? sessionDir(job.folder) : null;
  lines.push('', `session: ${job.session}`, `folder: ${job.folder}`, `permissions: ${job.perm?.source || 'unknown'}`);
  if (job.folderSource && /temp folder/.test(job.folderSource)) lines.push(`note: working in ${job.folderSource}`);
  if (rd) lines.push(`records: ${rd.dir}${rd.inFolder ? '' : ` (${rd.reason})`}`);
  if (job.denials?.length) lines.push(`refused by permissions: ${job.denials.join('; ')}`);
  return lines.join('\n');
}

// --------------------------------------------------------------- sessions ---

function describeSessions(folder) {
  const reg = loadRegistry(folder);
  const ids = Object.keys(reg.sessions).sort((a, b) => ((reg.sessions[a].lastUsedAt || reg.sessions[a].createdAt) < (reg.sessions[b].lastUsedAt || reg.sessions[b].createdAt) ? 1 : -1));
  if (!ids.length) return `folder: ${folder}\nNo delegations in this folder yet.`;
  const lines = [`folder: ${folder}`, `registry: ${regPaths(folder).sessions}`, '', 'sessions (most recent first):'];
  for (const id of ids) {
    const e = reg.sessions[id];
    lines.push(`  ${id}  "${e.lastTitle || e.title}"  last used ${e.lastUsedAt || 'never'}${e.running ? `  RUNNING job ${e.running.job}` : ''}`);
    if (e.agentSessionId) lines.push(`    ${AGENT_NAME[e.agent]}'s own session: ${e.agentSessionId} (open it yourself: ${e.agent === 'claude' ? `cd "${folder}" && claude --resume ${e.agentSessionId}` : `codex resume ${e.agentSessionId}`})`);
  }
  try {
    const hist = fs.readFileSync(regPaths(folder).history, 'utf8').trim().split('\n').slice(-10).map((l) => JSON.parse(l));
    lines.push('', 'recent delegations:');
    for (const h of hist) lines.push(`  ${h.time}  ${h.session}${h.appended ? ' (+context)' : ''}  ${h.result}  "${firstLine(h.title, 80)}"`);
  } catch { /* no history */ }
  return lines.join('\n');
}

function describeProjects() {
  let idx = {};
  try { idx = JSON.parse(fs.readFileSync(PROJECTS_INDEX, 'utf8')); } catch { /* none */ }
  const folders = Object.entries(idx).sort((a, b) => (a[1] < b[1] ? 1 : -1));
  if (!folders.length) return 'No delegations yet.';
  return ['Folders with delegations (most recent first):', ...folders.map(([f, t]) => `  ${t}  ${f}`), '', 'Pass folder to see its sessions.'].join('\n');
}

// ----------------------------------------------------------------- models ---
// Claude Code has no "list models" command, so its aliases are listed here (from its
// model-config docs). Codex prints its own catalogue, so that side is read live.

const CLAUDE_MODELS = [
  ['opus', 'the latest Opus (Opus 5.5 today). The default on Pro, Max, Team and Enterprise.'],
  ['sonnet', 'the latest Sonnet (Sonnet 5.5 today). Lighter and faster than Opus.'],
  ['haiku', 'the latest Haiku (Haiku 5.5 today). Fastest and cheapest.'],
  ['fable', 'the latest Fable (Fable 5.1 today). On some plans it bills to usage credits instead of the plan.'],
  ['best', 'Fable where the plan includes it, otherwise the same as opus.'],
  ['opusplan', 'Opus to plan, Sonnet to execute. Delegated runs never use plan mode, so this acts like sonnet.'],
];
const CLAUDE_EFFORTS = ['low', 'medium', 'high', 'xhigh', 'max'];

// What each CLI itself falls back to when the bridge sets no model.
function claudeCliDefault() {
  const file = path.join(os.homedir(), '.claude', 'settings.json');
  try {
    const s = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (s && (s.model || s.effortLevel)) return { model: s.model || null, effort: s.effortLevel || null, file };
  } catch { /* no settings file, or not readable */ }
  return null;
}

function codexCliDefault() {
  const file = path.join(os.homedir(), '.codex', 'config.toml');
  try {
    const head = fs.readFileSync(file, 'utf8').split(/^[ \t]*\[/m)[0]; // top-level keys only
    const m = /^[ \t]*model[ \t]*=[ \t]*"([^"]+)"/m.exec(head);
    const e = /^[ \t]*model_reasoning_effort[ \t]*=[ \t]*"([^"]+)"/m.exec(head);
    if (m || e) return { model: m ? m[1] : null, effort: e ? e[1] : null, file };
  } catch { /* no config.toml, or not readable */ }
  return null;
}

// `codex debug models` prints the catalogue this Codex build offers.
let catalogCache = null; // { at, result } - the catalogue only changes when Codex is updated
function codexCatalog(cfg) {
  if (catalogCache && Date.now() - catalogCache.at < 10 * 60 * 1000) return Promise.resolve(catalogCache.result);
  return new Promise((resolve) => {
    const done = (result) => { if (result.ok) catalogCache = { at: Date.now(), result }; resolve(result); };
    let proc;
    // stdin is closed so an unexpected prompt cannot make this hang.
    try { proc = spawn(cfg.codexPath, ['debug', 'models'], { env: childEnv(cfg, 'codex'), stdio: ['ignore', 'pipe', 'pipe'] }); }
    catch (err) { return done({ ok: false, error: String(err.message || err) }); }
    let out = '', errOut = '', settled = false;
    const timer = setTimeout(() => { settled = true; try { proc.kill('SIGKILL'); } catch { /* gone */ } done({ ok: false, error: 'codex debug models timed out.' }); }, 20000);
    timer.unref?.();
    proc.stdout.on('data', (d) => { if (out.length < 64 * 1024 * 1024) out += d; });
    proc.stderr.on('data', (d) => { if (errOut.length < 8192) errOut += d; });
    proc.on('error', (err) => { if (settled) return; settled = true; clearTimeout(timer); done({ ok: false, error: String(err.code === 'ENOENT' ? `Codex was not found at ${cfg.codexPath}.` : err.message || err) }); });
    proc.on('close', () => {
      if (settled) return;
      settled = true; clearTimeout(timer);
      const i = out.indexOf('{');
      if (i < 0) return done({ ok: false, error: errOut.trim().split('\n')[0] || 'codex debug models printed no JSON (an older Codex may not have this command).' });
      try {
        const all = JSON.parse(out.slice(i)).models;
        if (!Array.isArray(all) || !all.length) return done({ ok: false, error: 'codex debug models listed no models.' });
        const list = all.filter((m) => m && m.visibility === 'list');
        list.sort((a, b) => (a.priority ?? 99) - (b.priority ?? 99));
        return done({ ok: true, models: list.length ? list : all });
      } catch (e2) { return done({ ok: false, error: `could not read the model list: ${String(e2.message || e2)}` }); }
    });
  });
}

async function listModels(cfg, agent) {
  const Name = agent === 'claude' ? 'Claude' : 'Codex';
  const d = agent === 'claude' ? cfg.claude : cfg.codex;
  const cli = agent === 'claude' ? claudeCliDefault() : codexCliDefault();
  const out = [`Models for ${Name} as a sub-agent.`, ''];
  out.push('In use now:');
  out.push(`  model:  ${d.model || `(not set by the bridge, so ${Name} uses its own default${cli && cli.model ? `: ${cli.model}` : ''})`}`);
  out.push(`  effort: ${d.effort || `(not set by the bridge, so ${Name} uses its own default${cli && cli.effort ? `: ${cli.effort}` : ''})`}`);
  if (cli) out.push(`  ${Name}'s own default comes from ${cli.file}.`);
  out.push('');
  if (agent === 'claude') {
    out.push('Aliases (each tracks the newest model of that family):');
    for (const [name, note] of CLAUDE_MODELS) out.push(`  ${name.padEnd(9)} ${note}`);
    out.push('');
    out.push('Exact versions: pass a full name such as claude-opus-5-5, claude-sonnet-5-5, claude-haiku-5-5 or claude-fable-5-1.');
    out.push(`Effort levels: ${CLAUDE_EFFORTS.join(', ')}.`);
  } else {
    const cat = await codexCatalog(cfg);
    if (!cat.ok) {
      out.push(`Could not read Codex's catalogue (${cat.error}).`);
      out.push('Ask the user to run `codex debug models`, or use a slug they give you.');
    } else {
      out.push('Models this Codex build offers (most current first):');
      for (const m of cat.models) {
        const levels = (m.supported_reasoning_levels || []).map((l) => l.effort).join(', ');
        out.push(`  ${String(m.slug).padEnd(16)} ${m.description || m.display_name || ''}`);
        out.push(`  ${''.padEnd(16)} effort: ${levels || 'n/a'} (its own default: ${m.default_reasoning_level || 'n/a'})`);
      }
      out.push('');
      out.push('Codex has no alias for "latest", so a slug is an exact model. Availability also depends on the plan.');
    }
  }
  out.push('');
  out.push(`To change it, call set_models (only when the user asks).`);
  out.push(`The model of the agent reading this is not set here; it is chosen in its own app.`);
  return out.join('\n');
}

// Change the stored default for the delegated agent. Applies to this bridge process at once
// and to later ones through bridge.config.json.
async function setModels(cfg, agent, args) {
  const Name = agent === 'claude' ? 'Claude' : 'Codex';
  const reset = Boolean(args.reset);
  const hasModel = args.model !== undefined && args.model !== null && String(args.model) !== '';
  const hasEffort = args.effort !== undefined && args.effort !== null && String(args.effort) !== '';
  if (!reset && !hasModel && !hasEffort) throw new UserError('Pass model, effort, or reset: true.');
  if (hasModel && !/^[A-Za-z0-9._:[\]/-]{2,80}$/.test(String(args.model))) throw new UserError('`model` must be a model alias or name.');
  if (hasEffort && !/^[a-z]{2,10}$/.test(String(args.effort))) throw new UserError('`effort` must be a single level word such as low, medium or high.');
  if (agent === 'claude' && hasEffort && !CLAUDE_EFFORTS.includes(String(args.effort))) {
    throw new UserError(`Claude's effort levels are ${CLAUDE_EFFORTS.join(', ')}.`);
  }
  const before = { model: cfg[agent].model, effort: cfg[agent].effort };
  const next = reset
    ? { model: hasModel ? String(args.model) : null, effort: hasEffort ? String(args.effort) : null }
    : { model: hasModel ? String(args.model) : before.model, effort: hasEffort ? String(args.effort) : before.effort };
  // merge into the file on disk so other settings and hand edits survive
  let onDisk = {};
  try { onDisk = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')); } catch { /* new file */ }
  onDisk[agent] = { ...(onDisk[agent] || {}), ...next };
  let mode = null;
  try { mode = fs.statSync(CONFIG_PATH).mode & 0o777; } catch { /* new file */ }
  const tmp = `${CONFIG_PATH}.${process.pid}.tmp`;
  ensureDir(path.dirname(CONFIG_PATH));
  fs.writeFileSync(tmp, JSON.stringify(onDisk, null, 2) + '\n');
  if (mode !== null) { try { fs.chmodSync(tmp, mode); } catch { /* keep default */ } }
  fs.renameSync(tmp, CONFIG_PATH);
  cfg[agent].model = next.model;
  cfg[agent].effort = next.effort;
  logEvent('models_set', { agent, before, after: next });
  // Soft check: an unknown name is not refused (plans differ), but say so.
  let warn = null;
  if (next.model) {
    if (agent === 'claude') {
      const known = CLAUDE_MODELS.some(([n]) => n === next.model) || /^claude-/.test(next.model);
      if (!known) warn = `"${next.model}" is not a Claude alias or a claude-* model name. Check it with list_models.`;
    } else {
      const cat = await codexCatalog(cfg);
      if (cat.ok && !cat.models.some((m) => m.slug === next.model)) {
        warn = `"${next.model}" is not in this Codex build's catalogue. Check it with list_models.`;
      }
    }
  }
  const show = (v, what) => v || `(unset: ${Name}'s own default ${what})`;
  return [
    `${Name} as a sub-agent now uses:`,
    `  model:  ${show(next.model, 'applies')}`,
    `  effort: ${show(next.effort, 'applies')}`,
    `Was: model ${before.model || 'unset'}, effort ${before.effort || 'unset'}.`,
    'Saved, so it holds for later chats too. It applies from the next delegation; one already running keeps its model.',
    ...(warn ? [`Warning: ${warn}`] : []),
    'Tell the user what changed.',
  ].filter(Boolean).join('\n');
}

// ------------------------------------------------------------------ tools ---

function toolDefs(caller, maxWait) {
  const agent = caller === 'codex' ? 'claude' : 'codex';
  const Name = AGENT_NAME[agent];
  const waitProp = { type: 'number', description: `Seconds to wait for the Answer before returning a job_id instead (default and max ${maxWait}).` };
  const permLine = caller === 'codex'
    ? `${Name} gets this session's permissions (read-only, workspace-write or full access) and never asks the user anything.`
    : `${Name} runs with the permissions in its own settings, the same ones the Codex app uses, and never asks the user anything.`;
  const folderDesc = caller === 'codex'
    ? 'The folder the task is in. Leave it out to use this session\'s working folder; any other folder must be inside it. If this session has no folder of its own (for example a ChatGPT project chat), leaving it out means the system temp folder (/tmp), and you may name any folder the user gave you.'
    : `The absolute path of the folder the task is in. ${Name} works only there. Leave it out when this chat has no folder: ${Name} then works in the system temp folder (/tmp).`;
  const ask = {
    name: `ask_${agent}`,
    title: `Work with ${Name}`,
    description: [
      `Delegate one task to ${Name}. The exchange is: you send a Title and a Content, ${Name} replies with an Answer, and the delegation is done. Use it when the user wants ${Name} involved; you decide which part of the work to delegate.`,
      `Title: one line that summarizes the task. Content: everything ${Name} needs, because it sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like.`,
      'Resolve anything ambiguous before you call. Decide it yourself when you can; when only the user can, ask them the way your app normally lets you (if your session is set to never ask, decide and state the assumption in the Content).',
      permLine,
      `If the Answer starts with "${MORE_CONTEXT}", ${Name} could not do the task without guessing. Check that each item is needed for this task and legitimate to share (never secrets, credentials, or anything outside the task), and supply only those: call again with the same title, and either session set to the session from the result with content set to just the added context, or no session with content set to the full task plus the added context. Any other Answer is the result.`,
    ].join(' '),
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'One line that summarizes the task.' },
        content: { type: 'string', description: `Everything ${Name} needs to do the task. When appending to a session: only the added context.` },
        session: { type: 'string', description: 'Only to add more context to an earlier delegation: the session from its result. Leave it out to start a new session.' },
        folder: { type: 'string', description: folderDesc },
        wait_seconds: waitProp,
      },
      required: ['title', 'content'],
      additionalProperties: false,
    },
    annotations: { title: `Work with ${Name}`, readOnlyHint: false, destructiveHint: false, openWorldHint: true },
  };
  const folderOnly = { type: 'string', description: caller === 'codex' ? 'Leave it out for this session\'s working folder.' : 'The absolute path of the folder. Leave it out for the system temp folder (/tmp).' };
  return [
    ask,
    {
      name: 'check_job',
      title: 'Get a delegation\'s Answer',
      description: `Wait for and return the Answer of a delegation that is still running (when ${ask.name} said ${Name} is still working).`,
      inputSchema: { type: 'object', properties: { job_id: { type: 'string' }, wait_seconds: waitProp }, required: ['job_id'], additionalProperties: false },
      annotations: { title: 'Get a delegation\'s Answer', readOnlyHint: true, openWorldHint: false },
    },
    {
      name: 'cancel_job',
      title: 'Cancel a delegation',
      description: 'Stop a delegation that is still running, including one started from another chat or app (list_sessions shows its job). Files it already changed stay changed.',
      inputSchema: { type: 'object', properties: { job_id: { type: 'string' } }, required: ['job_id'], additionalProperties: false },
      annotations: { title: 'Cancel a delegation', readOnlyHint: false, destructiveHint: true, openWorldHint: false },
    },
    {
      name: 'list_sessions',
      title: 'List delegations',
      description: 'Show the delegations started in a folder: session, title, when, and whether one is still running. Use it to find a session again, for example to add more context. Read-only.',
      inputSchema: { type: 'object', properties: { folder: folderOnly }, additionalProperties: false },
      annotations: { title: 'List delegations', readOnlyHint: true, openWorldHint: false },
    },
    {
      name: 'view_changes',
      title: 'View changes in folder',
      description: 'Show what changed in a folder: git status and diff, or recently modified files when it is not a git repository. Read-only.',
      inputSchema: { type: 'object', properties: { folder: folderOnly }, additionalProperties: false },
      annotations: { title: 'View changes in folder', readOnlyHint: true, openWorldHint: false },
    },
    {
      name: 'list_models',
      title: `List ${Name} models`,
      description: `Show which models and effort levels ${Name} can run on, and which ones it uses now. Read-only.`,
      inputSchema: { type: 'object', properties: {}, additionalProperties: false },
      annotations: { title: `List ${Name} models`, readOnlyHint: true, openWorldHint: false },
    },
    {
      name: 'set_models',
      title: `Set ${Name}'s model`,
      description: `Change the model and effort ${Name} uses for every later delegation, saved for other chats too. Only when the user asks for it. Call list_models first if you are unsure of the name.`,
      inputSchema: {
        type: 'object',
        properties: {
          model: { type: 'string', description: agent === 'claude' ? 'An alias such as opus, sonnet or haiku, or a full model name. Omit to leave the model as it is.' : 'A Codex model slug from list_models. Omit to leave the model as it is.' },
          effort: { type: 'string', description: `Effort level${agent === 'claude' ? ' (low, medium, high, xhigh or max)' : ' supported by that model'}. Omit to leave it as it is.` },
          reset: { type: 'boolean', description: `true to clear the bridge's setting and let ${Name} use its own default.` },
        },
        additionalProperties: false,
      },
      annotations: { title: `Set ${Name}'s model`, readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
    },
  ];
}

async function viewChanges(cfg, folder) {
  const status = await gitStatus(cfg, folder);
  if (status === null) {
    const files = await recentFiles(folder, Date.now() - 6 * 3600 * 1000, 100);
    return [`folder: ${folder}`, 'Not a git repository, so there is no diff. Files modified in the last 6 hours:', ...(files.length ? files.map((f) => `  ${f}`) : ['  (none)'])].join('\n');
  }
  const stat = await runGit(cfg, folder, ['diff', '--stat', 'HEAD']);
  const diff = await runGit(cfg, folder, ['diff', 'HEAD']);
  const untracked = await runGit(cfg, folder, ['ls-files', '--others', '--exclude-standard']);
  const parts = [`folder: ${folder}`, '', 'git status --short:', status];
  if (stat.ok && stat.stdout.trim()) parts.push('', 'diff stat (vs HEAD):', stat.stdout.trim());
  if (untracked.ok && untracked.stdout.trim()) parts.push('', 'untracked files (contents not shown, read them directly):', untracked.stdout.trim());
  parts.push('', 'diff (vs HEAD):', diff.ok ? diff.stdout || '(empty)' : (diff.stderr || 'git diff failed (maybe no commits yet)'));
  return parts.join('\n');
}

let sandboxLogged = false;

function markCancelled(job, why) {
  job.status = 'cancelled';
  job.error = why;
}

// Cancel a job run by this bridge process.
function cancelJob(id, why) {
  const job = running.get(id);
  if (!job || job.status !== 'running') return false;
  markCancelled(job, why);
  killTree(job.proc);
  logEvent('job_cancelled', { job: id, why });
  return true;
}

const pidExists = (pid) => { if (!pid) return false; try { process.kill(pid, 0); return true; } catch { return false; } };

// Cancel a job wherever it runs: in this process, or in another bridge process (another app or chat).
function cancelAnywhere(id, why) {
  if (cancelJob(id, why)) return 'cancelled';
  const rec = loadJobFromDisk(id);
  if (!rec) return 'unknown';
  if (rec.status !== 'running') return rec.status;
  if (rec.pid && pidExists(rec.pid)) {
    try { ensureDir(path.dirname(cancelMarker(id))); fs.writeFileSync(cancelMarker(id), why); } catch { /* still kill it */ }
    killPid(rec.pid);
    logEvent('job_cancelled', { job: id, why, crossProcess: true });
    return 'cancelled';
  }
  return 'not running (its bridge process is gone)';
}

function runningJobsOnDisk() {
  let files = [];
  try { files = fs.readdirSync(JOB_DIR).filter((f) => f.endsWith('.json')); } catch { return []; }
  return files.map((f) => { try { return JSON.parse(fs.readFileSync(path.join(JOB_DIR, f), 'utf8')); } catch { return null; } })
    .filter((j) => j && j.status === 'running' && pidExists(j.pid));
}

async function callTool(cfg, caller, maxWait, name, args, meta, progress, ctx) {
  args = args || {};
  // Unknown arguments are refused, so a mistaken call fails clearly instead of being half-understood.
  const def = toolDefs(caller, maxWait).find((t) => t.name === name);
  if (def) {
    const allowed = Object.keys(def.inputSchema.properties || {});
    const extra = Object.keys(args).filter((k) => !allowed.includes(k));
    if (extra.length) throw new UserError(`Unknown argument${extra.length > 1 ? 's' : ''}: ${extra.join(', ')}. ${name} takes ${allowed.length ? allowed.join(', ') : 'no arguments'}.`);
  }
  const clientRoots = ctx?.clientRoots || [];
  const wait = Math.max(0, Math.min(Number(args.wait_seconds ?? maxWait), maxWait));
  const agent = caller === 'codex' ? 'claude' : 'codex';
  const sandbox = caller === 'codex' ? parseSandboxMeta(meta) : null;
  if (caller === 'codex' && !sandboxLogged && name === `ask_${agent}`) {
    sandboxLogged = true;
    logEvent('sandbox_meta', { received: Boolean(sandbox), parsed: sandbox, metaKeys: meta && typeof meta === 'object' ? Object.keys(meta) : [] });
  }
  if (name === `ask_${agent}`) {
    const where = await resolveWorkFolder(args, sandbox, clientRoots);
    const job = await startJob(cfg, { agent, caller, args, perm: callerPermission(agent, sandbox), where });
    if (ctx) ctx.jobId = job.id;
    await waitForJob(job, wait, progress);
    return { text: describeJob(job), isError: job.status === 'failed' };
  }
  if (name === 'check_job') {
    const id = String(args.job_id || '').trim();
    const job = running.get(id) || loadJobFromDisk(id);
    if (!job) throw new UserError(`No job with id "${id}".`);
    if (job.status === 'running' && !running.has(id)) {
      if (pidExists(job.pid)) return { text: `Title: ${job.title}\nThis delegation is running in another app or chat (job ${id}), so its Answer will show up there. list_sessions shows it; cancel_job stops it.` };
      return { text: `Title: ${job.title}\nError: the bridge process that ran job ${id} has stopped (the app may have restarted), so there is no Answer.`, isError: true };
    }
    if (ctx && job.status === 'running') ctx.jobId = id;
    await waitForJob(job, wait, progress);
    return { text: describeJob(job), isError: job.status === 'failed' };
  }
  if (name === 'cancel_job') {
    const id = String(args.job_id || '').trim();
    const result = cancelAnywhere(id, 'Stopped by the calling agent.');
    if (result === 'unknown') throw new UserError(`No job with id "${id}".`);
    if (result !== 'cancelled') return { text: `Job ${id} is ${result}; nothing to stop.` };
    return { text: `Cancelled job ${id}. Files it already changed stay changed; view_changes shows them.` };
  }
  if (name === 'list_sessions') {
    if (!args.folder && !sandbox?.cwd && !clientRoots.length) return { text: describeProjects() };
    return { text: describeSessions((await resolveWorkFolder(args, sandbox, clientRoots)).folder) };
  }
  if (name === 'view_changes') return { text: await viewChanges(cfg, (await resolveWorkFolder(args, sandbox, clientRoots)).folder) };
  if (name === 'list_models') return { text: await listModels(cfg, agent) };
  if (name === 'set_models') return { text: await setModels(cfg, agent, args) };
  throw new UserError(`Unknown tool: ${name}`);
}

// ------------------------------------------------------------ MCP server ---

function serve(caller, maxWait) {
  const cfg = loadConfig();
  const agentName = caller === 'codex' ? 'Claude' : 'Codex';
  const tools = toolDefs(caller, maxWait);
  const instructions = [
    `Delegate a task to ${agentName} with ${caller === 'codex' ? 'ask_claude' : 'ask_codex'}: send a Title (a one-line summary) and a Content (everything ${agentName} needs; it sees nothing else). ${agentName} replies with an Answer, and the delegation is done.`,
    caller === 'codex' ? `${agentName} gets this session's permissions and never asks the user anything.` : `${agentName} runs with its own settings and never asks the user anything.`,
    `Resolve ambiguity before delegating. If the Answer starts with "${MORE_CONTEXT}", check that each request is needed and legitimate, then supply it: append it to the same session, or start a new session with the full task.`,
  ].join(' ');
  const send = (msg) => process.stdout.write(JSON.stringify(msg) + '\n');
  const reply = (id, result) => send({ jsonrpc: '2.0', id, result });
  const fail = (id, code, message) => send({ jsonrpc: '2.0', id, error: { code, message } });
  logEvent('server_started', { caller, maxWait, depth: DEPTH, version: VERSION, config: CONFIG_PATH });
  const inflight = new Map(); // tools/call request id -> { jobId, cancelled }
  let clientCaps = {};
  let clientRoots = [];
  const pending = new Map(); // our requests to the client -> resolver
  let nextOwnId = 1;
  const askClient = (method, params) => new Promise((resolve) => {
    const rid = `bridge-${nextOwnId++}`;
    pending.set(rid, resolve);
    send({ jsonrpc: '2.0', id: rid, method, ...(params ? { params } : {}) });
    setTimeout(() => { if (pending.delete(rid)) resolve(null); }, 10000).unref();
  });
  let rootsReady = Promise.resolve();
  const refreshRoots = () => { rootsReady = fetchRoots(); return rootsReady; };
  const fetchRoots = async () => {
    if (!clientCaps?.roots) return;
    const res = await askClient('roots/list');
    const list = Array.isArray(res?.result?.roots) ? res.result.roots : [];
    clientRoots = list.map((r) => { try { return r.uri?.startsWith('file://') ? fileURLToPath(r.uri) : null; } catch { return null; } }).filter(Boolean);
    logEvent('client_roots', { count: clientRoots.length, roots: clientRoots });
  };

  async function handle(msg) {
    const { id, method, params } = msg;
    const isRequest = id !== undefined && id !== null;
    if (!method) {
      if (id !== undefined && pending.has(id)) { const done = pending.get(id); pending.delete(id); done(msg); }
      return;
    }
    try {
      switch (method) {
        case 'initialize': {
          clientCaps = params?.capabilities || {};
          const capabilities = { tools: { listChanged: false } };
          // Ask Codex to share the calling session's sandbox policy with each tool call.
          if (caller === 'codex') capabilities.experimental = { 'codex/sandbox-state': {}, 'codex/sandbox-state-meta': {} };
          return reply(id, {
            protocolVersion: params?.protocolVersion || '2025-06-18',
            capabilities,
            serverInfo: { name: `claude-codex-bridge (${agentName})`, version: VERSION },
            instructions,
          });
        }
        case 'ping':
          return isRequest && reply(id, {});
        case 'tools/list':
          return reply(id, { tools });
        case 'tools/call': {
          const meta = params?._meta;
          const token = meta?.progressToken;
          const progress = token === undefined ? null : (n, message) => send({ jsonrpc: '2.0', method: 'notifications/progress', params: { progressToken: token, progress: n, message } });
          const ctx = { jobId: null, cancelled: false };
          if (isRequest) inflight.set(id, ctx);
          try {
            await rootsReady;
            ctx.clientRoots = clientRoots;
            const r = await callTool(cfg, caller, maxWait, params?.name, params?.arguments, meta, progress, ctx);
            if (ctx.cancelled) return; // the caller cancelled this request; per MCP, don't answer it
            return reply(id, { content: [{ type: 'text', text: r.text }], isError: Boolean(r.isError) });
          } catch (err) {
            if (ctx.cancelled) return;
            if (!(err instanceof UserError)) logEvent('tool_error', { tool: params?.name, error: String(err.stack || err) });
            return reply(id, { content: [{ type: 'text', text: `Error: ${err.message || err}` }], isError: true });
          } finally {
            inflight.delete(id);
          }
        }
        case 'notifications/initialized':
        case 'notifications/roots/list_changed':
          refreshRoots().catch(() => {});
          return;
        case 'notifications/cancelled': {
          // The calling app stopped waiting for a tool call: the user pressed stop, or the call timed out.
          const ctx = inflight.get(params?.requestId);
          const reason = String(params?.reason || '');
          logEvent('client_cancelled', { requestId: params?.requestId, reason, job: ctx?.jobId || null });
          if (!ctx) return;
          ctx.cancelled = true;
          const onlyTimeout = /time(?:d)?[\s_-]?out/i.test(reason);
          if (ctx.jobId && cfg.cancelOnStop && !onlyTimeout) cancelJob(ctx.jobId, `The calling agent was stopped${reason ? ` (${reason})` : ''}.`);
          return;
        }
        case 'resources/list': return reply(id, { resources: [] });
        case 'prompts/list': return reply(id, { prompts: [] });
        default:
          if (isRequest) return fail(id, -32601, `Method not found: ${method}`);
      }
    } catch (err) {
      logEvent('handler_error', { method, error: String(err.stack || err) });
      if (isRequest) fail(id, -32603, String(err.message || err));
    }
  }

  const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
  rl.on('line', (line) => {
    const t = line.trim();
    if (!t) return;
    let msg;
    try { msg = JSON.parse(t); } catch { return send({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }); }
    if (Array.isArray(msg)) msg.forEach((m) => handle(m)); else handle(msg);
  });
  const shutdown = () => {
    for (const job of running.values()) {
      if (job.status === 'running') {
        job.status = 'cancelled';
        job.error = 'The bridge shut down before the delegation finished.';
        killTree(job.proc);
        saveJob(job);
      }
    }
    logEvent('server_stopped', { caller });
    setTimeout(() => process.exit(0), 300).unref();
  };
  rl.on('close', shutdown);
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

// ------------------------------------------------------------- CLI modes ---

async function tryMode(argv) {
  const cfg = loadConfig();
  const agent = argv.try;
  if (agent !== 'claude' && agent !== 'codex') throw new UserError('--try needs "claude" or "codex".');
  const caller = agent === 'claude' ? 'codex' : 'claude';
  // --level read|auto|full pretends the calling Codex session has that permission level (Claude only).
  const level = ['read', 'auto', 'full'].includes(argv.level) && agent === 'claude' ? argv.level : null;
  const sandbox = level ? { level, network: argv['no-network'] ? false : true, mode: `--level ${level}` } : null;
  const where = await resolveWorkFolder({ folder: argv.folder || process.cwd() }, null, []);
  const job = await startJob(cfg, {
    agent, caller, where, perm: callerPermission(agent, sandbox),
    args: { title: typeof argv.title === 'string' ? argv.title : 'Test from the terminal', content: argv._.join(' ') || 'Reply with a short greeting. Do not change any files.', session: argv.session },
  });
  process.stderr.write(`Running ${agent} (job ${job.id}, session ${job.session}) in ${job.folder} ...\n`);
  await job.done;
  process.stdout.write(describeJob(job) + '\n');
  process.exit(job.status === 'done' ? 0 : 1);
}

function parseArgs(argv) {
  const out = { _: [] };
  const flags = new Set(['sessions', 'version', 'paths', 'jobs', 'reset', 'no-network']);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (!flags.has(key) && next !== undefined && !next.startsWith('--')) { out[key] = next; i++; } else out[key] = true;
    } else out._.push(a);
  }
  return out;
}

const argv = process.argv[2] === '--watchdog' ? null : parseArgs(process.argv.slice(2));
if (!argv) {
  watchdogMode(process.argv.slice(3));
} else if (argv.version) {
  process.stdout.write(`claude-codex-bridge ${VERSION}\n`);
} else if (argv.paths) {
  process.stdout.write(JSON.stringify({ config: CONFIG_PATH, state: STATE_DIR, log: path.join(STATE_DIR, 'bridge.log'), jobs: JOB_DIR, perFolder: REG_DIR_NAME }, null, 2) + '\n');
} else if (argv.cancel) {
  const targets = argv.cancel === true || argv.cancel === 'all' ? runningJobsOnDisk().map((j) => j.id) : [String(argv.cancel)];
  if (!targets.length) process.stdout.write('No delegations are running.\n');
  for (const id of targets) process.stdout.write(`${id}: ${cancelAnywhere(id, 'Stopped from the terminal (--cancel).')}\n`);
} else if (argv.jobs) {
  const list = runningJobsOnDisk();
  process.stdout.write(list.length
    ? list.map((j) => `${j.id}  ${j.session}  since ${j.startedAt}  "${j.title}"  ${j.folder}`).join('\n') + '\n'
    : 'No delegations are running.\n');
} else if (argv.sessions) {
  (async () => {
    process.stdout.write((argv.folder ? describeSessions((await resolveWorkFolder({ folder: argv.folder }, null, [])).folder) : describeProjects()) + '\n');
  })().catch((err) => { process.stderr.write(`Error: ${err.message || err}\n`); process.exit(1); });
} else if (argv.models) {
  (async () => {
    const cfg = loadConfig();
    const agents = argv.models === true ? ['claude', 'codex'] : [String(argv.models)];
    for (const agent of agents) {
      if (agent !== 'claude' && agent !== 'codex') throw new UserError('--models takes claude or codex, or nothing for both.');
      if (argv['set-model'] || argv['set-effort'] || argv.reset) {
        process.stdout.write(await setModels(cfg, agent, { model: argv['set-model'], effort: argv['set-effort'], reset: argv.reset === true }) + '\n\n');
      } else {
        process.stdout.write(await listModels(cfg, agent) + '\n\n');
      }
    }
  })().catch((err) => { process.stderr.write(`Error: ${err.message || err}\n`); process.exit(1); });
} else if (argv.try) {
  tryMode(argv).catch((err) => { process.stderr.write(`Error: ${err.message || err}\n`); process.exit(1); });
} else {
  const caller = argv.caller;
  if (caller !== 'codex' && caller !== 'claude') {
    process.stderr.write([
      'Usage: node server.mjs --caller codex|claude [--max-wait SECONDS]',
      '       node server.mjs --try claude|codex --folder DIR --title "one-line summary" [--session ID] [--level read|auto|full] "content"',
      '       node server.mjs --sessions [--folder DIR]',
      '       node server.mjs --models [claude|codex]     list models and the current defaults',
      '       node server.mjs --models claude --set-model opus --set-effort xhigh',
      '       node server.mjs --jobs                      list running delegations',
      '       node server.mjs --cancel JOB_ID|all         stop delegations',
      '',
    ].join('\n'));
    process.exit(2);
  }
  serve(caller, Math.max(5, Math.min(Number(argv['max-wait']) || 50, 3600)));
}
