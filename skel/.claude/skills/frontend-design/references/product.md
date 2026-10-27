# Product register: apps, dashboards, admin panels, tools, settings

Here design serves the task. Success is measured in how quickly someone can orient, decide and act. Beauty comes from clarity, consistency and calm, not from spectacle.

## Structure

Organize around a few clear regions:

- **Navigation** — where am I, where can I go
- **Primary workspace** — the thing being worked on
- **Secondary context** — details, inspector, filters (collapsible when space is tight)
- **One clear accent** — reserved for the primary action and important state

No hero section, no marketing headline, no "Welcome back, Alex 👋" banner taking up the first screen unless asked. Open on the working surface.

## Calm surface hierarchy

- Use two or three surface levels at most (page, panel, raised element). Distinguish them with subtle background shifts or a single hairline, not heavy borders on every region.
- Cards only when a card *is* the unit of interaction (draggable, selectable, a link to a detail page). A dashboard made of a mosaic of identical cards is a layout failure, not a design system.
- If a panel can become plain layout without losing meaning, drop the card treatment.
- Icons should aid scanning. Ornamental icons next to every label add noise.
- Avoid decorative gradients and glows behind routine UI.

## Density

- Product UI can and often should be dense. Reduce padding before you reduce information.
- Align everything to a grid; density without alignment reads as clutter.
- Use type weight and color (text vs muted text) for hierarchy rather than size jumps.
- Group related controls; separate groups with space, not boxes.

## Tables and data

- Right-align numbers, use `tabular-nums`, keep units consistent and in the header where possible.
- Left-align text. Truncate long values with an ellipsis and expose the full value (tooltip, detail view).
- Sticky headers on long tables; sticky first column on wide ones.
- Sorting, filtering and pagination state in the URL.
- Show freshness when data can be stale ("Updated 3 min ago").
- Empty table: explain why it's empty and offer the next step (create, import, clear filters).

## Charts

- Choose the chart for the question: change over time → line; comparison across categories → bar; part of whole with few parts → stacked bar (rarely pie).
- Label directly when possible instead of relying on legends.
- Muted colors for context, the accent for the one series that matters.
- Start bar axes at zero. Don't use 3D, don't use dual axes unless unavoidable.
- Charts need accessible alternatives (a summary sentence or the data table).

## Forms

- One column for most forms. Labels above inputs. Group related fields with headings.
- Mark optional fields rather than required ones when most fields are required.
- Validate on blur or submit, not on every keystroke. Error messages next to the field, saying how to fix it.
- Primary action at the end of the form, named for what it does. Secondary actions visually quieter.
- Preserve input on error and on accidental navigation where possible.
- Long settings pages: save per section or auto-save with clear status, never a single save button 3,000px away.

## Feedback

- Every action gets a response within ~100ms: a pressed state, a spinner, an optimistic update.
- Optimistic UI for low-risk actions, with rollback and a clear message on failure.
- Toasts for confirmations that need no action; inline messages for things tied to a place; dialogs only when a decision is required. A modal shouldn't be the first idea.
- Prefer undo over "Are you sure?" for reversible actions.

## Utility copy

- Headings say what an area is or what you can do there: "Billing", "Team members", "Recent deployments".
- Supporting text explains scope, behavior or freshness in one sentence.
- Consistent terminology across the product: if it's a "workspace" in the nav, it's not a "project" in a dialog.
- Litmus: if someone scans only headings, labels and numbers, do they understand the screen?

## Final checks for product UI

- Does the screen open on the work, not a pitch?
- Is the accent reserved for action and state?
- Are there any cards that should just be layout?
- Do all states exist: empty, loading, error, very long content, many items, no permission?
- Is it usable with the keyboard alone, including tables, menus and dialogs?
