#!/usr/bin/env node
// End-to-end self-test for claude-codex-bridge, using the real `claude` and `codex` CLIs.
//
//   node selftest.mjs            run everything (a few minutes; uses a little of both plans)
//   node selftest.mjs --direct   skip the tests where the real agents call the bridge themselves
//   node selftest.mjs --clean    delete the test folder afterwards
//
// The direct checks run on light models (Claude haiku, Codex at low effort) through a copy of
// your config, so your own defaults are not changed or spent. The test folder is created in your
// temp folder; the only file written here is selftest-report.md (secrets redacted, no env vars).

import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SERVER = path.join(HERE, 'server.mjs');
const CONFIG = path.join(HERE, 'bridge.config.json');
// Where the bridge keeps its shared state (outside this folder); asked from the bridge itself.
const PATHS = JSON.parse(execFileSync(process.execPath, [SERVER, '--paths'], { encoding: 'utf8' }));
const LOG_DIR = PATHS.state;
const REPORT = path.join(HERE, 'selftest-report.md');
const HOME = os.homedir();
const CODEX_CONFIG = path.join(process.env.CODEX_HOME || path.join(HOME, '.codex'), 'config.toml');
const DESKTOP_CONFIG = path.join(HOME, 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json');
const SKILL_DIR = path.join(HOME, '.agents', 'skills', 'work-with-claude');
const args = new Set(process.argv.slice(2));
const STAMP = new Date().toISOString().replace(/[:.]/g, '-');
const RUN_DIR = path.join(fs.realpathSync(os.tmpdir()), 'claude-codex-bridge-selftest', `run-${STAMP}`);
const PROJ = path.join(RUN_DIR, 'project');
const TEST_CONFIG = path.join(RUN_DIR, 'bridge.config.json');

const SECRETS = [
  [/\bsk-(?:ant-|proj-)?[A-Za-z0-9_-]{16,}\b/g, '[REDACTED KEY]'],
  [/\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b/g, '[REDACTED TOKEN]'],
  [/\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g, '[REDACTED JWT]'],
  [/\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{16,}/gi, '$1 [REDACTED]'],
  [/((?:api[_-]?key|secret|token|passw(?:or)?d|authorization)["']?\s*[:=]\s*["']?)[^\s"',;]{8,}/gi, '$1[REDACTED]'],
];
const redact = (s) => SECRETS.reduce((t, [re, rep]) => t.replace(re, rep), String(s ?? ''));

const results = [];
const notes = [];
const out = (s = '') => process.stdout.write(s + '\n');
function record(name, ok, detail = '', secs = null) {
  results.push({ name, ok, detail: redact(detail), secs });
  out(`${ok ? '  PASS' : '  FAIL'}  ${name}${secs !== null ? `  (${secs}s)` : ''}${!ok && detail ? `\n        ${redact(detail).split('\n').slice(0, 8).join('\n        ')}` : ''}`);
}
function version(bin) {
  try { return execFileSync(bin, ['--version'], { encoding: 'utf8', timeout: 20000, stdio: ['ignore', 'pipe', 'ignore'] }).trim().split('\n')[0]; } catch { return null; }
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pidAlive = (pid) => { if (!pid) return false; try { process.kill(pid, 0); return true; } catch { return false; } };
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return null; } };
const lines = (f) => (read(f) || '').split('\n').filter((l) => l.length);
const field = (t, k) => (new RegExp(`^${k}: (.*)$`, 'm').exec(t) || [])[1] || '';
const answerOf = (t) => { const m = /^Answer:\n([\s\S]*?)\n\nsession: /m.exec(t || ''); return m ? m[1] : null; };
const registry = () => { try { return JSON.parse(read(path.join(PROJ, '.session', 'sessions.json'))).sessions; } catch { return {}; } };
const bridgeFolderState = () => { const out = []; const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const f = path.join(d, e.name); if (f === REPORT) continue; if (e.isDirectory()) walk(f); else out.push(`${path.relative(HERE, f)}@${fs.statSync(f).mtimeMs}`); } }; try { walk(HERE); } catch { /* ignore */ } return out.sort().join('\n'); };
const BRIDGE_BEFORE = bridgeFolderState();
async function timed(fn) { const t = Date.now(); const r = await fn(); return [r, Math.round((Date.now() - t) / 1000)]; }

