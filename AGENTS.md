# Tony's agent instructions

These are common instructions for Tony's agents across all scenarios.

## General Guidelines

- Never use the em dash "—". Use commas, colons, or semicolons, depending on the context.
- When writing commit messages, NEVER auto-add your agent name as co-author.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, & long-term maintainability.
- Prioritize native language features and standard libraries over external packages unless explicitly requested.
- Shy away from making significant assumptions. If one or more things are unclear, ask me for clarification prior to going too deep down a wrong path. 
- Always respond to me in ASD-STE100 Simplified Technical English.

## Git and SSH

- My GitHub SSH key is `~/.ssh/id_github`, and it has a passphrase. Before any
  operation that contacts the remote, probe it with `git ls-remote origin HEAD`.
- If the probe fails with `Permission denied (publickey)`, the key is not loaded
  in this session. Stop and ask me to run:

  ```bash
  ssh-add ~/.ssh/id_github
  ```

  The passphrase prompt needs a TTY that you do not have, so you cannot run it
  for me. Wait for me to confirm, run the probe again, then continue.
using a different credential.
