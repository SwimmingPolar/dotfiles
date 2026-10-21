# claude-codex-bridge

A small local MCP server that lets **Codex** and **Claude Desktop** delegate tasks to each other. The calling agent sends a **Title** and a **Content**; the other agent, running as a sub-agent on its own sign-in, replies with an **Answer**. No API keys are needed.

| You start in | Skill | Tool it uses | Sub-agent | Billed to |
| --- | --- | --- | --- | --- |
| Codex (ChatGPT app, CLI, IDE) | `$work-with-claude` (Work with Claude) | `ask_claude` | `claude -p` (Claude Code) | your Claude plan |
| Claude Desktop | `work-with-codex` (Work with Codex) | `ask_codex` | `codex exec` | your ChatGPT plan |

## Install and test

From this folder, in your terminal:

```bash
node install.mjs --dry-run   # shows exactly what it will change, changes nothing
node install.mjs             # backs up and edits both apps' configs, installs the Codex skill
node selftest.mjs            # runs both directions with the real CLIs, writes selftest-report.md
```

Then fully quit and reopen Claude Desktop and the Codex/ChatGPT app, and save the `work-with-codex` skill in Claude Desktop (its source is in `skills/work-with-codex/`).

The self-test works in a throwaway folder in your temp folder and runs its direct checks on light models through a copy of your config, so your defaults aren't spent and nothing is left in the bridge folder except `selftest-report.md`. It checks a complete task, a request for more context, appending that context to the same session, the folder rule, stopping, and a real Codex and a real Claude calling the bridge themselves. `--direct` skips the last part; `--clean` deletes the test folder when everything passes. `node install.mjs --uninstall` reverses the install.

## The exchange

```
calling agent  --  Title + Content  -->  sub-agent
calling agent  <--      Answer      --   sub-agent
calling agent: done
```

- **Title** is a one-line summary of the task.
- **Content** is everything the sub-agent needs, because it sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like.
- **Answer** is the sub-agent's final reply. The result the calling agent reads looks like this:

```
Title: Write the client welcome email
Answer:
Created welcome-email.md for Northwind Traders, signed by Dana Kim, with the kickoff on Tuesday 3 November 2026, 10:00 KST.

session: claude-e810334e
folder: /Users/you/Projects/onboarding
permissions: this Codex session (profile:managed/restricted)
records: /Users/you/Projects/onboarding/.session
```

**More context.** If the Content isn't enough to do the task without guessing at something that matters, the sub-agent doesn't guess. Its Answer starts with `More context needed:` and lists exactly what's missing. The calling agent judges whether each item is necessary and legitimate to share (never secrets or anything outside the task) and supplies what is, in one of two ways:

- **Append** to the same session: call again with `session` from the result and `content` set to just the added context. The sub-agent continues its own conversation.
- **Start a new session:** call again without `session`, with the full task plus the added context in `content`.

There are no caps on any of this. The calling agent decides when it has what it needs.

## Who decides what

| Decision | Who |
| --- | --- |
| What to delegate, and how to split the work | The calling agent |
| Resolving ambiguity before delegating | The calling agent; it asks you only when only you can answer, as its app's settings allow |
| Whether to make the call | The calling agent. Codex runs the bridge's tools without prompting (`default_tools_approval_mode = "approve"`, set by the installer). In Claude Desktop, choose "Always allow" the first time Claude uses the tool. |
| Whether a context request is legitimate, and append vs new session | The calling agent |
| What the sub-agent may do | The calling agent's permissions; failing that, the sub-agent's own app settings (below) |

## Permissions

The sub-agent gets the calling agent's permissions. It never asks you anything: `codex exec` never prompts for approval (if you've set Codex's auto-reviewer, the reviewer decides), and `claude -p` refuses anything that would need a prompt. Refused actions are listed in the result under `refused by permissions`.

| Calling side | The sub-agent runs with |
| --- | --- |
| Codex | **This Codex session's permissions**, which Codex shares with the bridge on every call. Read-only → Claude can read and search only. Workspace-write → Claude's auto mode: edits in the folder, commands, risky actions checked automatically. Full access → no checks. Network off → no web tools. If Codex shares nothing, Claude uses its own settings (`~/.claude/settings.json`). |
| Claude Desktop | **Codex's own settings**, from `~/.codex/config.toml`, the file the Codex app uses. Claude Desktop doesn't share its permission settings with MCP servers, so the bridge adds no overrides. If you want Codex to edit files when Claude delegates, set `sandbox_mode = "workspace-write"` at the top of that file. |

**Folder.** The sub-agent works where the calling agent works. From Codex, that's the session's working folder (or a folder inside it you pass as `folder`). From Claude Desktop, the calling agent passes the folder. When a chat has no folder of its own, the sub-agent works in the system temp folder, `/tmp`. That includes a ChatGPT project chat in Codex, which Codex runs in its internal folder (`~/.codex/.chatgpt-projects/...`), and a chat whose folder is the root or your whole home folder. The result's `note:` line says when this happened. A folder the calling agent names explicitly is used as given. A folder outside the calling agent's own is refused. Claude as a sub-agent also can't read outside the folder (`claude.blockOutsideReads`).

**One level only.** A sub-agent can't delegate further: its own bridge refuses, and the bridge is turned off inside a Codex sub-agent.

