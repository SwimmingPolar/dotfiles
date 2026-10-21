---
name: work-with-claude
description: "Delegate one well-defined task to Claude through the claude_bridge tools: send a Title and a Content, get back an Answer. Use when the user wants Claude involved ($work-with-claude)."
---

# Work with Claude

Delegation is one exchange: you send Claude a **Title** and a **Content** with `ask_claude`, Claude replies with an **Answer**, and the delegation is done.

**Title** is a one-line summary of the task.

**Content** is everything Claude needs, because Claude sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like. Claude works in this session's working folder; to narrow it, put a folder inside it in `folder`. If this session has no folder of its own (for example a ChatGPT project chat, which Codex runs in its internal folder), Claude works in /tmp, unless you name a folder the user gave you in `folder`.

The bridge keeps its records for each folder in `.session/` inside that folder, and adds `.session/` to the folder's `.gitignore` when the folder is in git. Leave `.session/` out of the task.

You decide what to delegate, and you delegate only what you can state without ambiguity. Resolve ambiguity before you send: decide it yourself when you can, and ask the user, as this session's settings allow, when only they can.

**Answer** is Claude's reply. If it begins with `More context needed:`, Claude could not do the task without guessing, and it lists what is missing. Judge whether each item is necessary for this task and legitimate to share. Supply what is, either appended to the same session (`session` from the result, `content` set to only the added context) or in a new session (no `session`, `content` set to the full task plus the added context). Any other Answer is the result.

Claude gets this session's permissions (read-only, workspace-write or full access) and never asks the user anything.
