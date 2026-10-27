---
name: wireframes
description: Create and edit low-fidelity HTML wireframes for screens, pages, flows, components and layouts. Use this skill EVERY time you create or edit a wireframe, and whenever the user asks to sketch, mock up, lay out, block out, or plan the structure of a UI, page, screen, dialog, dashboard or user flow — even if they never say the word "wireframe". Wireframes are saved as self-contained HTML files in [projectroot]/.wireframes/.
---

# Wireframes

Use this skill every time you create or edit a wireframe.

## Fixed rules (from the project owner)

- **Wireframes are HTML.** One self-contained `.html` file per wireframe.
- **Location:** created wireframes go into `[projectroot]/.wireframes/[framed content].html`
  - `[projectroot]` is the repository root (the directory containing `.git`, or the top-level project directory if there is no git repo). Never put wireframes inside `src/`, `public/` or any build directory.
  - `[framed content]` names *what the wireframe shows*, in lowercase kebab-case: `checkout-page.html`, `onboarding-flow.html`, `settings-notifications-dialog.html`, `invoice-table-component.html`.
  - Create the `.wireframes/` directory if it does not exist.

## Why wireframes exist (keep this in mind for every decision)

A wireframe answers *structure* questions — what is on the screen, in which order, how much weight each thing gets, and what happens when the user acts. It deliberately does not answer *styling* questions. Anything that pulls attention toward colors, brand, imagery or polish makes the wireframe worse, because reviewers start debating the paint instead of the plan. Every rule below follows from that.

## Workflow

### Creating a wireframe