## Sessions and records

Each delegation gets a session id such as `claude-1a2b3c4d`, returned in the result. Everything about a folder's delegations is kept in that folder, in `.session/`:

- `sessions.json`: each session's id, title, and the agent's own session id.
- `history.jsonl`: one line per delegation, with its title and result (answer, more context, error or cancelled).
- `jobs/`: each delegation's full record (title, content, Answer, timing).

Secrets are redacted. When the folder is in git, the bridge adds `.session/` to that folder's `.gitignore`. Before each delegation the bridge checks it can create and write `.session/`. If it can't, for example in a read-only folder or one macOS privacy settings block, the delegation still runs and the records go to `~/Library/Caches/claude-codex-bridge/folders/`. The result's `records:` line always says where they went.

**Nothing is written to the bridge's own folder** while it runs. The only exception is `set_models`, which updates `bridge.config.json` when you ask it to. A small index of running delegations (so any app can check or cancel them), stop markers and a diagnostic `bridge.log` live in `~/Library/Caches/claude-codex-bridge`; `node server.mjs --paths` prints these locations. If the calling agent loses a session id, for example after its context is compacted, `list_sessions` shows them by title. You can also open a sub-agent's conversation yourself: `list_sessions` prints the `claude --resume …` or `codex resume …` command.

## Stopping a delegation

| What you do | What happens to the sub-agent |
| --- | --- |
| Ask the calling agent to cancel it (`cancel_job`) | Stopped, along with everything it started. Works for delegations from other chats or apps too. |
| Run `node server.mjs --cancel all` (or `--cancel <job_id>`) | Stopped. `--jobs` lists what's running. |
| Press stop in the calling app | Stopped, if the app tells the bridge (`notifications/cancelled`). Codex currently doesn't send this ([openai/codex#26956](https://github.com/openai/codex/issues/26956)), so after stopping Codex, the Claude sub-agent finishes its run; use `cancel_job` or `--cancel` to stop it. |
| Quit or force quit the calling app | Stopped. |
| The bridge itself is killed | Stopped within about 2 seconds, by a small watchdog. |

Files the sub-agent already changed stay changed; `view_changes` shows them.

## Models

The sub-agent's model and effort come from `claude.model` / `claude.effort` and `codex.model` / `codex.effort` in `bridge.config.json`. When those are `null`, each CLI uses its own default. Ask the calling agent to list or change them (`list_models`, `set_models`), or use the terminal:

```bash
node server.mjs --models                       # both sides: models, effort levels, current settings
node server.mjs --models claude --set-model opus --set-effort xhigh
node server.mjs --models codex --reset         # back to Codex's own default
```

The Codex list is read live from `codex debug models`. For Claude, `opus`, `sonnet`, `haiku` and `fable` always mean the newest of that family; full names such as `claude-opus-5-5` pin a version. The calling agent's own model is whatever you pick in its app.

## Tools

| Tool | What it does |
| --- | --- |
| `ask_claude` / `ask_codex` | The exchange: `title`, `content`, and optionally `session` (to append) and `folder`. |
| `check_job` | The Answer of a delegation that was still running when the call returned. |
| `cancel_job` | Stops a running delegation. |
| `list_sessions` | Delegations in a folder, by title, with their session ids. |
| `view_changes` | Git status and diff of a folder. |
| `list_models` / `set_models` | The sub-agent's model and effort. |

## Settings (`bridge.config.json`)

| Key | What it does |
| --- | --- |
| `claudePath`, `codexPath`, `childPath` | Full paths found by the installer. Re-run it if you move or reinstall a CLI. |
| `claude.model`, `claude.effort`, `codex.model`, `codex.effort` | The sub-agent's model and effort (`null` = the CLI's own default). |
| `claude.blockOutsideReads` | `true` (default): Claude as a sub-agent can't read outside the task's folder. |
| `cancelOnStop` | `true` (default): stopping the calling agent stops the sub-agent, when the app reports it. |
| `useApiKeys` | `false` (default): the sub-agent's API-key variables are removed, so it runs on your subscription. |

The bridge reads this file when it starts, except `set_models`, which applies at once. After editing it by hand, restart the app on that side.

## Terminal

```bash
node server.mjs --try claude --folder DIR --title "Summary" "Content"      # one delegation, as from Codex
node server.mjs --try claude --folder DIR --title "Summary" --session ID "More context"
node server.mjs --try claude --level auto ...                              # pretend the Codex session is workspace-write
node server.mjs --sessions [--folder DIR]
```

## Troubleshooting

- **The tool doesn't show up.** Fully quit and reopen the app. In Codex, `/mcp` lists the servers. Claude Desktop shows MCP errors under Settings → Developer.
- **"not found at …".** A CLI moved, for example after an update. Run `node install.mjs` again.
- **Claude asks you to log in or bills the API.** Run `env -u ANTHROPIC_API_KEY claude` once and sign in with your claude.ai account.
- **Codex can't edit files when Claude delegates.** Codex is using its own settings; set `sandbox_mode = "workspace-write"` in `~/.codex/config.toml`.
- **Claude's auto mode isn't available.** It needs Claude Code 2.1.281 or later (`claude update`). Without it, actions that would need approval are refused and listed in the result.
- **Look at `selftest-report.md`** for which check failed and why.
