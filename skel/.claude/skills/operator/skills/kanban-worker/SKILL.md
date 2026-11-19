---
name: kanban-worker
description: Execute a local JSON kanban board (kanban.json) to completion by acting as an orchestrator that spawns one subagent per ticket, respecting ticket dependencies and running independent tickets in parallel. Use this skill whenever the user asks to work through, run, execute, complete, process or "do" a kanban board, backlog, ticket list or task board — including boards made with the kanban-planner skill — or says things like "start working on the tickets" or "finish the board".
disable-model-invocation: true
---

# Kanban Worker

You are the **orchestrator**. You don't implement tickets yourself: you schedule them, hand each one to a subagent, check the result and record the new status on the board. The board file is the single source of truth, so anyone (a human, or you after an interruption) can see exactly where things stand.

## The one rule about the board file

**The only change you ever make to the board is a ticket's `status` value.** You never rewrite the file, reformat it, reorder it, add fields or touch titles, descriptions or dependencies. That way the valid JSON the planner wrote stays valid.

Each ticket has its id and status on one line, like this:

```json
      "id": "007", "status": "todo",
```

To change a status, do a targeted find-and-replace (your file edit / str_replace tool) of exactly that fragment, including the id:

| Change | Find | Replace with |
|---|---|---|
| start | `"id": "007", "status": "todo"` | `"id": "007", "status": "in_progress"` |
| finish | `"id": "007", "status": "in_progress"` | `"id": "007", "status": "done"` |
| give up | `"id": "007", "status": "in_progress"` | `"id": "007", "status": "failed"` |

Because the id is in the search string, the match is unique and can't land on another ticket. If the fragment isn't found exactly, re-read the file instead of improvising a different edit. Never write the file from a script or by regenerating its contents.

Statuses: `todo` → `in_progress` → `done` or `failed`.

Only you write to the board. Subagents report back to you and never touch the board file. That keeps it consistent even with several agents working at once.

## Process

### 1. Start up
- Locate the board (default `kanban.json` in the project root; ask if there's no obvious candidate) and read it.
- If it doesn't parse as JSON, or a ticket lacks the `"id": "NNN", "status": "..."` line, stop and tell the user. Don't repair the board yourself.
- If any tickets are `in_progress`, a previous run was interrupted. Treat them as ready to retry (set them back to `todo` with the same kind of targeted edit, or just pick them up again). Their partial work is still on disk, and the retry will see it.
- Tell the user in one or two lines what you found: how many tickets are done, how many remain, and which ones can start now.

### 2. Main loop
Repeat until nothing is left to start:

1. **Fork a scheduler.** Spawn one subagent (the "fork") with the scheduler prompt below. It re-reads the board, finds every ticket that can start now (status `todo`, and every dependency `done`), works out which of them would touch the same files, and hands you back a schedule of **lanes**: tickets in one lane run one after another, and different lanes run in parallel. The fork only reads; it never edits the board or any other file. Doing this in a fork keeps the file inspection out of your own context.
2. **Set each ticket to `in_progress` before spawning its subagent**, so the board always reflects reality. For a lane with several tickets, that means the first one now and each next one right before its own turn. The others stay `todo` until then.
3. **Spawn subagents as the fork recommends.** Start the first ticket of every lane **in the same turn**, so the lanes run in parallel, using the ticket prompt template below. Run at most **4** lanes at once (or the number the user asks for); if the fork returns more, start the rest as lanes finish. When a ticket finishes, start the next ticket in its lane.
4. **Handle each result as it comes back** (step 3 below).
5. **Loop.** When every lane of the schedule is finished, go back to step 1. Finished tickets may have unlocked new ones, so the next fork works from the updated board.

The loop ends when the fork reports no ready tickets. Either everything is `done`, or the rest is waiting on a `failed` ticket.

If the fork's answer doesn't follow the format, or lists a ticket that isn't actually ready when you check the board, don't guess. Fork again, telling it what was wrong.

### 3. Handling a result
Each subagent ends with a `RESULT:` block.

- **DONE**: do a quick sanity check proportionate to the ticket. If the Done-when names a command (tests, build), run it yourself; otherwise glance at the files it claims to have created. If that holds up, set the ticket to `done`.
- **FAILED**, or your check doesn't hold up: retry **once** with a fresh subagent and add the failure reason to its prompt. If the retry also fails, set the ticket to `failed`, remember the reason for your final report, and continue. Its dependents never become ready; everything else carries on. If the ticket was part of a lane, carry on with the next ticket in that lane: they only shared a lane because of file overlap, not because one needs the other.

Don't fix a ticket's work yourself in the orchestrator. Your context needs to last for the whole board, and fixing is what the retry is for.

### 4. Finish
Report briefly:
- done / total,
- each failed ticket with its reason (the board stores no reasons, so this report is where they live),
- tickets left waiting because something they depend on failed,
- anything a human should look at.

If tickets failed, suggest a concrete next step: fix it by hand and set it to `done`, or clarify or split the ticket and rerun. A rerun picks up where it left off, because the statuses are on the board.

## Scheduler (fork) prompt template

```
You are the scheduler for a kanban board. Read only; do not edit any file.

Board file: <path to kanban.json>

1. Read the board. List every ticket whose status is "todo" and whose
   dependencies are all "done" (or that has no dependencies).
2. For each of these tickets, work out which files it will most likely create or
   modify, from its description and by looking at the repository.
3. Group the tickets into lanes:
   - Tickets that would touch the same file go into the same lane, in id order,
     so they run one after another.
   - Tickets with no file overlap get their own lane, so they run in parallel.
4. Report in exactly this format and nothing else:

READY: <number of ready tickets>
LANES:
- lane 1: 003
- lane 2: 004 -> 006 (both edit src/api/routes.ts)
- lane 3: 005
NOTES: <anything the orchestrator should know, or "none">

If no ticket is ready, report "READY: 0" and an empty LANES list.
```

## Ticket prompt template

The subagent starts with no context. Give it the board header, its ticket, and the title and description of each direct dependency, copied from the board, so it knows what already exists and which interfaces to use.

```
You are completing one ticket of a larger project board. Work only on this ticket.

PROJECT: <board title>
<board description>

TICKET <id>: <title>
<ticket description>

ALREADY COMPLETED (build on these, don't redo them; inspect the files they produced if you need details):
- <dep id> <dep title>: <dep description>
(or "none")

<only on retry: A PREVIOUS ATTEMPT FAILED: <reason>. Check what's already on disk before starting.>

Rules:
- Stay within this ticket's scope. Other agents are working on other tickets in
  parallel in the same workspace, so don't modify files unrelated to your ticket.
- Never edit the board file (kanban.json).
- Verify your work against the "Done when" criteria before reporting.
- If the ticket is impossible or underspecified, don't invent a different design.
  Report FAILED with the reason.

End your reply with exactly this block:
RESULT: DONE | FAILED
SUMMARY: <1–2 sentences: what you did and the key files, or why it failed>
```

## If subagents aren't available

In environments without a subagent/Task tool, skip the fork and work out the ready tickets yourself, then run them one at a time: set it to `in_progress`, do the work yourself following the ticket template's rules, verify it, set it to `done` or `failed`, and move on.
