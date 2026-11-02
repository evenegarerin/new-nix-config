---
name: wireframes
description: Create and edit low-fidelity HTML wireframes for screens, pages, flows, components and layouts. Use this skill EVERY time you create or edit a wireframe, and whenever the user asks to sketch, mock up, lay out, block out, or plan the structure of a UI, page, screen, dialog, dashboard or user flow — even if they never say the word "wireframe". Wireframes are saved as self-contained HTML files in [projectroot]/.wireframes/ and link to each other so the set is click-through, like the real product.
---

# Wireframes

Use this skill every time you create or edit a wireframe.

## Fixed rules (from the project owner)

- **Wireframes are HTML.** One self-contained `.html` file per wireframe.
- **Location:** created wireframes go into `[projectroot]/.wireframes/[framed content].html`
  - `[projectroot]` is the repository root (the directory containing `.git`, or the top-level project directory if there is no git repo). Never put wireframes inside `src/`, `public/` or any build directory.
  - `[framed content]` names *what the wireframe shows*, in lowercase kebab-case: `checkout-page.html`, `onboarding-flow.html`, `settings-notifications-dialog.html`, `invoice-table-component.html`.
  - Create the `.wireframes/` directory if it does not exist.
- **Wireframes link to each other.** A flow is walked by clicking, not by reading file names. See *Linking*.
- **Existing wireframes are not overwritten.** You may only change a file that is already there to keep it true (see *Changing an existing wireframe*). New work goes into a new file.

## Why wireframes exist (keep this in mind for every decision)

A wireframe answers *structure* questions — what is on the screen, in which order, how much weight each thing gets, and what happens when the user acts. It deliberately does not answer *styling* questions. Anything that pulls attention toward colors, brand, imagery or polish makes the wireframe worse, because reviewers start debating the paint instead of the plan. Every rule below follows from that.

## Workflow

### Creating a wireframe

