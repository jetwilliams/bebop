# Delegation: manager and project agents

## The split

| | Manager | Project agent |
|---|---|---|
| Talks to you | Yes, on Telegram | No (only through the manager, or when you attach to its window) |
| Does project work | No | Yes, in its own folder |
| Context | The whole studio, at a shallow depth | One project, in depth |
| Role file | `MANAGER.md` | `projects/<name>/PROJECT.md` |
| Writes | Memory, `OWNER_TODO.md`, status notes | Code, assets, its project's `NOTES.md` |
| Lifetime | Always on (the watchdog restarts it) | Started when needed, resumed later |

### Why split them

- **The manager stays responsive.** If it starts a 40-minute render itself, nobody answers your messages for 40
  minutes. Long jobs go to a project agent; the manager stays free to talk.
- **Context stays focused.** A project agent that only knows one project makes fewer cross-project mistakes, and its
  context window isn't full of unrelated chat.
- **Mistakes stay contained.** A project agent works in one folder. If it breaks something, it breaks one project.
- **A second pair of eyes.** The manager checks the project agent's work. One agent rarely catches its own mistakes.

## How the manager delegates

### Option 1: an agent in a tmux window (long-lived)

Use this for ongoing projects. Each project has a window (see `STUDIO_WINDOWS`) with an agent session you resume.
The manager sends it a brief. How depends on your tools:

- If your agent tool has a built-in way to message another session, use that.
- Otherwise, write the brief to a file and send a one-line pointer:
  ```sh
  tmux send-keys -t studio:project-a "Read briefs/2026-10-08-landing-page.md and do it. Report back in NOTES.md." C-m
  ```
  Long multi-line pastes through `send-keys` often fail to submit. Short pointer lines are reliable.

### Option 2: a subagent (short-lived)

For a one-off task (research, a quick check), the manager can start a subagent inside its own session. The subagent
reports back and ends. Good for work that takes minutes, not hours.

### Option 3: a headless run

Most agent CLIs can run one task non-interactively and exit (for example `claude -p "..."` or `codex exec "..."`).
Good for scheduled jobs. Redirect stdin (`< /dev/null`) so it doesn't hang waiting for input.

## How to write a brief

The project agent has none of the manager's context. A good brief stands on its own:

```markdown
# Brief: <short title>
Date: 2026-10-08   From: manager   To: project-a

## Goal
One or two sentences: what should exist when you're done, and why the owner wants it.

## Context
What the owner said (quote the key words), links to the files involved, decisions already made.

## Constraints
- Work only in projects/project-a/.
- Use the test server, not the live one.
- No paid API calls. No public posting. Stop and report if either seems needed.

## Done means
- The page loads on the test server with no console errors.
- Screenshot saved to projects/project-a/out/landing.png.

## Report back
In NOTES.md, under today's date: what you changed (file list), what you checked and how, anything unsure.
```

Tips:

- **Quote the owner.** Paraphrase loses the details that matter.
- **Say what done looks like** in checkable terms (a file exists, a test passes, a page loads).
- **Name the limits** (folder, test copy, no spending), even if the role file already says so. Repetition is cheap;
  a live outage is not.
- **Ask for evidence** in the report: file paths, screenshots, test output.
- **One task per brief.** Two unrelated asks in one brief means one of them gets half-done.

## Checking work before reporting

The manager never forwards "done" on the project agent's word alone. Before replying to you, it:

1. **Opens the output.** Reads the changed files, views the image or frames, plays or inspects the audio, loads the
   page.
2. **Runs the check** named in "Done means" (tests, a health endpoint, a lint).
3. **Compares against the brief and your rules** (the memories). Wrong format? Off-style? Rule broken? Send it back.
4. **Reports plainly**: what was done, what was checked, what wasn't, and anything that needs your decision.

If it couldn't check something (for example, it can't hear audio), it says so instead of guessing.

## Approvals

When the next step spends money, posts publicly or touches a live system, the manager:

1. Prepares everything (a dry run, a preview, a cost estimate).
2. Sends you the preview on Telegram with exactly what will happen.
3. Waits for **your typed approval at the terminal** (see [security.md](security.md)).

A project agent can't approve on the manager's word, and the manager can't approve on yours if "yours" arrived
through chat. Chat is fine for "yes, go ahead and prepare it". The final, irreversible step is typed by you.

## Status tracking

- Each project's `NOTES.md` holds its own status.
- The manager keeps a short status list (in its own notes or a `STATUS.md`): what's running, what's waiting on you,
  what's blocked.
- `OWNER_TODO.md` lists what only you can do. The manager reminds you; it never does these itself.
