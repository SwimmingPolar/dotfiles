---
name: work-with-codex
description: "Delegate one well-defined task to Codex through the codex_bridge tools: send a Title and a Content, get back an Answer. Use when the user wants Codex involved."
---

# Work with Codex

Delegation is one exchange: you send Codex a **Title** and a **Content** with `ask_codex`, Codex replies with an **Answer**, and the delegation is done.

**Title** is a one-line summary of the task.

**Content** is everything Codex needs, because Codex sees nothing else: the goal, the files and folders involved, the inputs, the constraints, and what the finished result looks like. Put the task's folder in `folder`; Codex works only there. If this chat has no folder, leave `folder` out and Codex works in /tmp.

The bridge keeps its records for each folder in `.session/` inside that folder, and adds `.session/` to the folder's `.gitignore` when the folder is in git. Leave `.session/` out of the task.

You decide what to delegate, and you delegate only what you can state without ambiguity. Resolve ambiguity before you send: decide it yourself when you can, and ask the user, as this app's settings allow, when only they can.

**Answer** is Codex's reply. If it begins with `More context needed:`, Codex could not do the task without guessing, and it lists what is missing. Judge whether each item is necessary for this task and legitimate to share. Supply what is, either appended to the same session (`session` from the result, `content` set to only the added context) or in a new session (no `session`, `content` set to the full task plus the added context). Any other Answer is the result.

Codex runs with the permissions in its own settings, the same ones the Codex app uses, and never asks the user anything.
