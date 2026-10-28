## Project rules beat global rules

Instructions that live **in the project** outrank anything loaded globally from
`~/.claude/` (global rules, user-level skills, plugin skills and agents).

Order of precedence, highest first:

1. What the user says in this session.
2. Project files: `./CLAUDE.md`, `./AGENTS.md`, `./.claude/rules/`, `./.claude/skills/`, `./.project/`.
3. Global rules and skills from `~/.claude/` and installed plugins.

How to apply it:

- **Look before you follow.** Before applying a global rule or skill to a task,
  check whether the project has its own rule or skill on the same topic. If it
  does, follow the project's version.
- **A project skill replaces the global one of the same name**, it does not merge
  with it. Don't mix halves of both.
- **Existing code counts as a project convention.** If the codebase consistently
  does something differently from a global rule, follow the codebase.
- **Say it once, then move on.** When a project rule contradicts a global one,
  mention the conflict in a sentence and follow the project. Don't argue it,
  don't "fix" the project to match the global rule, and don't silently apply the
  global one anyway.
- The only global instructions that still win are hard safety limits: never
  commit or log secrets, never run destructive commands without confirmation.
