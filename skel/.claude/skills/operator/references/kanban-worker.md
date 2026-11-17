# Kanban Worker

This is the execution loop the **operator root agent runs itself**. Subagents and forks cannot launch further agents, so the root is the only one who can dispatch ticket workers. The root does not implement tickets: it schedules them, hands each one to a worker, checks the result and records the new status on the board. The board file is the single source of truth, so anyone (a human, or the root after an interruption) can see exactly where things stand.

## The one rule about the board file

**The only change ever made to the board is a ticket's `status` value**, and only the root makes it. Never rewrite the file, reformat it, reorder it, add fields or touch titles, descriptions or dependencies. That way the valid JSON the planner wrote stays valid. The one exception is appending fix-up tickets after a failed completion review, which is done by a planner worker following `kanban-planner.md` ("To extend an existing board").

Each ticket has its id and status on one line:

```json
      "id": "007", "status": "todo",
```

To change a status, do a targeted find-and-replace (Edit tool) of exactly that fragment, including the id:

| Change | Find | Replace with |
|---|---|---|
| start | `"id": "007", "status": "todo"` | `"id": "007", "status": "in_progress"` |
| finish | `"id": "007", "status": "in_progress"` | `"id": "007", "status": "done"` |
| give up | `"id": "007", "status": "in_progress"` | `"id": "007", "status": "failed"` |

Because the id is in the search string, the match is unique. If the fragment isn't found exactly, re-read the file instead of improvising a different edit. Never write the board from a script or by regenerating its contents.

Statuses: `todo` → `in_progress` → `done` or `failed`.

Workers report back to the root and never touch the board file.

## Process

### 1. Start up
- Read the board (default `kanban.json` in the project root).
- If it doesn't parse as JSON, or a ticket lacks the `"id": "NNN", "status": "..."` line, stop and tell the user. Don't repair the board.
- Tickets already `in_progress` come from an interrupted run. Set them back to `todo`; their partial work is still on disk and the retry will see it.
- Tell the user in one or two lines how many tickets are done, how many remain, and which can start now.

### 2. Main loop
Repeat until nothing is left to start:

1. **Fork a scheduler** with the scheduler prompt below. It re-reads the board, finds every ready ticket (status `todo`, all dependencies `done`), works out which would touch the same files, and returns **lanes**: tickets in one lane run one after another, different lanes run in parallel. The fork only reads and returns text.
2. **Set each ticket to `in_progress` right before its worker starts.** In a multi-ticket lane, the later tickets stay `todo` until their turn.
3. **Start the first ticket of every lane in the same message**, so the lanes run in parallel, using the ticket prompt template below. At most **4** lanes at once (or what the user asked for). When a ticket finishes, start the next one in its lane.
4. **Handle each result** as described in step 3.
5. **Loop.** When every lane is finished, fork a new scheduler; finished tickets may have unlocked new ones.

The loop ends when the scheduler reports `READY: 0`. Either everything is `done`, or the rest waits on a `failed` ticket.

If the scheduler's answer doesn't follow the format, or lists a ticket that isn't actually ready, fork again and say what was wrong.

### 3. Handling a result
Each worker ends with a `RESULT:` block.

- **DONE**: if the ticket's Done-when names a cheap command (tests, build via `just`), fork a quick check or trust the worker's report of having run it; don't pull large output into the root. If it holds up, set the ticket to `done`.
- **FAILED**, or the check fails: retry **once** with a fresh worker and add the failure reason to its prompt. If the retry also fails, set the ticket to `failed`, keep the reason for the final report, and continue. Its dependents never become ready; everything else carries on.

Never fix a ticket's work in the root. The root's context has to last for the whole board.

### 4. Finish
Hand over to the completion review (see the root `SKILL.md`) with:
- done / total,
- each failed ticket with its reason,
- tickets left waiting on a failed dependency.

## Scheduler fork prompt

```
You are the scheduler for a kanban board. Read only; do not edit any file and do not launch agents.

Board file: <path to kanban.json>

1. Read the board. List every ticket whose status is "todo" and whose
   dependencies are all "done" (or that has no dependencies).
2. For each of these tickets, work out which files it will most likely create or
   modify, from its description and by looking at the repository.
3. Group the tickets into lanes:
   - Tickets that would touch the same file go into the same lane, in id order.
   - Tickets with no file overlap get their own lane.
4. Report in exactly this format and nothing else:

READY: <number of ready tickets>
LANES:
- lane 1: 003
- lane 2: 004 -> 006 (both edit src/api/routes.ts)
- lane 3: 005
NOTES: <anything the root should know, or "none">

If no ticket is ready, report "READY: 0" and an empty LANES list.
```

## Ticket prompt template

The worker starts with no context. Give it the board header, its ticket, and the title and description of each direct dependency, copied from the board. Add the skills or reference files it needs (e.g. "use the react and mui skills"), since project rules and skills apply to it too.

```
You are completing one ticket of a larger project board. Work only on this ticket.

PROJECT: <board title>
<board description>

TICKET <id>: <title>
<ticket description>

ALREADY COMPLETED (build on these, don't redo them; inspect the files they produced if you need details):
- <dep id> <dep title>: <dep description>
(or "none")

SKILLS TO USE: <skill names or reference files, or "none">

<only on retry: A PREVIOUS ATTEMPT FAILED: <reason>. Check what's already on disk before starting.>

Rules:
- Stay within this ticket's scope. Other agents work on other tickets in
  parallel in the same workspace, so don't modify files unrelated to your ticket.
- Never edit the board file (kanban.json).
- Do not commit; the root commits at the end.
- Verify your work against the "Done when" criteria before reporting.
- If the ticket is impossible or underspecified, don't invent a different design.
  Report FAILED with the reason.

End your reply with exactly this block:
RESULT: DONE | FAILED
SUMMARY: <1–2 sentences: what you did and the key files, or why it failed>
```