function runCmd(cmd, cmdArgs, { cwd, env, input, timeoutMs }) {
  return new Promise((resolve) => {
    const p = spawn(cmd, cmdArgs, { cwd, env, stdio: ['pipe', 'pipe', 'pipe'] });
    let stdout = ''; let stderr = '';
    const timer = setTimeout(() => { try { p.kill('SIGTERM'); } catch { /* gone */ } }, timeoutMs);
    p.stdout.on('data', (d) => { stdout += d; });
    p.stderr.on('data', (d) => { stderr += d; });
    p.on('error', (err) => { clearTimeout(timer); resolve({ code: null, stdout, stderr: String(err) }); });
    p.on('close', (code) => { clearTimeout(timer); resolve({ code, stdout, stderr }); });
    p.stdin.on('error', () => { /* the program may exit without reading its input */ });
    p.stdin.end(input || '');
  });
}

// --------------------------------------------------------------- MCP client ---

function startBridge(caller) {
  const env = { ...process.env, CLAUDE_CODEX_BRIDGE_CONFIG: TEST_CONFIG };
  const srv = spawn(process.execPath, [SERVER, '--caller', caller, '--max-wait', '600'], { stdio: ['pipe', 'pipe', 'pipe'], env });
  let buf = '';
  const waiters = new Map();
  let id = 1;
  srv.stdout.on('data', (d) => {
    buf += d;
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, i); buf = buf.slice(i + 1);
      let m; try { m = JSON.parse(line); } catch { continue; }
      if (m.id && waiters.has(m.id)) { waiters.get(m.id)(m); waiters.delete(m.id); }
    }
  });
  const req = (method, params) => new Promise((resolve) => { const n = id++; waiters.set(n, resolve); srv.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: n, method, params }) + '\n'); });
  const call = async (name, a, meta) => {
    const r = await req('tools/call', { name, arguments: a, ...(meta ? { _meta: meta } : {}) });
    if (r.error) return { text: `MCP error: ${r.error.message}`, isError: true };
    return { text: r.result.content[0].text, isError: r.result.isError };
  };
  const startCall = (name, a, meta) => { const n = id++; srv.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: n, method: 'tools/call', params: { name, arguments: a, ...(meta ? { _meta: meta } : {}) } }) + '\n'); return n; };
  const cancel = (requestId, reason) => srv.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/cancelled', params: { requestId, reason } }) + '\n');
  return { req, call, startCall, cancel, stop: () => srv.stdin.end() };
}

