# claude-codex-bridge self-test

- Date: 2026-10-21T03:59:10.245Z
- Result: **34 of 34 passed**
- claude: 2.1.304 (Claude Code)
- codex: codex-cli 0.163.0
- Node: 26.12.0
- Test folder: `/Users/swimmingpolar/.mcp/claude-codex-mcp/.selftest/run-2026-10-21T03-57-08-096Z/project`

| | Check | Time |
| --- | --- | --- |
| PASS | Node 26.12.0 (needs 18+) |  |
| PASS | claude found: /Users/swimmingpolar/.local/bin/claude (2.1.304 (Claude Code)) |  |
| PASS | codex found: /Users/swimmingpolar/.local/bin/codex (codex-cli 0.163.0) |  |
| PASS | Codex config has [mcp_servers.claude_bridge] pointing at this bridge |  |
| PASS | Codex runs the bridge tools without prompting (default_tools_approval_mode = "approve") |  |
| PASS | Claude Desktop config has codex_bridge pointing at this bridge |  |
| PASS | Codex skill consult-claude installed (manual only) |  |
| PASS | `codex mcp list` shows claude_bridge enabled |  |
| PASS | Claude: a fully specified task comes back as an Answer and is done | 8s |
| PASS | Claude: permissions come from the calling Codex session (this Codex session (profile:managed/restricted)) |  |
| PASS | Claude: missing information comes back as "More context needed:" instead of a guess | 4s |
| PASS | Claude: appended context continues the same session | 6s |
| PASS | Claude: with the context, the task is done |  |
| PASS | Codex: a fully specified task comes back as an Answer and is done | 15s |
| PASS | Codex: permissions come from Codex's own settings (Codex's own settings (~/.codex/config.toml, as in the Codex app)) |  |
| PASS | Codex: missing information comes back as "More context needed:" instead of a guess | 6s |
| PASS | Codex: appended context continues the same session | 11s |
| PASS | Codex: with the context, the task is done |  |
| PASS | list_sessions shows the sessions with their titles |  |
| PASS | history.jsonl has a line per delegation (6) |  |
| PASS | tracking files contain no API keys or tokens |  |
| PASS | .claude-codex/ is excluded from git |  |
| PASS | Claude Desktop side without a folder: told to pass one (or ask the user) |  |
| PASS | a folder outside the calling Codex session's folder is refused |  |
| PASS | Codex: list_models and set_models are there |  |
| PASS | Codex: list_models shows the models and the current default |  |
| PASS | Claude: list_models and set_models are there |  |
| PASS | Claude: list_models shows the models and the current default |  |
| PASS | Claude: stopping the calling agent stops the sub-agent |  |
| PASS | Codex: stopping the calling agent stops the sub-agent |  |
| PASS | Codex agent -> ask_claude -> Claude created the file | 21s |
| PASS | Codex shared its session permissions with the bridge (profile:managed/restricted -> auto) |  |
| PASS | Codex shared its working folder with the bridge (yes) |  |
| PASS | Claude agent -> ask_codex -> Codex created the file | 20s |

## Notes

- Codex as a sub-agent uses Codex's own settings. Top-level sandbox_mode in /Users/swimmingpolar/.codex/config.toml: "workspace-write".
