---
name: kanban-planner
description: Break a task or project down into a granular local kanban board stored as a JSON file (kanban.json), with tickets that have id, status, title, description and dependencies (e.g. ticket 012 cannot start before 007 is done). Use this skill whenever the user wants to plan, split, decompose or break down work into tickets, subtasks, a backlog, a task board or a kanban board — especially when the plan is meant to be executed later by AI agents or by the kanban-worker skill — even if they don't say "kanban" explicitly.
disable-model-invocation: true
---

# Kanban Planner

Turn a goal into a JSON kanban board that AI agents can execute ticket by ticket. The board is executed later by the `kanban-worker` skill, which hands **each ticket to a fresh subagent that sees nothing but that ticket and the board header**, and which changes nothing in the file except `status` values. That means the board you write is final: it must be valid, complete and self-explanatory on the first try.

## Board format

Write a single JSON file (default: `kanban.json` in the project root, unless the user names another path). Use **exactly this layout**:

```json
{
  "title": "Add user accounts to the todo app",
  "description": "Overall goal and context that applies to every ticket: stack, repo layout, conventions, how to run tests, assumptions made during planning.",
  "tickets": [
    {
      "id": "001", "status": "todo",
      "title": "Create users table migration",
      "description": "In db/migrations/, add a migration creating a `users` table with id (uuid pk), email (unique, not null), password_hash, created_at. Follow the naming style of existing migrations.\n\nDone when: the migration runs cleanly on a fresh database and rolls back cleanly.",
      "dependencies": []
    },
    {
      "id": "002", "status": "todo",
      "title": "Add User model and repository",
      "description": "...\n\nDone when: ...",
      "dependencies": ["001"]
    }
  ]
}
```

The layout is part of the contract, not just style:

- **`"id"` and `"status"` share one line, in that order: `"id": "001", "status": "todo",`.** The worker updates a ticket by replacing exactly that line fragment (e.g. `"id": "007", "status": "todo"` → `"id": "007", "status": "in_progress"`). Because the id is in the same string, the replacement is unique and can't hit the wrong ticket or break the JSON. Keep this exact spacing: one space after each colon, one space after the comma.
- 2-space indentation, one field per line otherwise, as shown.
- No extra fields. The worker won't add any either.

Field rules:
- `id`: zero-padded three-digit string (`"001"`, `"087"`, `"112"`), unique, numbered in reading order.
- `status`: always `"todo"` on a new board. Valid values are `todo`, `in_progress`, `done`, `failed`.
- `title`: short and imperative ("Add login endpoint", not "Login").
- `description`: self-contained instructions, ending with a `Done when:` line. A single JSON string: line breaks as `\n`, double quotes escaped as `\"`, backslashes as `\\`.
- `dependencies`: ids that must be `done` before this ticket may start. `[]` if none. **Every dependency must have a lower id than the ticket itself.** This one rule makes cycles impossible, so number your tickets in an order where that holds.

## Process

1. **Understand the goal.** If you're in a code repository, look around first (layout, stack, conventions, tests). Tickets that name real files and real commands are much better than generic ones. If something essential is truly ambiguous, ask one question; otherwise make a reasonable assumption and record it in the board `description`.
2. **Draft the breakdown** and split until each ticket meets the granularity rules below.
3. **Order and wire dependencies.** Put foundations first so every dependency points backwards, then assign ids.
4. **Write the file** in the layout above.
5. **Check it** (next section). Fix anything wrong and check again.
6. **Report back briefly:** number of tickets, which ones can start immediately, any assumptions, and that the `kanban-worker` skill runs it. Don't paste the whole JSON into chat unless asked.

To *extend* an existing board: keep existing tickets byte-for-byte unchanged, append new tickets with the next free ids, and run the checks again.

## Checking the board

Nobody repairs the board after you, so re-read the file you wrote and go through this list:

- **JSON syntax:** commas between tickets but none after the last ticket or last field; every string closed; no raw line breaks or unescaped `"` inside descriptions; brackets and braces balanced. If you can run a command, `python -m json.tool kanban.json > /dev/null` (or `jq . kanban.json`) is a quick confirmation, but the file must also be right by inspection.
- **Layout:** every ticket has the `"id": "NNN", "status": "todo",` line exactly as specified.
- **Ids:** unique, three digits, strings.
- **Dependencies:** each one refers to an existing id that is lower than the ticket's own id; no ticket depends on itself.
- **Descriptions:** every one ends with `Done when:` and makes sense to someone who has read nothing else.
- **Parallel safety:** no two tickets without a dependency path between them edit the same file.

## Granularity: what a good ticket is

A ticket is right-sized when **one agent can finish it in one focused session without making big design decisions**:

- It produces one coherent, verifiable change: a module, an endpoint, a migration, a component, a test suite, a config change, a doc section.
- It typically touches a handful of files, not the whole codebase.
- It has an objective Done-when check, ideally a command that passes (tests, build, lint) or an observable result.
- Split further if the description needs "and" to join unrelated work, or if you can't state a single Done-when.
- Don't split below usefulness: "create file X" + "add function to X" + "export it" is one ticket. Over-splitting multiplies hand-off overhead.

Rough guide: a small feature is 5–15 tickets, a mid-sized project 15–50. End with an integration ticket ("Run the full test suite and fix integration issues") that depends on the leaf tickets. It catches seams between tickets that individual agents couldn't see.

## Writing descriptions for a context-free agent

The worker's subagent receives only the board `title` and `description`, its own ticket, and the titles and descriptions of its direct dependencies. There are no notes passed between tickets, so **everything one ticket needs from another must be fixed in the descriptions up front**:

- State **where** (file paths, modules), **what** (behaviour, names, signatures), and **constraints** (conventions, libraries).
- Define shared interfaces explicitly and identically on both sides. If 005 creates `getUser(id): User | null` in `src/users/repo.ts` and 009 calls it, both descriptions name that exact function, signature and path. This is how agents working at the same time stay compatible.
- Say where each ticket's output goes, since agents only communicate through the files they leave behind.
- No references like "as discussed" or "the approach above". Repeat what's needed.
- Put context shared by all tickets in the board `description` once rather than repeating it.

## Dependencies

- Add one only when a ticket truly needs the other's output (a file, a schema, an API). Fewer false dependencies means more parallelism.
- **Do add one when two tickets would edit the same file**, even if they're logically independent. The worker runs independent tickets in parallel, and parallel edits to one file collide. Either chain them or restructure so each ticket owns its files.
- Aim for a wide, shallow graph: a foundation layer (scaffolding, schema, shared types), then many independent tickets, then integration.

## Non-code tasks

The same format works for research, writing, data work and so on. Keep the same rules: self-contained descriptions, an explicit output location (e.g. "write findings to `research/competitors.md`"), and a checkable Done-when.