// If a delegation is still running when the call returns, collect its Answer with check_job.
// The test itself gives up after 20 minutes and cancels the run, so a stuck CLI can't hang it.
async function finish(b, r) {
  const started = Date.now();
  let m;
  while ((m = /is still working \(job ([a-f0-9]{8})/.exec(r.text || ''))) {
    if (Date.now() - started > 20 * 60000) {
      await b.call('cancel_job', { job_id: m[1] });
      return { text: `${r.text}\n(the self-test gave up after 20 minutes and cancelled it)`, isError: true };
    }
    r = await b.call('check_job', { job_id: m[1] });
  }
  return r;
}

// A Codex session in workspace-write, as current Codex describes it in tool-call _meta.
const special = (kind, access) => ({ path: { type: 'special', value: { kind } }, access });
const codexMeta = () => {
  const st = { permissionProfile: { type: 'managed', file_system: { type: 'restricted', entries: [special('root', 'read'), special('project_roots', 'write')] }, network: 'enabled' }, sandboxCwd: pathToFileURL(PROJ).href };
  return { 'codex/sandbox-state': st, 'codex/sandbox-state-meta': st };
};
const callArgs = (agent, a) => (agent === 'codex' ? { ...a, folder: PROJ } : a); // Claude Desktop has to name the folder

// ------------------------------------------------------------------- tests ---

async function preflight(cfg) {
  out('\nSetup checks');
  const node = Number(process.versions.node.split('.')[0]);
  record(`Node ${process.versions.node} (needs 18+)`, node >= 18);
  const cv = cfg.claudePath && version(cfg.claudePath);
  const xv = cfg.codexPath && version(cfg.codexPath);
  record(`claude found: ${cfg.claudePath} (${cv || 'version check failed'})`, Boolean(cv));
  record(`codex found: ${cfg.codexPath} (${xv || 'version check failed'})`, Boolean(xv));
  const toml = read(CODEX_CONFIG) || '';
  const block = (/\[mcp_servers\.claude_bridge\][\s\S]*?(?=\n\[|$)/.exec(toml) || [''])[0];
  record('Codex config has [mcp_servers.claude_bridge] pointing at this bridge', block.includes(SERVER), CODEX_CONFIG);
  record('Codex runs the bridge tools without prompting (default_tools_approval_mode = "approve")', /default_tools_approval_mode\s*=\s*"approve"/.test(block), block);
  const sb = (/^\s*sandbox_mode\s*=\s*"([^"]+)"/m.exec(toml.split(/^\s*\[/m)[0]) || [])[1];
  notes.push(`Codex as a sub-agent uses Codex's own settings. Top-level sandbox_mode in ${CODEX_CONFIG}: ${sb ? `"${sb}"` : 'not set (Codex picks its default)'}.`);
  let desktopOk = false;
  try { desktopOk = JSON.parse(read(DESKTOP_CONFIG) || '{}').mcpServers?.codex_bridge?.args?.includes(SERVER); } catch { /* invalid */ }
  record('Claude Desktop config has codex_bridge pointing at this bridge', Boolean(desktopOk), DESKTOP_CONFIG);
  record('Codex skill work-with-claude installed (manual only)', /Title/.test(read(path.join(SKILL_DIR, 'SKILL.md')) || '') && /allow_implicit_invocation:\s*false/.test(read(path.join(SKILL_DIR, 'agents', 'openai.yaml')) || ''));
  const list = await runCmd(cfg.codexPath, ['mcp', 'list'], { cwd: HOME, env: process.env, timeoutMs: 30000 });
  record('`codex mcp list` shows claude_bridge enabled', /claude_bridge\s.*enabled/.test(list.stdout), list.stdout.slice(0, 400) || list.stderr.slice(0, 400));
  return Boolean(cv && xv);
}

function makeProject(cfg) {
  fs.mkdirSync(PROJ, { recursive: true });
  fs.writeFileSync(path.join(PROJ, 'README.md'), '# selftest project\n');
  try {
    execFileSync('git', ['init', '-q'], { cwd: PROJ });
    execFileSync('git', ['-c', 'user.email=selftest@local', '-c', 'user.name=selftest', 'add', '.'], { cwd: PROJ });
    execFileSync('git', ['-c', 'user.email=selftest@local', '-c', 'user.name=selftest', 'commit', '-qm', 'init'], { cwd: PROJ });
  } catch { notes.push('git is not available, so the git checks were skipped.'); }
  // light models for the direct checks; everything else as installed
  fs.writeFileSync(TEST_CONFIG, JSON.stringify({ ...cfg, claude: { ...(cfg.claude || {}), model: 'haiku', effort: 'low' }, codex: { ...(cfg.codex || {}), effort: 'low' } }, null, 2));
}

async function directTests(agent) {
  const Name = agent === 'claude' ? 'Claude' : 'Codex';
  const caller = agent === 'claude' ? 'codex' : 'claude';
  out(`\n${caller === 'codex' ? 'Codex' : 'Claude Desktop'} -> ${Name} (direct bridge calls)`);
  const b = startBridge(caller);
  await b.req('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'selftest', version: '1' } });
  const meta = caller === 'codex' ? codexMeta() : undefined;

  // 1. a fully specified task
  const file = path.join(PROJ, `hello-${agent}.txt`);
  let [r, s] = await timed(async () => finish(b, await b.call(`ask_${agent}`, callArgs(agent, { title: `Create hello-${agent}.txt`, content: `Create a file named hello-${agent}.txt in the working folder containing exactly one line: hello from ${agent}\nDo not create or change any other file.` }), meta)));
  const wrote = (read(file) || '').trim() === `hello from ${agent}`;
  record(`${Name}: a fully specified task comes back as an Answer and is done`, !r.isError && answerOf(r.text) !== null && wrote, r.text, s);
  record(`${Name}: permissions come from ${caller === 'codex' ? 'the calling Codex session' : 'Codex\'s own settings'} (${field(r.text, 'permissions')})`,
    caller === 'codex' ? /^this Codex session/.test(field(r.text, 'permissions')) : /^Codex's own settings/.test(field(r.text, 'permissions')), r.text);
  if (agent === 'codex' && !wrote) notes.push('Codex as a sub-agent could not write the file with its own settings. If you want it to edit files when Claude delegates, set sandbox_mode = "workspace-write" at the top of ~/.codex/config.toml (the Codex app uses the same file).');

  // 2. a task that is missing a fact the sub-agent cannot know
  const greet = path.join(PROJ, `greeting-${agent}.txt`);
  [r, s] = await timed(async () => finish(b, await b.call(`ask_${agent}`, callArgs(agent, { title: `Write greeting-${agent}.txt`, content: `Create greeting-${agent}.txt in the working folder with one line that greets the user's manager by first name. The manager's name is not in this folder or in this message.` }), meta)));
  const sid = field(r.text, 'session');
  const asked = /^More context needed:/i.test(answerOf(r.text) || '');
  record(`${Name}: missing information comes back as "More context needed:" instead of a guess`, asked && !fs.existsSync(greet), r.text, s);
  if (!asked) notes.push(`${Name} did not ask for more context on the greeting task (models sometimes guess); the protocol still works, as the next check shows.`);

  // 3. append the context to the same session
  if (!sid || !registry()[sid]?.agentSessionId) {
    record(`${Name}: appended context continues the same session`, false, 'skipped: the previous delegation produced no session to append to');
    b.stop();
    return;
  }
  const before = registry()[sid]?.agentSessionId;
  [r, s] = await timed(async () => finish(b, await b.call(`ask_${agent}`, callArgs(agent, { title: `Write greeting-${agent}.txt`, content: '1. The manager\'s first name is Dana.', session: sid }), meta)));
  const after = registry()[sid]?.agentSessionId;
  record(`${Name}: appended context continues the same session`, field(r.text, 'session') === sid && Boolean(before) && before === after, `session ${field(r.text, 'session')} vs ${sid}; agent session ${before} -> ${after}\n${r.text}`, s);
  record(`${Name}: with the context, the task is done`, /Dana/.test(read(greet) || ''), `${read(greet) || '(no file)'}\n${r.text}`);
  b.stop();
}

async function trackingTests() {
  out('\nSession tracking');
  const b = startBridge('claude');
  await b.req('initialize', {});
  const r = await b.call('list_sessions', { folder: PROJ });
  b.stop();
  record('list_sessions shows the sessions with their titles', /"Create hello-claude.txt"/.test(r.text) && /"Create hello-codex.txt"/.test(r.text), r.text);
  const regDir = path.join(PROJ, '.session');
  const hist = lines(path.join(regDir, 'history.jsonl'));
  record(`.session/history.jsonl has a line per delegation (${hist.length})`, hist.length >= 6);
  const jobs = (() => { try { return fs.readdirSync(path.join(regDir, 'jobs')); } catch { return []; } })();
  record(`.session/jobs/ has each delegation's full record (${jobs.length})`, jobs.length >= 6);
  const blob = [read(path.join(regDir, 'sessions.json')), hist.join('\n'), ...jobs.map((f) => read(path.join(regDir, 'jobs', f)))].join('\n');
  record('the records contain no API keys or tokens', !/\bsk-(ant-|proj-)?[A-Za-z0-9_-]{16,}|ANTHROPIC_API_KEY=|OPENAI_API_KEY=/.test(blob));
  if (fs.existsSync(path.join(PROJ, '.git'))) {
    const gi = read(path.join(PROJ, '.gitignore')) || '';
    record('.session/ is in the folder\'s .gitignore, once', gi.split('\n').filter((l) => l.trim() === '.session/').length === 1, gi);
  }
}

async function folderTests() {
  out('\nFolder');
  let b = startBridge('claude');
  await b.req('initialize', {});
  let [r, s] = await timed(async () => finish(b, await b.call('ask_codex', { title: 'Reply only', content: 'Reply with "Answer: ok". Do not create, change or delete any files.' })));
  const tmp = fs.realpathSync('/tmp');
  record('with no folder set, the sub-agent works in /tmp and its records go to /tmp/.session', field(r.text, 'folder') === tmp && field(r.text, 'records') === path.join(tmp, '.session'), r.text, s);
  b.stop();
  b = startBridge('codex');
  await b.req('initialize', {});
  r = await b.call('ask_claude', { title: 'x', content: 'Do nothing.', folder: path.dirname(RUN_DIR) }, codexMeta());
  record('a folder outside the calling Codex session\'s folder is refused', r.isError && /outside the calling agent's working folder/.test(r.text), r.text);
  // A Codex chat with no folder of its own (ChatGPT project chats run in ~/.codex/.chatgpt-projects/...)
  const noFolder = { 'codex/sandbox-state': { ...codexMeta()['codex/sandbox-state'], sandboxCwd: pathToFileURL(path.dirname(CODEX_CONFIG)).href } };
  [r, s] = await timed(async () => finish(b, await b.call('ask_claude', { title: 'Reply only (no folder)', content: 'Reply with "Answer: ok". Do not create, change or delete any files.' }, noFolder)));
  record('a Codex chat with no folder of its own (like a ChatGPT project chat) works in /tmp', field(r.text, 'folder') === tmp && /no folder of its own/.test(field(r.text, 'note')), r.text, s);
  b.stop();
}

async function modelTests() {
  out('\nModels');
  for (const [caller, Name] of [['claude', 'Codex'], ['codex', 'Claude']]) {
    const b = startBridge(caller);
    await b.req('initialize', {});
    const tools = (await b.req('tools/list')).result.tools.map((t) => t.name);
    record(`${Name}: list_models and set_models are there`, tools.includes('list_models') && tools.includes('set_models'), tools.join(', '));
    const r = await b.call('list_models', {});
    record(`${Name}: list_models shows the models and the current default`, !r.isError && /In use now/.test(r.text), r.text);
    b.stop();
  }
}

// Pressing stop in the calling app: the app sends notifications/cancelled, and the bridge stops the sub-agent.
async function stopTest(agent) {
  const Name = agent === 'claude' ? 'Claude' : 'Codex';
  const caller = agent === 'claude' ? 'codex' : 'claude';
  const b = startBridge(caller);
  await b.req('initialize', {});
  const title = `stop test ${agent}`;
  const n = b.startCall(`ask_${agent}`, callArgs(agent, { title, content: 'Run the shell command `sleep 300` and wait for it to finish, then reply. Do not change any files.' }), caller === 'codex' ? codexMeta() : undefined);
  const findJob = () => { try { const dir = path.join(PROJ, '.session', 'jobs'); return fs.readdirSync(dir).map((f) => { try { return JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); } catch { return null; } }).filter((j) => j && j.title === title && j.folder === fs.realpathSync(PROJ)).sort((a, x) => (a.startedAt < x.startedAt ? 1 : -1))[0] || null; } catch { return null; } };
  let job = null;
  for (let i = 0; i < 40 && !(job && job.pid); i++) { await sleep(500); job = findJob(); }
  await sleep(8000);
  const wasAlive = pidAlive(job?.pid);
  b.cancel(n, 'User requested cancellation');
  await sleep(6000);
  const after = findJob();
  record(`${Name}: stopping the calling agent stops the sub-agent`, wasAlive && !pidAlive(job?.pid) && after?.status === 'cancelled',
    `sub-agent was running: ${wasAlive}, still alive after stop: ${pidAlive(job?.pid)}, job status: ${after?.status}`);
  b.stop();
}

async function agentTests(cfg) {
  out('\nAgent-driven (the real agents call the bridge themselves, with your installed settings)');
  // A1: a real Codex session calls ask_claude through its own MCP config.
  const logBefore = lines(path.join(LOG_DIR, 'bridge.log')).length;
  const promptA = [
    'Call the ask_claude tool from the claude_bridge MCP server exactly once with these arguments:',
    'title: Create from-codex-agent.txt',
    'content: Create a file named from-codex-agent.txt in the working folder containing exactly: ok',
    'If the result says Claude is still working, call check_job with its job_id until you have the Answer.',
    'Do not create or edit any files yourself. Then reply with the Answer from the result.',
  ].join('\n');
  let [res, s] = await timed(() => runCmd(cfg.codexPath, ['exec', '--skip-git-repo-check', '-s', 'workspace-write', '-C', PROJ, '-'],
    { cwd: PROJ, env: process.env, input: promptA, timeoutMs: 15 * 60000 }));
  const f1 = (read(path.join(PROJ, 'from-codex-agent.txt')) || '').trim();
  const viaA = Object.values(registry()).some((e) => e.agent === 'claude' && e.title === 'Create from-codex-agent.txt' && e.agentSessionId);
  record('Codex agent -> ask_claude -> Claude created the file', f1 === 'ok' && viaA,
    `${viaA ? '' : 'No "Create from-codex-agent.txt" session in the bridge, so Codex did not go through ask_claude.\n'}exit ${res.code}\n${res.stdout.slice(-1500)}\n${res.stderr.slice(-800)}`, s);
  const newLog = lines(path.join(LOG_DIR, 'bridge.log')).slice(logBefore).map((l) => { try { return JSON.parse(l); } catch { return {}; } });
  const metaEv = newLog.find((e) => e.event === 'sandbox_meta');
  if (metaEv) {
    record(`Codex shared its session permissions with the bridge (${metaEv.parsed?.mode || 'nothing'} -> ${metaEv.parsed?.level || '?'})`, Boolean(metaEv.received && metaEv.parsed?.level), JSON.stringify(metaEv).slice(0, 600));
    record(`Codex shared its working folder with the bridge (${metaEv.parsed?.cwd ? 'yes' : 'no'})`, Boolean(metaEv.parsed?.cwd));
  } else {
    record('Codex shared its session permissions with the bridge', false, 'no sandbox_meta event in logs/bridge.log (the tool may not have been called)');
  }

  // A2: a real Claude Code session calls ask_codex through an MCP config.
  const mcpConfig = JSON.stringify({ mcpServers: { codex_bridge: { command: process.execPath, args: [SERVER, '--caller', 'claude', '--max-wait', '600'] } } });
  const promptB = [
    'Call the ask_codex tool from the codex_bridge MCP server exactly once with these arguments:',
    'title: Create from-claude-agent.txt',
    'content: Create a file named from-claude-agent.txt in the working folder containing exactly: ok',
    `folder: ${PROJ}`,
    'If the result says Codex is still working, call check_job with its job_id until you have the Answer.',
    'Do not create or edit any files yourself. Then reply with the Answer from the result.',
  ].join('\n');
  const env = { ...process.env };
  delete env.ANTHROPIC_API_KEY;
  delete env.ANTHROPIC_AUTH_TOKEN;
  [res, s] = await timed(() => runCmd(cfg.claudePath, ['-p', '--mcp-config', mcpConfig, '--strict-mcp-config', '--permission-mode', 'dontAsk',
    '--allowedTools', 'mcp__codex_bridge__ask_codex', 'mcp__codex_bridge__check_job', '--model', 'haiku'],
  { cwd: PROJ, env, input: promptB, timeoutMs: 15 * 60000 }));
  const f2 = (read(path.join(PROJ, 'from-claude-agent.txt')) || '').trim();
  const viaB = Object.values(registry()).some((e) => e.agent === 'codex' && e.title === 'Create from-claude-agent.txt' && e.agentSessionId);
  record('Claude agent -> ask_codex -> Codex created the file', f2 === 'ok' && viaB,
    `${viaB ? '' : 'No "Create from-claude-agent.txt" session in the bridge, so Claude did not go through ask_codex.\n'}exit ${res.code}\n${res.stdout.slice(-1500)}\n${res.stderr.slice(-800)}`, s);
}

function writeReport(cfg) {
  const passed = results.filter((r) => r.ok).length;
  const md = [
    '# claude-codex-bridge self-test',
    '',
    `- Date: ${new Date().toISOString()}`,
    `- Result: **${passed} of ${results.length} passed**`,
    `- claude: ${version(cfg.claudePath) || 'unknown'}`,
    `- codex: ${version(cfg.codexPath) || 'unknown'}`,
    `- Node: ${process.versions.node}`,
    `- Test folder: \`${PROJ}\``,
    '',
    '| | Check | Time |',
    '| --- | --- | --- |',
    ...results.map((r) => `| ${r.ok ? 'PASS' : 'FAIL'} | ${r.name.replace(/\|/g, '\\|')} | ${r.secs !== null ? `${r.secs}s` : ''} |`),
    '',
    ...(notes.length ? ['## Notes', '', ...notes.map((n) => `- ${redact(n)}`), ''] : []),
    ...(results.some((r) => !r.ok) ? ['## Failure details', '', ...results.filter((r) => !r.ok).flatMap((r) => [`### ${r.name}`, '', '```', r.detail.slice(0, 3000), '```', ''])] : []),
  ].join('\n');
  fs.writeFileSync(REPORT, md);
  return passed === results.length;
}

// -------------------------------------------------------------------- main ---

const cfg = (() => { try { return JSON.parse(fs.readFileSync(CONFIG, 'utf8')); } catch { return null; } })();
if (!cfg) { out(`No ${CONFIG}. Run \`node install.mjs\` first.`); process.exit(1); }
out('claude-codex-bridge self-test (uses the real CLIs; takes a few minutes)');
const okSetup = await preflight(cfg);
if (okSetup) {
  makeProject(cfg);
  await directTests('claude');
  await directTests('codex');
  await trackingTests();
  await folderTests();
  await modelTests();
  out('\nStopping (like pressing stop in the calling app)');
  await stopTest('claude');
  await stopTest('codex');
  if (!args.has('--direct')) await agentTests(cfg);
}
if (okSetup) {
  out('\nBridge folder');
  const after = bridgeFolderState();
  const changed = after.split('\n').filter((l) => l && !BRIDGE_BEFORE.split('\n').includes(l));
  record('nothing was written to the bridge folder during the test', changed.length === 0, changed.join('\n'));
}
const allOk = writeReport(cfg);
if (args.has('--clean') && allOk) fs.rmSync(RUN_DIR, { recursive: true, force: true });
out(`\n${results.filter((r) => r.ok).length} of ${results.length} passed. Report: ${REPORT}`);
process.exit(allOk ? 0 : 1);
