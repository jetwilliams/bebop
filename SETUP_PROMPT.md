# One-prompt setup

Open a terminal on the machine that will run your studio, clone this repo, start your coding agent
(Claude Code, Codex or similar) **inside the repo folder**, and paste the prompt below.

The agent checks what you already have, asks you a few questions, shows a plan, and only then sets
things up, asking before every step that changes your system. It saves your answers, so you can run
the same prompt again later to update or repair the setup without starting over.

```text
Set up Bebop on this machine for me, using this repository as the guide.

STEP 0 — Read first.
Read README.md, SETUP_PROMPT.md, docs/ (setup, security, memory, delegation, model-swap) and the files
in templates/ and scripts/ before doing anything.

STEP 1 — Check what already exists (read-only, change nothing).
- Is there a saved answers file from a previous run (bebop.answers.md in the studio folder)?
  If yes, this is a RE-RUN: show me what's saved and ask what I want to change.
- OS and version; is the machine set to stay awake / auto-restart?
- Which tools are installed: tmux, git, Node.js, Claude Code, Codex, Tailscale (or another private network)?
- Does a studio folder / context pod already exist? Any existing AGENTS.md, CLAUDE.md or memory/ folder?
- Is a tmux session or watchdog already running?
Report what you found in a short list.

STEP 2 — Interview me, one short question at a time. Skip anything STEP 1 already answered.
About me and my manager
- What's your name, and what should your manager agent be called?
- Personality: what's it inspired by, its personality in one line, its tone with you, language,
  and anything it must never do?
- How do you like replies: short or detailed? Voice notes or text?
Memory and context
- Do you already have a memory/notes folder or a context pod (e.g. from the context-pod template)?
  If yes: where is it, and should I USE it as-is, IMPORT parts of it, or start fresh beside it?
- Anything I should know about you to start with (work, interests, goals)? Keep it light; you can add more later.
Projects
- What are your first 1–3 projects (name + one line each)? Do any already have folders I should adopt?
Models and tools
- Which agent should run the manager (Claude Code, Codex, other)? Do you want a backup model?
- Do you already have a Telegram bot for this, or should we make a new one?
Safety and approvals
- Which actions must ALWAYS wait for your typed OK at this machine? (Defaults: spending money,
  posting publicly, changing live systems, installing software.) Add any of your own.
- Do you have a private network to reach this machine from your phone (e.g. Tailscale)? If not, do you want one?
Backups
- Do you want automatic backups of the studio folder? To where (external drive, other)?

STEP 3 — Plan.
Show me a short numbered plan built from my answers (what you'll create, install, configure, and what
I'll need to do by hand). Wait for my OK. Change the plan if I ask.

STEP 4 — Build, step by step, telling me what each step does. Never overwrite an existing file
without showing me the difference and asking first.
- Create or adopt the context pod: AGENTS.md (from templates/HANDOVER.md), the manager's role file
  (from templates/MANAGER.md with my answers filled in, including the personality and approval list),
  memory/MEMORY.md, and one folder per project (from templates/PROJECT.md).
- Save my answers to bebop.answers.md in the studio folder (no secrets in it).
- Write the scripts' config from scripts/studio.env.example with my choices.
- Start tmux with scripts/studio-up.sh and check it works.
- Install the watchdog (launchd on macOS, systemd on Linux) and test it.
- Set up backups if I chose them.

STEP 5 — Telegram.
- New bot: walk me through BotFather (/newbot) and the settings in docs/setup.md.
- I will type the bot token MYSELF into the hidden prompt from scripts/set-secret.sh.
  Never ask me to paste the token into this chat, and never print it.
- Help me install and pair the Telegram channel plugin, restricted to my account only.

STEP 6 — Test and hand over.
- Tell me to message the bot from my phone: "hi, what can you do?" and check it answers in its personality.
- Finish with a checklist: what's running, what's saved where, how to re-run this setup, and what I
  still need to do by hand.

Rules for you while doing this:
- Ask before installing software, changing system settings, creating background services, or
  modifying any file that already existed.
- Never handle secrets in chat; secrets only go in through hidden prompts typed by me.
- Don't open any port to the internet; remote access is through a private network only.
- If a step fails, stop and explain; don't work around security settings.
```

## Re-running

Run the same prompt any time: after moving machines, adding projects, changing your manager's
personality, or if something broke. The agent reads `bebop.answers.md`, shows what's saved, and only
changes what you ask it to.

## After setup

Message your bot from your phone: "hi, what can you do?" Your manager should answer in the
personality you gave it. Then try: "start a new project called test and tell me when it's set up."