1. **Understand the job of the screen.** Before drawing, state (to yourself, and in the comment at the top of the wireframe's source) who uses this screen, what they are trying to get done, and what the single primary action is. If the codebase already has this screen or related data models/routes, read them first so the wireframe uses real fields, real entity names and real constraints.
2. **List `.wireframes/` first — always.** `ls .wireframes/` before you write anything. It tells you three things: the naming conventions and visual vocabulary to stay consistent with, whether this screen already exists (if so, read *Changing an existing wireframe* — do not start over), and which neighbouring screens you will have to link to.
3. **Place the screen in the flow.** Name the screen the user comes *from* and the screen(s) they go *to* before drawing. Those become real links (see *Linking*). A screen with no entry point and no exit is almost always a sign you have not understood the job yet.
4. **Start from the template** in `assets/template.html` (relative to this skill). It contains the embedded sketch font, the grayscale design tokens, placeholder primitives, the hover-annotation system, flow navigation and the viewport/state switchers.
   Copy it with the shell — `cp -n <skill>/assets/template.html .wireframes/<framed content>.html` — then edit that copy. The `-n` is not optional: it is what stops you from silently flattening an existing wireframe. If `cp` reports the file exists, stop and read it. Never retype or re-read the template in full: the font is embedded as a ~70 KB base64 string near the top and it has no business in anyone's context window. Same for a second wireframe: `cp -n` an existing one.
5. **Block out hierarchy first, details second.** Lay out regions (header, nav, main, aside, footer) → then sections → then individual elements. Make sure the visual weight order matches the importance order.
6. **Annotate** (see below), cover the required states, and fill the metadata comment at the top of the file.
7. **Wire it up.** Fill the flow nav and the *Reached from* / *Leads to* rows, make the navigating actions real links, and add the new file to `.wireframes/index.html` (see *Linking*).
8. **Verify** with the checklist at the end before reporting back.

### Changing an existing wireframe

A wireframe that is already in `.wireframes/` is a record: someone reviewed it, decided things with it, and may have linked to it from a ticket. Treat it as append-mostly. The question is never "would I draw it this way?" but "is it still *true*?".

**Touch an existing file only for these reasons:**

- The user asked for a change to that specific screen.
- A new or renamed wireframe made its links, *Reached from* / *Leads to* rows or flow nav wrong or incomplete.
- An annotation, label, field name or constraint became false (the data model changed, a decision was made, an open question got answered).
- It is broken: dead link, invalid HTML, a placeholder like `[next-screen]` that was never filled in.

**Never, unless the user explicitly asks:**

- Overwrite it by copying the template or another wireframe over it. Always `cp -n`.
- Regenerate it from scratch because editing looks harder than rewriting.
- Restyle, reformat, reorder or "tidy" it — including making it match a newer wireframe's conventions.
- Sweep the whole folder "for consistency" after one change.
- Delete or rewrite annotations, open questions or changelog entries, or change its status (`draft` → `approved` is the user's call).
- Remove states, viewports or content you think are redundant.

**How to make the change:**

- Edit in place, smallest diff that makes it true. Leave everything your change does not contradict exactly as it is.
- Update annotations your change made false; keep the ones that still hold. If an open question got answered, replace it with the answer rather than deleting it.
- Append a changelog entry to the `CHANGELOG` block in the file's metadata comment: date + one line on what changed and why.
- Do not create `-v2`, `-new` or `-final` copies. If the user wants alternatives to compare, put them in one file as labelled options (`Option A`, `Option B`), or — if they ask for separate files — `[framed content]--option-a.html`, with the options linking to each other.
- Redesigning a screen so heavily that the old one is still worth keeping? Ask the user first whether to replace it or keep both as variants.

## Linking: the set is click-through

A folder of unconnected screens does not show a workflow. Someone should be able to open the first screen, click the primary action, and land on what really comes next — that is how missing steps, dead ends and impossible back-navigation get found, and it costs nothing at wireframe stage.

- **Navigating actions are real links.** Anything that takes the user to another screen is `<a class="btn btn-primary" href="./[next-screen].html">` — not a `<button>`. Buttons stay buttons only for actions that do not leave the screen (open a modal, switch a tab, submit in place); those are shown with the state switcher inside the same file.
- **Relative links only** (`./other-screen.html`). The `.wireframes/` folder must stay movable and work from `file://`. No absolute paths, no `http(s)` links to anything in the set.
- **Never link to a file that does not exist.** If the destination is not wireframed yet, use `<a class="btn" aria-disabled="true">[Label]</a>` (the template styles it dashed and muted) plus a note saying where it would go and why it is not drawn. A dead `href` makes the whole set untrustworthy.
- **Every screen says where it sits.** Fill the `.wf-flow` nav in the control bar with the real step order, `aria-current="page"` on the current screen, and the *Reached from* / *Leads to* rows in the file's metadata comment. Delete the nav only if the screen genuinely has no flow.
- **Links go both ways.** If A leads to B, B links back to A (its own back/cancel action, or at minimum the flow nav). A screen you can only reach by typing its file name is not part of the flow.
- **Dead ends are annotated, not left silent.** "Ends the flow; user returns to the dashboard" is a note worth writing.
- **Keep `.wireframes/index.html` current.** It is the entry point: every wireframe listed, grouped by flow, in walk order. Create it from `assets/index-template.html` (`cp -n`) as soon as there is more than one wireframe, and add new files to it. Every screen links back to it from the control bar.
- **One screen per file, one file per screen.** Modals, drawers, inline expansions and validation errors belong to their parent screen as states — not separate files. A genuinely separate destination gets its own file.
- **Renaming is a flow edit.** If you rename a wireframe, update every file that links to it and the index in the same change. Check with `grep -l '[old-name]' .wireframes/*.html`.

## Visual language: low fidelity on purpose

- **Grayscale only.** Use the gray tokens from the template. The one exception is the annotation accent color (used only for notes/markers, never for UI), so annotations are clearly "not part of the design".
- **Hand-drawn font for the framed content.** The template embeds Excalifont (the Excalidraw sketch face, taken from the wireframe-kit) as `var(--font)` and applies it to everything inside the frame. A sketchy face is a feature, not decoration: it tells reviewers at a glance that nothing here is final, so they comment on structure instead of on type choices. Never swap it for a production typeface or load it from a CDN.
- **System font for the wireframe chrome.** The control bar and the annotation markers and tooltips use `var(--font-ui)`, so the scaffolding around the wireframe stays visibly separate from the wireframe itself — same reason the accent color is annotation-only.
- **One type scale** (e.g. 12 / 14 / 16 / 20 / 28px). Hierarchy comes from size, weight and spacing — not color, and not a second font family.
- **Placeholders, not assets.** Images = gray box with an X and a label (`[Product photo 4:3]`). Icons = small labelled squares or a plain glyph. Charts = a box labelled with chart type and what it plots. No real logos, photos, icon fonts or brand colors.
- **Real-ish content, not lorem ipsum.** Use plausible labels, headings, button text and data (realistic names, prices, dates, long and short values). Copy is structure: a button that says "Save draft" vs "Publish" changes the design. Mark copy that still needs a writer with `[TBD]`.
- **Stress the content.** Include at least one long value (long name, 3-line title, 6-digit number) and one short/empty value so the layout's limits are visible.
- **Consistent spacing grid** (multiples of 4 or 8px). Alignment and grouping should be deliberate — misalignment reads as intent in a wireframe.

## Technical requirements

- Single self-contained file: inline `<style>` and `<script>`, no external CSS/JS/fonts/images, no build step, no framework. It must open correctly by double-clicking the file. Relative `<a href="./other-wireframe.html">` links to the other files in `.wireframes/` are the one intended exception — they are navigation, not a dependency, and the file still renders fine on its own.
- The font stays an embedded `data:font/woff2;base64,…` URI inside that `<style>`. Don't extract it to a `.woff2` next to the HTML and don't link Google Fonts — both break the "opens anywhere, no network" property. `assets/Excalifont-Regular.woff2` is kept beside the template only as the source for re-embedding if the template ever needs rebuilding. `assets/index-template.html` is the starting point for `.wireframes/index.html`; it needs no sketch font, because the index is chrome rather than a wireframe.
- Semantic HTML (`header`, `nav`, `main`, `section`, `aside`, `footer`, `button`, `form`, `label`, `table`). This doubles as documentation of the intended structure for whoever implements it.
- Use real form controls (`<input>`, `<select>`, `<button>`) so it's clickable, but they should do nothing destructive. Minimal JS is fine for toggling states, tabs, modals and the viewport switcher — never for fake data fetching.
- Layout with CSS grid/flexbox and relative units so it actually reflows; don't fake responsiveness with fixed pixel canvases.
- Keep it readable: someone should be able to open the source and understand the screen.

## The page: a control bar and the frame, nothing else

The browser window is the device. The only chrome is one bar across the top; everything below it
is the wireframe.

- **The frame fills the window below the bar.** `body` is a flex column — the bar, then
  `.wf-stage`, which takes everything that is left. A screen written against `height: 100%`
  therefore gets the real window, and `.screen` is `min-height: 100%` so a screen that does not
  set its own height still fills it. A wireframe reviewed in a 1280 px box on a 1920 px screen
  answers a question nobody asked.
- **The bar and the frame are the only things that render.** No notes column beside the frame,
  no metadata block above it, no open-questions section under it, and no panel or control that
  opens one. Anything that *describes* the wireframe rather than *being* it is an HTML comment
  at the top of the source — see *Required content* — where it stays with the file and costs the
  reviewer no screen.
- **The one exception is `<ol id="wf-notes">`, and it is invisible.** It sits after the stage with
  `class="wf-notes"`, clipped to a pixel but still in the accessibility tree, because the tooltip
  reads its text from there and it is the only route to a note for a keyboard or a screen reader.
  `display: none` and `hidden` take away both; use neither.
- **Only `Desktop (full)` is the window.** Mobile and tablet keep their fixed widths (375 px,
  768 px), centred, with a side border on each edge so they read as a device standing on the
  page rather than as a broken layout.
- **Scrolling belongs to the screen, not the page.** `body` has `overflow: hidden`; the stage and
  the frame scroll. A screen taller than the window scrolls inside the frame, exactly as it would
  in the product.

## Required content in every wireframe

1. **Metadata, in a comment at the top of `<body>`** (the template has it): title, one-sentence purpose, primary user, primary action, status (`draft` / `in review` / `approved`), *Reached from* / *Leads to* / related wireframes (as `label (./file.html)`), the open questions and a changelog. Plain text, not markup — it is read in an editor, never in a browser. Opening the file shows the screen and nothing else. Remember an HTML comment may not contain `--`: write an em dash, not two hyphens.
2. **States.** Show every state that changes the layout, using the template's state switcher. Always consider: default/populated, empty (first use), loading, error, and — where relevant — partial data, permission-denied, success/confirmation, and overflow (very many items). If a state is intentionally out of scope, say so in an annotation instead of silently omitting it.
3. **Viewports.** If the screen will be used on more than one device class, show at least mobile (375px) and desktop (the real window) via the viewport switcher, and annotate what collapses, hides or reorders between them.
4. **Annotations.** A marker is a numbered pink circle sitting **on the thing it is about**, and it reveals its note on hover, on focus and on tap. There is no notes column beside the wireframe: a panel of prose competes with the screen for attention, and the reader has to map numbers to text by eye.
   - The markup is `<button type="button" class="wf-marker" data-note="3" aria-label="Note 3">3</button>`. `data-note` is the **1-based position** of the item in the hidden `<ol id="wf-notes">` after the frame, which is the single source of the text. Reorder that list and every `data-note` has to move with it.
   - Keep the list anyway, hidden. Hover reaches no keyboard and no screen reader, so without it a note has exactly one route and some readers have none. It is not a duplicate to maintain by hand: the tooltip is built from it.
   - **Give every note a marker.** A note with no marker now reaches nobody at all — the list it lives in does not render. The one honest exception is a note about something that is *not* on the screen ("no empty state, because there is no data to be empty of") — say so in the note.
   - Next to a block element inside a flex column, a marker becomes a flex item and drops to its own line. Wrap the two in `<div class="wf-anchor">`.
   - Annotate:
     - behavior that is not visible (what a click does, validation rules, sorting/filter defaults, what's paginated and how)
     - data source and constraints (`max 80 chars`, `from Order.items`, `sorted by updatedAt desc`)
     - decisions and their reason ("Filters in a drawer on mobile because >6 filters")
   Keep each note to one or two sentences. Don't annotate the obvious ("this is a button").
   - **Open questions are not notes.** They get no marker — they are about the screen, not about a spot on it. They go under `OPEN QUESTIONS` in the metadata comment, and they are the reason the wireframe is being reviewed at all, so say them to the user in your report rather than leaving them to be found in the source. Where the project keeps its own record of open questions (`.project/questions.md` here), put them there too.
5. **Interactions & flow.** Every primary and secondary action states where it leads — as a real link if it leaves the screen, as a state if it does not. Multi-screen flows are one file per screen, wired together with the flow nav so they can be clicked through end to end (see *Linking*).

## Accessibility, baked in at wireframe stage

Structural accessibility is cheapest to fix now: indicate heading levels, logical tab/reading order (annotate if it differs from visual order), labels for every input, visible focus states, touch targets ≥ 44px on mobile, and never rely on position or icon alone to convey meaning.

## Things to avoid

- Styling polish: shadows, gradients, rounded "app look", animations, colors, real imagery.
- Lorem ipsum and identical placeholder rows (`Item, Item, Item`).
- Inventing features the user didn't ask for; if you think something is missing, add it as an annotated suggestion (`Suggestion:`), not as silent design.
- Drawing only the happy path.
- Splitting one screen across several files, or putting multiple unrelated screens in one file.
- Writing wireframes anywhere other than `[projectroot]/.wireframes/`.
- Orphan screens: no inbound link, no outbound link, not in the index.
- Dead `href`s, or `<button>` for something that is really navigation.
- Rewriting, restyling or overwriting a wireframe that was already there.

## Pre-delivery checklist

Before telling the user you're done, verify:

- [ ] File is at `[projectroot]/.wireframes/[framed content].html` with a kebab-case name describing the content
- [ ] No existing wireframe was overwritten, regenerated or restyled; anything you did touch got a changelog entry and the smallest possible diff
- [ ] Opens standalone; no external requests (grep for `http` in `src`/`href` attributes — links to other wireframes are relative `./…`)
- [ ] Every link resolves to a file that exists in `.wireframes/` (`grep -o 'href="\./[^"]*"' <file>`, then check each one); undrawn destinations use `aria-disabled="true"` + a note
- [ ] Flow nav and *Reached from* / *Leads to* are filled with real neighbours, or the nav is deleted because the screen is standalone; no `[placeholder]` links left
- [ ] Navigating actions are links, in-screen actions are buttons; the flow can be clicked through and walked back
- [ ] `.wireframes/index.html` exists (once there is more than one wireframe) and lists this file
- [ ] Grayscale only; accent color used exclusively for annotation markers, tooltips and open questions
- [ ] Sketch font renders (framed content in Excalifont, chrome in the system font) and is still embedded as a data URI
- [ ] Metadata comment filled (purpose, user, primary action, status, reached from / leads to, open questions, changelog), and it contains no `--`
- [ ] The frame fills the window below the bar at `Desktop (full)`, and the bar is the only other
      thing that renders — checked by opening the file, not by reading the markup
- [ ] Primary action is visually the most prominent element
- [ ] Empty, loading and error states present or explicitly scoped out
- [ ] Mobile and desktop shown (if applicable) and the differences annotated
- [ ] Every non-obvious behavior is annotated, and every note has a marker on the thing it describes (or says why it cannot)
- [ ] Each marker's `data-note` matches its note's position in `<ol id="wf-notes">`, checked by hovering at least one marker in a real browser — a wrong index shows the wrong note, which reads as a correct annotation
- [ ] Open questions are under `OPEN QUESTIONS` in the metadata comment, not buried among the notes, and are repeated in your report
- [ ] Realistic content, including a long-value and an empty-value case
- [ ] HTML is valid and semantic

Then report back briefly: the file path, what the wireframe covers, how it connects to the rest of the set (what links in, what it leads to), the key structural decisions you made, and the open questions the user should answer.