1. **Understand the job of the screen.** Before drawing, state (to yourself, and in the wireframe's header) who uses this screen, what they are trying to get done, and what the single primary action is. If the codebase already has this screen or related data models/routes, read them first so the wireframe uses real fields, real entity names and real constraints.
2. **Check `.wireframes/` for existing files.** Reuse naming conventions and the shared visual vocabulary of existing wireframes so the set stays consistent. If a wireframe for the same content exists, edit it instead of creating a duplicate.
3. **Start from the template** in `assets/template.html` (relative to this skill). It contains the grayscale design tokens, placeholder primitives, annotation system and viewport switcher. Copy it, don't reinvent it.
4. **Block out hierarchy first, details second.** Lay out regions (header, nav, main, aside, footer) → then sections → then individual elements. Make sure the visual weight order matches the importance order.
5. **Annotate** (see below), cover the required states, and fill the header metadata.
6. **Verify** with the checklist at the end before reporting back.

### Editing a wireframe

- Edit the existing file in place. Do not create `-v2`, `-new` or `-final` copies unless the user explicitly asks for a variant.
- Preserve existing annotations that are still true; update or remove ones your change made false.
- Add an entry to the changelog block in the header (date + one line on what changed and why).
- If the user asks for alternatives to compare, put them in the same file as labelled options (`Option A`, `Option B`) side by side or as tabs, unless they ask for separate files — then use `[framed content]--option-a.html`.

## Visual language: low fidelity on purpose

- **Grayscale only.** Use the gray tokens from the template. The one exception is the annotation accent color (used only for notes/markers, never for UI), so annotations are clearly "not part of the design".
- **One system font stack**, a small type scale (e.g. 12 / 14 / 16 / 20 / 28px). Hierarchy comes from size, weight and spacing — not color.
- **Placeholders, not assets.** Images = gray box with an X and a label (`[Product photo 4:3]`). Icons = small labelled squares or a plain glyph. Charts = a box labelled with chart type and what it plots. No real logos, photos, icon fonts or brand colors.
- **Real-ish content, not lorem ipsum.** Use plausible labels, headings, button text and data (realistic names, prices, dates, long and short values). Copy is structure: a button that says "Save draft" vs "Publish" changes the design. Mark copy that still needs a writer with `[TBD]`.
- **Stress the content.** Include at least one long value (long name, 3-line title, 6-digit number) and one short/empty value so the layout's limits are visible.
- **Consistent spacing grid** (multiples of 4 or 8px). Alignment and grouping should be deliberate — misalignment reads as intent in a wireframe.

## Technical requirements

- Single self-contained file: inline `<style>` and `<script>`, no external CSS/JS/fonts/images, no build step, no framework. It must open correctly by double-clicking the file.
- Semantic HTML (`header`, `nav`, `main`, `section`, `aside`, `footer`, `button`, `form`, `label`, `table`). This doubles as documentation of the intended structure for whoever implements it.
- Use real form controls (`<input>`, `<select>`, `<button>`) so it's clickable, but they should do nothing destructive. Minimal JS is fine for toggling states, tabs, modals and the viewport switcher — never for fake data fetching.
- Layout with CSS grid/flexbox and relative units so it actually reflows; don't fake responsiveness with fixed pixel canvases.
- Keep it readable: someone should be able to open the source and understand the screen.

## Required content in every wireframe

1. **Header block** (the template has it): title, one-sentence purpose, primary user, primary action, status (`draft` / `in review` / `approved`), related wireframes (relative links), and a changelog.
2. **States.** Show every state that changes the layout, using the template's state switcher. Always consider: default/populated, empty (first use), loading, error, and — where relevant — partial data, permission-denied, success/confirmation, and overflow (very many items). If a state is intentionally out of scope, say so in an annotation instead of silently omitting it.
3. **Viewports.** If the screen will be used on more than one device class, show at least mobile (~375px) and desktop (~1280px) via the viewport switcher, and annotate what collapses, hides or reorders between them.
4. **Annotations.** Numbered markers on the wireframe that map to a numbered notes panel. Annotate:
   - behavior that is not visible (what a click does, validation rules, sorting/filter defaults, what's paginated and how)
   - data source and constraints (`max 80 chars`, `from Order.items`, `sorted by updatedAt desc`)
   - decisions and their reason ("Filters in a drawer on mobile because >6 filters")
   - open questions, marked `? Open question:` — these are as valuable as answers
   Keep each note to one or two sentences. Don't annotate the obvious ("this is a button").
5. **Interactions & flow.** For multi-screen flows, either one file per screen with links between them in step order, or one file with a step navigator. State where each primary/secondary action leads.

## Accessibility, baked in at wireframe stage

Structural accessibility is cheapest to fix now: indicate heading levels, logical tab/reading order (annotate if it differs from visual order), labels for every input, visible focus states, touch targets ≥ 44px on mobile, and never rely on position or icon alone to convey meaning.

## Things to avoid

- Styling polish: shadows, gradients, rounded "app look", animations, colors, real imagery.
- Lorem ipsum and identical placeholder rows (`Item, Item, Item`).
- Inventing features the user didn't ask for; if you think something is missing, add it as an annotated suggestion (`Suggestion:`), not as silent design.
- Drawing only the happy path.
- Splitting one screen across several files, or putting multiple unrelated screens in one file.
- Writing wireframes anywhere other than `[projectroot]/.wireframes/`.

## Pre-delivery checklist

Before telling the user you're done, verify:

- [ ] File is at `[projectroot]/.wireframes/[framed content].html` with a kebab-case name describing the content
- [ ] Opens standalone; no external requests (grep for `http` in `src`/`href` attributes)
- [ ] Grayscale only; accent color used exclusively for annotations
- [ ] Header block filled (purpose, user, primary action, status, changelog)
- [ ] Primary action is visually the most prominent element
- [ ] Empty, loading and error states present or explicitly scoped out
- [ ] Mobile and desktop shown (if applicable) and the differences annotated
- [ ] Every non-obvious behavior is annotated; open questions are listed
- [ ] Realistic content, including a long-value and an empty-value case
- [ ] HTML is valid and semantic

Then report back briefly: the file path, what the wireframe covers, the key structural decisions you made, and the open questions the user should answer.