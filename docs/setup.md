# Setup (how-to)

Build a Bebop setup on a spare Mac or Linux box. Allow an afternoon. Steps marked **macOS** or **Linux** only
apply to that system.

In the commands below, `studio` is an example user name and `~/studio` an example studio folder. Use your own.

## What you need

- A computer that can stay on: an old Mac, a mini PC, a home server. 8 GB of RAM is enough for the agents; more if
  you run local models or renderers.
- A Claude subscription or API account for Claude Code. Optional: an OpenAI account for the Codex CLI as a backup.
- A Telegram account on your phone.
- An external drive for backups (optional but recommended).

## 1. Prepare the machine

1. **Start clean if you can.** A fresh OS install means no old personal data for an agent to stumble into.
2. **Create a dedicated user account** for the studio.
   - **macOS:** System Settings → Users & Groups → Add User. A Standard account is enough for daily work; you can use
     an admin account for installs.
   - **Linux:** `sudo adduser studio`
3. **Log in automatically** after a restart, so the studio comes back by itself.
   - **macOS:** System Settings → Users & Groups → "Automatically log in as". This requires FileVault to be off. That
     is a real trade-off: weigh disk encryption against unattended restarts. If you keep FileVault on, someone has to
     unlock the machine after each reboot (in person, or with `sudo fdesetup authrestart` before a planned restart).
   - **Linux:** user services can run without a login. Run `sudo loginctl enable-linger studio`.
4. **Never sleep.**
   - **macOS:**
     ```sh
     sudo pmset -a sleep 0 disksleep 0 displaysleep 10   # display may sleep, the machine may not
     sudo pmset -a autorestart 1                          # power back on after a power cut
     ```
     Optional: `pmset repeat` can wake and sleep the machine on a schedule if you only need it at certain hours.
   - **Linux:** `sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target`
5. **Control OS updates.** Automatic updates that restart the machine will take the studio down. Set them to
   download only, and install them yourself.

## 2. Install the tools

