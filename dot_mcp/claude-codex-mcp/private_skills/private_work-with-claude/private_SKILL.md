---
name: work-with-claude
description: "Delegate one well-defined task to Claude through the claude_bridge tools: send a Title and a Content, get back an Answer. Use when the user wants Claude involved ($work-with-claude)."
---

# Work with Claude

Delegation is one exchange: you send Claude a **Title** and a **Content** with `ask_claude`, Claude replies with an **Answer**, and the delegation is done.

**Title** is a one-line summary of the task.

**Content** is everything Claude needs, because Claude sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like. Claude works in this session's working folder; to narrow it, put a folder inside it in `folder`. If this session has no folder of its own (a ChatGPT project chat, or a chat the Codex app filed under ~/Documents/Codex/<date>/), Claude works in /tmp, unless you name a folder the user gave you in `folder`.

The bridge keeps its records for each folder in `.skills/claude-codex-mcp/sessions/` inside that folder, and adds that folder to the `.gitignore` when the folder is in git. Leave it out of the task.

You decide what to delegate, and you delegate only what you can state without ambiguity. Resolve ambiguity before you send: decide it yourself when you can, and ask the user, as this session's settings allow, when only they can.

**Getting the Answer.** Never wait for the Answer in the chat. `ask_claude` returns at once with a job id while Claude works, and Claude's Answer arrives in this chat by itself, as an `ask_claude` tool result, the moment Claude finishes, whether you are working or your turn has ended. Meanwhile, go on with other work, or end your turn when the next step needs the Answer. If a result asks you to call `check_job` instead, do it from whatever background scheduling you have.

**Answer** is Claude's reply. If it begins with `More context needed:`, Claude could not do the task without guessing, and it lists what is missing. Judge whether each item is necessary for this task and legitimate to share. Supply what is, either appended to the same session (`session` from the result, `content` set to only the added context) or in a new session (no `session`, `content` set to the full task plus the added context). Any other Answer is the result.

Claude gets this session's permissions (read-only, workspace-write or full access) and never asks the user anything.
