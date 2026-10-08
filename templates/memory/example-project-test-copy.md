---
name: Project A test copy
description: Project A experiments go to the test server only; the live one needs the owner's OK
type: project
---

Project A runs two copies of its web server: the live one and a test copy on a separate port and folder (see
`projects/project-a/PROJECT.md` for both). All experiments, debugging and new features go on the test copy first.
Restarting or reconfiguring the live copy needs the owner's OK, typed at the terminal.

**Why:** the owner decided this on 2026-10-03 after an experiment restarted the live server while it was in use.

**How to apply:** any brief that touches Project A's server names the test copy explicitly. When a change is proven
on the test copy, prepare the live change and ask the owner; don't apply it yourself.
