# Model swap: handing over to another model

Usage caps, outages and price changes happen. When the main model is unavailable, another one (for example the Codex
CLI) should be able to keep the studio running. Because the memory is plain markdown, it can.

## The handover file

`AGENTS.md` at the top of the studio folder is written for an agent that knows nothing. Codex reads `AGENTS.md`
automatically; other tools can be told to read it first.

It answers, in order:

1. **What is this studio?** One paragraph. The owner's priorities, in order.
2. **The map.** Where each project lives, which services run on which ports, how to check health.
3. **How work is organised.** The tmux session, which windows belong to whom, which ones never to touch.
4. **Daily operations.** The recurring jobs and the commands that run them.
5. **Hard rules.** Secrets, money, public posting, live systems, content rules.
6. **Taste.** Which files describe your preferences, to read before any creative work.
7. **The first ten minutes.** A checklist: read this, check health, check status, ask the owner what to work on.

Template: [templates/HANDOVER.md](../templates/HANDOVER.md).

Rules for the file itself:

- **Your word beats the file**, and newer project notes beat older handover text. Say so at the top.
- **No secrets.** Point to where keys live; never include them.
- **Commands, not descriptions.** "Run `bash ops/studio-up.sh`" beats "start the services".
- **Date it**, and update it when the setup changes. A stale handover is worse than none, because it is trusted.

## How to swap

1. **Stop or pause the main manager** if it is still running, so two agents don't edit the same files.
   The watchdog will restart it, so pause the watchdog too:
   - macOS: `launchctl bootout gui/$(id -u)/<your watchdog label>`
   - Linux: `systemctl --user stop bebop-watchdog.timer`
2. **Open a terminal** in the studio folder (at the host or over SSH) and start the backup model, for example:
   ```sh
   cd ~/studio && codex
   ```
3. **Its first message from you:** "Read AGENTS.md and do the first-ten-minutes checklist." It reads the handover, the
   memory index and the to-do list, checks health and reports.
4. **Work one project at a time**, as the handover file says.
5. **When the main model is back**, ask the backup to write a handback note in each project it touched (what it did,
   what's unfinished), then stop it, re-enable the watchdog, and tell the main manager to read those notes.

## What the backup model may not have

- **The chat channel.** The Telegram plugin here is a Claude Code plugin. Another model may not have an equivalent, so
  during a swap you talk to it at the terminal (SSH from your phone works).
- **Do not start a second bot poller** on the same token as a workaround. Two pollers knock each other off.
- **The same tools.** MCP servers, skills and subagents differ between tools. The handover should describe tasks in
  terms of shell commands and files wherever possible, so any model can do them.
- **Built-in memory.** Anything kept only in one tool's private memory store is invisible to another. That is the main
  reason to keep the memory index and memories inside the pod.

## Keeping the pod portable

- Plain markdown, plain shell scripts, plain JSON. No tool-specific formats for anything the next model needs.
- Role files say *what* to do and *why*, not which tool feature to use.
- Tool-specific setup (Claude Code's `CLAUDE.md`, Codex's config) is a thin pointer to the shared files:
  "Read MANAGER.md and AGENTS.md first."
- Test the swap once while nothing is on fire: run the backup model through the first-ten-minutes checklist and see
  what it gets wrong. Fix the handover file, not the model.
