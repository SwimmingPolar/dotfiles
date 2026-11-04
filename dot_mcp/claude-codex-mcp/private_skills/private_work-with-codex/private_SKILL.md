---
name: work-with-codex
description: "Delegate one well-defined task to Codex through the codex_bridge tools: send a Title and a Content, get back an Answer. Use when the user wants Codex involved."
---

# Work with Codex

Delegation is one exchange: you send Codex a **Title** and a **Content** with `ask_codex`, Codex replies with an **Answer**, and the delegation is done.

**Title** is a one-line summary of the task.

**Content** is everything Codex needs, because Codex sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like. Put the task's folder in `folder`; Codex works only there. If this chat has no folder, leave `folder` out and Codex works in /tmp.

The bridge keeps its records for each folder in `.skills/claude-codex-mcp/sessions/` inside that folder, and adds that folder to the `.gitignore` when the folder is in git. Leave it out of the task.

You decide what to delegate, and you delegate only what you can state without ambiguity. Resolve ambiguity before you send: decide it yourself when you can, and ask the user, as this app's settings allow, when only they can.

**Getting the Answer.** Never wait for the Answer in the chat. `ask_codex` returns at once with a job id while Codex works. Pick the Answer up in the background with whatever you have: if you can run a shell command in the background and are woken when it exits, as in Claude Code, run the `--wait` command the result gives you that way, and it exits with the Answer the moment Codex finishes; otherwise use a scheduled task or a wake-up that calls `check_job`. Meanwhile, go on with other work, or end your turn when the next step needs the Answer.

**Answer** is Codex's reply. If it begins with `More context needed:`, Codex could not do the task without guessing, and it lists what is missing. Judge whether each item is necessary for this task and legitimate to share. Supply what is, either appended to the same session (`session` from the result, `content` set to only the added context) or in a new session (no `session`, `content` set to the full task plus the added context). Any other Answer is the result.

Codex runs with the permissions in its own settings, the same ones the Codex app uses, and never asks the user anything.