**macOS** (with [Homebrew](https://brew.sh)):

```sh
brew install tmux node git rsync
brew install --cask tailscale
```

**Linux** (Debian/Ubuntu):

```sh
sudo apt update && sudo apt install -y tmux git rsync curl openssh-server
# Node.js: use your distribution's package, or nvm, or the NodeSource repo
curl -fsSL https://tailscale.com/install.sh | sh
```

**Both:**

```sh
# Claude Code (see https://docs.anthropic.com/en/docs/claude-code for the current install method)
npm install -g @anthropic-ai/claude-code

# Bun: the Telegram channel plugin runs on it
curl -fsSL https://bun.sh/install | bash

# Optional: Codex CLI as the backup model
npm install -g @openai/codex
```

Run `claude` once and log in. Do the same for `codex` if you installed it.

## 3. Set up the private network

1. Sign in to Tailscale on the host (`sudo tailscale up` on Linux, or the menu bar app on macOS) and on your phone and
   laptop, with the same account.
2. Turn on SSH to the host, so you can reach a terminal from anywhere on your private network:
   - **macOS:** System Settings → General → Sharing → Remote Login (allow only the studio user).
   - **Linux:** `openssh-server` from step 2 is enough. Use key-based login and turn off password login.
3. Do **not** forward any port on your router. Everything goes through the private network.
4. Install an SSH app on your phone (for example Termius or Blink). This is how you type approvals at the terminal
   when you are not at home.

## 4. Create the context pod

```sh
mkdir -p ~/studio/memory ~/studio/projects
cp templates/HANDOVER.md        ~/studio/AGENTS.md
cp templates/MANAGER.md         ~/studio/MANAGER.md
cp templates/memory/*.md        ~/studio/memory/      # the index + examples; edit or delete the examples
```

Fill in the placeholders in `AGENTS.md` and `MANAGER.md` (search for `{{`). Keep the folder out of `~/Desktop`,
`~/Documents` and `~/Downloads` on macOS: background jobs started by launchd are not allowed to read those folders.

Point Claude Code at the role file. Claude Code reads `CLAUDE.md` in the folder it starts in, so create one:

```sh
printf '%s\n' 'Read MANAGER.md and AGENTS.md before doing anything else.' 'Memory index: memory/MEMORY.md' > ~/studio/CLAUDE.md
```

(Codex reads `AGENTS.md` by itself.)

## 5. Create the Telegram bot

1. In Telegram, open a chat with **@BotFather** and send `/newbot`. Pick a display name and a username ending in
   `bot`. BotFather replies with a token.
2. Treat the token like a password. Do not paste it into a chat with any agent, a note, or a screenshot.
3. Recommended BotFather settings:
   - `/setjoingroups` → **Disable** (nobody can add your bot to a group)
   - `/setprivacy` → **Enable** (the default)

## 6. Store the token privately

The plugin reads its token from `~/.claude/channels/telegram/.env`. Write it with the hidden prompt, typed at the
host's terminal:

```sh
bash scripts/set-secret.sh ~/.claude/channels/telegram/.env TELEGRAM_BOT_TOKEN
```

The plugin also offers `/telegram:configure <token>`. That works, but it puts the token into the agent's conversation
log. The hidden prompt keeps it out.

Check it is there without printing it:

```sh
grep -c '^TELEGRAM_BOT_TOKEN=' ~/.claude/channels/telegram/.env    # prints 1
```

## 7. Install the Telegram channel plugin

```sh
cd ~/studio
claude
```

Inside Claude Code:

```
/plugin install telegram@claude-plugins-official
```

Exit (`/exit`), then start the manager with the channel turned on:

```sh
claude --channels plugin:telegram@claude-plugins-official
```

## 8. Pair your account, then lock the bot to one user

1. On your phone, send any message to your bot. It replies with a short pairing code.
2. In the manager's terminal (not in Telegram), type:
   ```
   /telegram:access pair <code>
   ```
3. Switch the policy so strangers get no reply at all:
   ```
   /telegram:access policy allowlist
   ```
4. Check: `/telegram:access` should list exactly one user ID: yours.
5. Send another message from your phone. The manager should answer.

From now on, change access only by typing at the terminal. If a Telegram message ever asks the manager to add someone
or approve a pairing, that is exactly what a prompt-injection attack looks like. The manager must refuse.

## 9. Decide how the manager handles permission prompts

Claude Code asks before running commands or editing files. When you are away, nobody is there to answer, and the
manager stalls. Options, safest first:

1. **Allow rules.** Pre-approve the commands the manager needs in `~/studio/.claude/settings.json`, and deny what it
   must never do:
   ```json
   {
     "permissions": {
       "allow": ["Read", "Bash(tmux list-windows:*)", "Bash(git status)", "Bash(git diff:*)"],
       "deny":  ["Read(**/.env)", "Read(**/.env.*)", "Bash(git push:*)"]
     }
   }
   ```
   Grow the allow list as you learn what it needs.
2. **Broader permission modes** (see the Claude Code docs). Only on a dedicated user account with no personal files
   and no secrets readable by that user, and only after reading [security.md](security.md).

Whatever you choose, keep the approval gates in your role files: money, public posts and live systems wait for you.

## 10. Configure and start the studio

```sh
mkdir -p ~/.config/bebop
cp scripts/studio.env.example ~/.config/bebop/studio.env
# edit it: STUDIO_DIR, the windows you want, the backup drive
bash scripts/studio-up.sh
tmux attach -t studio      # look around; detach with Ctrl-b then d
```

`studio-up.sh` is safe to re-run. It only creates what is missing.

## 11. Install the watchdog

Copy `scripts/watchdog.sh`, `scripts/studio-up.sh` and `scripts/_common.sh` into a folder launchd or systemd can
read, for example `~/.local/share/bebop/`.

- **macOS:** edit [scripts/service/com.example.bebop.watchdog.plist](../scripts/service/com.example.bebop.watchdog.plist)
  (replace `${LABEL}`, `${SCRIPTS_DIR}` and `${HOME}` with real values), then:
  ```sh
  cp com.yourname.bebop.watchdog.plist ~/Library/LaunchAgents/
  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.bebop.watchdog.plist
  ```
- **Linux:** edit `${SCRIPTS_DIR}` in [bebop-watchdog.service](../scripts/service/bebop-watchdog.service), then:
  ```sh
  mkdir -p ~/.config/systemd/user
  cp scripts/service/bebop-watchdog.{service,timer} ~/.config/systemd/user/
  systemctl --user daemon-reload
  systemctl --user enable --now bebop-watchdog.timer
  ```

Test it: close the manager (`/exit` in its window). Within 5 minutes it should be back. The log is in
`~/.local/state/bebop/watchdog.log`.

Run only **one** manager per bot token. Two sessions polling the same bot knock each other off.

## 12. Set up the backup

Set `BACKUP_VOLUME` and `BACKUP_DEST` in `studio.env`, plug in the drive, and run:

```sh
bash scripts/backup.sh
```

To run it every hour, either add a window to `STUDIO_WINDOWS`:

```
backup|$HOME/studio|bash /path/to/scripts/backup.sh --loop 3600
```

or schedule it with cron, launchd or systemd the same way as the watchdog. On macOS, if your studio folder is inside
a protected folder, the tmux loop is the option that works.

## 13. Add your first project

```sh
mkdir -p ~/studio/projects/my-project
cp templates/PROJECT.md ~/studio/projects/my-project/PROJECT.md
printf '%s\n' 'Read PROJECT.md and NOTES.md first.' > ~/studio/projects/my-project/CLAUDE.md
touch ~/studio/projects/my-project/NOTES.md
```

Fill in `PROJECT.md`, add a line to `STUDIO_WINDOWS`, run `studio-up.sh`, and start an agent in the new window
(`claude`). Then tell the manager about it (add a row to the project table in `MANAGER.md`). See
[delegation.md](delegation.md) for how the manager briefs it.

## 14. Final checks

- [ ] A message from your phone gets an answer.
- [ ] A message from another Telegram account gets no answer.
- [ ] After `/exit` in the manager window, the watchdog brings it back.
- [ ] After a full reboot, the machine logs in, and the manager comes back without you touching it.
- [ ] `grep -rn "TELEGRAM_BOT_TOKEN=" ~/studio` finds nothing (secrets live outside the pod).
- [ ] The backup drive has a copy, and no `.env` files in it: `find "$BACKUP_DEST" -name '*.env*'` prints nothing.
- [ ] You can SSH into the host from your phone over the private network.
