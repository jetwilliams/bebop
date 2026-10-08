# Memory: the context pod

Agents forget everything between sessions, and a model swap starts from zero. The context pod fixes both: it is a
folder of plain markdown files that holds what the agents need to know, written so that any model (or a person) can
read it cold.

Background on the idea: [jetworks.io/posts/context-pods](https://jetworks.io/posts/context-pods/).

## What goes in the pod

| File | Holds | Who writes it |
|---|---|---|
| `AGENTS.md` | The handover file: what the studio is, the map, the rules, how to start. See [model-swap.md](model-swap.md). | You + the manager |
| `MANAGER.md` | The manager's role. | You |
| `projects/<name>/PROJECT.md` | Each project agent's role. | You |
| `projects/<name>/NOTES.md` | Running notes per project: status, decisions, what was tried, handback notes. | The project agent |
| `memory/MEMORY.md` | The index: one line per memory, with a link. | The manager |
| `memory/*.md` | One fact per file: your preferences, feedback rules, project facts, references. | The manager |
| `OWNER_TODO.md` | Things only you can do (enter a key, create an account, approve something). | The manager |

Claude Code also has its own built-in memory folder (`~/.claude/projects/<folder>/memory/`), loaded automatically for
sessions started in that folder. You can keep the index and memories there instead of in `memory/`. The pattern is
the same. Keeping them inside the pod has one advantage: every model can find them, and the backup picks them up with
the rest.

## The index: MEMORY.md

The index is loaded at the start of every session, so it must stay short. One line per memory:

```markdown
- [Reply style](reply-style.md) — short replies on the phone; one question at a time
- [Check before reporting](check-before-reporting.md) — open the output yourself before saying it works
```

Rules:

- One line each, under about 150 characters.
- The description says enough to know whether to open the file.
- No content in the index itself. The index points; the files hold.
- Remove lines when you delete a memory.

Template: [templates/memory/MEMORY.md](../templates/memory/MEMORY.md).

## A memory file

One fact (or one tightly related set of facts) per file, with frontmatter:

```markdown
---
name: Check before reporting
description: open the output yourself before saying it works
type: feedback
---

Before telling the owner a task is done, open the result and check it: view the image, play the audio, run the
tests, load the page.

**Why:** twice an agent reported "done" on a render that was blank. The owner lost time and trust.

**How to apply:** every report to the owner. If you could not check it, say so plainly.
```

### Types

| Type | For | Example |
|---|---|---|
| `user` | Who you are, how you like to work | "Reads replies on a phone: short messages, no tables" |
| `feedback` | A rule that came from a correction | "Never re-render an approved file; new rules apply to new work only" |
| `project` | A fact about a project | "Project A's test server is the one to experiment on; the live one is off limits" |
| `reference` | Where something lives | "Release checklist is in projects/app/RELEASE.md" |

Examples: [templates/memory/](../templates/memory/).

## How to write good memories

1. **One fact per file.** Small files are easy to update, replace and delete. A file called `misc.md` is a smell.
2. **Write the why.** A rule without a reason gets applied too widely or dropped. "Because the last batch was blank"
   tells the agent where the rule ends.
3. **Write how to apply it.** When does this matter? What should the agent actually do differently?
4. **Use absolute dates.** "Last week" means nothing in a month. Write `2026-10-08`.
5. **Prefer the latest word.** When you change your mind, update or delete the old memory. Don't leave two that
   contradict each other. If you must keep history, mark the old one `SUPERSEDED by <file>`.
6. **Facts, not transcripts.** Save the conclusion, not the conversation that led to it.
7. **Don't save what the code already says.** File structures, function names and settings change; the files are the
   source of truth. Save the things that aren't written anywhere else: preferences, decisions, reasons.
8. **No secrets. Ever.** No keys, tokens, passwords, or personal data you wouldn't want in a backup. A memory can say
   "the API key is in `projects/app/.env`"; it never holds the key.
9. **Keep likes as options.** If you say you loved something once, that is a memory of a good option, not a new
   default. Write it that way, or the agent will repeat it until you hate it.
10. **Review now and then.** Once a month, read the index. Delete what is stale, merge what overlaps.

## When the manager should save a memory

- You correct it ("no, not like that") → a `feedback` memory.
- You state a preference or a standing rule → a `user` or `feedback` memory.
- A decision is made that future sessions need → a `project` memory.
- You tell it where something lives → a `reference` memory.

Put this in the manager's role file (the template already does), so it happens without being asked.

## Why plain markdown

- **Model-agnostic.** Every model can read a text file. Nothing is locked into one vendor's memory feature.
- **Inspectable.** You can read, edit and delete what the agents "know" with any editor, from your phone over SSH if
  needed.
- **Versionable and backed up** like any other file.
- **Cheap.** Only the index loads every time; the rest is opened when relevant.
