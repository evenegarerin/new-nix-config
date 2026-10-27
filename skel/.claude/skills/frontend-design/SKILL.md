---
name: frontend-design
description: Design and build distinctive, production-quality web interfaces, and review or polish existing ones. Use this skill whenever a task creates or restyles anything people will look at in a browser — landing pages, marketing sites, app screens, dashboards, admin tools, settings pages, forms, components, prototypes, HTML/CSS/JSX/Tailwind UI, design tokens or a design system — and whenever the user says a UI "looks generic", "looks AI-made", "make it look better/nicer/more polished", or asks for a design critique or UI audit, even if they never use the word "design".
---

# Frontend Craft

Left alone, a model designs the median of its training data: the same hero, the same three cards, the same palette, the same fade-up on every section. The output is competent and forgettable, and people now recognise it on sight. This skill exists to replace defaults with decisions, to hold every build to a quality floor, and to make you look at what you built before calling it done.

The workflow has eight steps. Small tasks (one component, a quick fix) can compress steps 2–3 into a couple of sentences, but never skip step 0 or step 7.

0. Read what already exists
1. Pick the register: brand or product
2. Write a short design plan
3. Run the default check on the plan
4. Build
5. Design every state, not just the happy path
6. Hold the quality floor
7. Look at it, critique it, fix it
8. Record the decisions

---

## 0. Read what already exists

Before forming any opinion, look at the project. Search for: a `DESIGN.md` or similar design notes, CSS custom properties, `tailwind.config.*` or `@theme` blocks, a `components/` or `ui/` folder, existing pages, fonts already loaded, brand assets.

- **If there is an established system, extend it.** Reuse its tokens, components, spacing and voice. A new page should look like it was always part of the app. An imported aesthetic bolted onto an existing product is the most common way a "well-designed" page ends up wrong.
- **If the user's brief names a look, follow it exactly**, even if it is one of the clichés listed below. Their words always win over this skill's preferences.
- **If there is nothing**, you are designing from scratch: continue to step 1.
- **If the subject is vague** ("make a landing page"), propose one concrete subject, audience and primary job, state it, and proceed (or confirm, if you can ask). Distinctive choices come from the subject's world — its materials, vocabulary, history, the places it happens. A vague subject produces a generic page no matter how good the rules are.

## 1. Pick the register: brand or product

Most bad UI comes from applying the right rules to the wrong kind of surface. Decide which register you're in; it changes nearly every downstream choice.

| | **Brand** (landing, marketing, portfolio, campaign, editorial) | **Product** (app, dashboard, admin, tool, settings, internal) |
|---|---|---|
| Job of design | Is the product; creates identity and desire | Serves the task; disappears into use |
| First screen | One composition, like a poster | The working surface itself — no hero |
| Type | Expressive, display sizes, can carry personality | Calm, legible, dense, consistent |
| Color | Can be committed or drenched | Mostly neutral; color reserved for action and status |
| Copy | Short, evocative but concrete | Utility: says what this is and what you can do |
| Motion | A few memorable moments | Feedback on actions; almost nothing ambient |
| Density | Generous space, few elements | As dense as is still readable |

Then read the matching reference file before building:
- Brand → `references/brand.md`
- Product → `references/product.md`

A product's marketing site and its app are two registers. Treat them separately even within one repo.

## 2. Write a short design plan

Write this down (in your response or a scratch note) before writing code. Changing a plan costs a sentence; changing 400 lines of CSS costs an afternoon.

- **Subject, audience, job.** One line each.
- **Thesis.** One sentence describing the mood, material and energy. ("A tide-table app that feels like a well-worn nautical almanac: inky, precise, quietly confident.")
- **Dials.** Set three dials from 1–5 and let them constrain choices:
  - *Density* — how much is on screen at once.
  - *Motion* — how much moves without the user asking.
  - *Departure* — how far from convention the layout goes.
  A banking dashboard might be 4/1/1; a gallery portfolio 1/3/5. Dials stop every project from landing at 3/3/3.
- **Tokens.**
  - Color: 4–6 named values (background, surface, text, muted text, accent, plus one if needed), with the role of each.
  - Type: one or two families with their roles, a scale (pick a ratio ≥1.2 and stick to it), weights in use.
  - Space: a base unit and scale. Radius: a scale tied to hierarchy, not one value everywhere. Elevation: whether shadows exist at all.
- **Layout.** A one-sentence concept plus a rough ASCII wireframe for the key screen. If you're unsure, sketch two and compare.
- **Signature.** The one thing someone will remember. Spend your boldness here and keep everything around it quiet.

## 3. Run the default check

Generated design currently converges on a handful of looks. All are legitimate for some briefs; the problem is that they show up regardless of the brief. Recognise them in your plan:

- **The SaaS kit:** centered hero with a gradient wash, a big number with small labels, three or four identical rounded cards with the same soft shadow, one radius on everything, logo cloud, purple-to-blue accents.
- **The warm editorial:** cream or parchment background, high-contrast serif display, a burnt orange or clay accent.
- **The dark terminal:** near-black background, a single acid green / electric accent, monospace labels everywhere.
- **The broadsheet:** hairline rules, zero radius, dense newspaper columns, numbered sections.
- **Template chrome** that appears on any subject: tracked-out all-caps eyebrow above every heading; one word of the headline in italic or accent color; `A · B · C` meta strings; `01 / 02 / 03` numbering on things that aren't a sequence; arrows appended to every link; glassmorphism as decoration; gradient text; colored side-stripe borders on cards; fake-precision stats ("99.97% uptime", "10x faster") that nobody supplied.

**The similar-brief test:** imagine a different but similar brief (another product in the same category). Would your plan come out roughly the same? Then those parts are defaults, not decisions. Revise them and note what changed and why.

**Don't just swap one default for the next.** A banned-font list only moves the cluster: ban the most common sans and everything converges on the second-most-common one. Choose every typeface, color and layout for a reason you can say in a sentence that refers to *this* subject.

Over-correction is also a failure. A dashboard does not need a dramatic asymmetric layout to avoid looking generic; conventions exist because they work. Depart from convention where it serves the thesis, not to prove a point.

## 4. Build

### Composition before components
Arrange the page with scale, alignment, whitespace, cropping and contrast first. Add chrome (borders, boxes, shadows, badges) only when the layout genuinely needs it. If removing a card's border, background and shadow doesn't hurt understanding or interaction, it shouldn't be a card. Cards nested in cards are always wrong.

### Typography
- Type carries most of the personality. Treat a display headline as a visual element, not a container for words.
- One or two families. If two, make them clearly different in role and form.
- Body text 16px minimum on the web; line length about 45–75 characters; serif body slightly more line-height than sans.
- Set a real scale and use it; avoid arbitrary in-between sizes.
- Use `font-variant-numeric: tabular-nums` wherever numbers align or update (tables, prices, timers, stats).
- Use real typographic characters in copy: curly quotes, apostrophes, proper ellipsis `…`, en dashes in ranges.
- Load fonts responsibly: `font-display: swap`, a fallback stack with similar metrics, only the weights you use.

### Color
- Define every color as a CSS custom property; components never reference raw hex values.
- Name tokens by role (`--surface`, `--text-muted`, `--accent`), not by hue (`--blue-500`) at the component level.
- Consider OKLCH for building scales — equal lightness steps look evenly spaced, unlike HSL.
- Tint your neutrals slightly toward the palette's hue; pure grey next to a saturated accent looks dead.
- One accent by default. Color should signal something (action, state, selection), not decorate.
- Never put grey text on a colored background; derive a tint of that background instead.
- Dark mode is a second set of token values (via `prefers-color-scheme` and/or a `data-theme` attribute), not a filter. Dark surfaces get lighter as they elevate; reduce saturation of accents slightly.
- Don't pick light or dark by habit. Ask where and when this is used: a recipe app at a bright kitchen counter and a DJ tool in a club want different answers.

### Space and layout
- Use the spacing scale only. Vary spacing deliberately to create rhythm and grouping — tighter within groups, looser between them. Uniform padding everywhere flattens hierarchy.
- Use CSS grid and flexbox, `gap` over margins, logical properties where it matters, `min()`/`clamp()` for fluid sizing.
- Prefer container queries for components that live in different-width slots.
- Mind selector specificity: a type selector and a class selector fighting over padding is a classic source of inconsistent section spacing. Keep specificity flat.

### Imagery and content
- Use real or realistic content from the brief. Write believable copy; never ship lorem ipsum, invented testimonials presented as real, or statistics nobody gave you. If a number is needed and unknown, use an obviously placeholder value and say so.
- Images should do narrative work: show the product, the place, the people, the context. Abstract gradients and blobs are not a visual idea.
- Don't hotlink random web images. Use assets the user provided, generated ones if tooling exists, or tasteful placeholders that are clearly placeholders.
- Choose or crop images with a calm area for overlaid text, and guarantee contrast with a scrim if needed.

### Motion
- Motion that responds to the user (open, expand, confirm, reorder) is welcome when it shows what changed.
- Ambient motion is a budget, set by the motion dial. One orchestrated moment beats a fade-and-slide on every section and a hover lift on every card.
- Animate `transform` and `opacity`; avoid animating `width`, `height`, `top`, `left` or anything that triggers layout.
- Use ease-out curves for entrances (things arriving decelerate); keep durations roughly 150–300ms for UI feedback, longer only for deliberate set pieces. Avoid bouncy/elastic easing on serious products.
- Always honor `prefers-reduced-motion: reduce` with a near-instant or static alternative.

### Code hygiene that affects design
- Semantic HTML first: `button` for actions, `a` for navigation, real headings in order, `label` for every input, landmarks (`header`, `nav`, `main`, `footer`).
- Fixed and floating elements must never cover content or controls at any viewport size.
- Follow the repo's existing framework and conventions; don't introduce a new styling approach into a codebase that has one.

## 5. Design every state, not just the happy path

The screenshot in the brief is one state of many. Real users meet the others first. For each screen or component, decide what happens with:

- **Empty**: first run, no results, cleared filters. Make it an invitation to act, with the action right there.
- **Loading**: skeletons that match the final layout (to avoid shifts), or a spinner only for short waits; never a blank screen.
- **Error**: say what happened, why if known, and how to fix it. Keep user input; never wipe a form on failure.
- **Partial / many**: one item, hundreds of items, a very long name, a missing image, a 40% longer translation.
- **Interaction states**: hover, focus-visible, active, disabled (with a reason when possible), selected, pending.
- **Destructive actions**: confirmation or, better, undo.

## 6. Hold the quality floor

Build to this floor without announcing it. Full checklist in `references/quality-floor.md`; the essentials:

- Responsive from ~360px to wide desktop; no horizontal page scroll; wide content (tables, code) scrolls inside its own container.
- Visible keyboard focus on everything interactive; logical tab order; no keyboard traps.
- Text contrast at least WCAG AA (4.5:1 body, 3:1 large text and UI parts). Don't use color alone to carry meaning.
- Touch targets at least 44×44px on touch layouts.
- Full-height heroes account for sticky headers and mobile browser chrome (use `svh`/`dvh`, subtract header height).
- Form inputs have the right `type`, `inputmode` and `autocomplete`.
- Images have dimensions (no layout shift) and meaningful `alt` (or empty `alt` if decorative).
- Meaningful state lives in the URL (tabs, filters, search, pagination) so it survives reload and can be shared.

## 7. Look at it, critique it, fix it

Writing UI blind is the biggest weakness of any design guidance. If your environment has a browser tool (Playwright, Puppeteer, a preview, a screenshot MCP), use it — this step matters more than any rule above.

1. Render and screenshot at roughly 390px, 768px and 1440px wide. Check light and dark if both exist.
2. Compare the screenshots against your plan: are the tokens, layout and signature actually there, or did the build drift back to defaults?
3. Tab through the page with the keyboard. Trigger at least one empty, error and loading state.
4. Ask the litmus questions:
   - Could this belong to a different product if you removed the name? Then it isn't specific enough.
   - Can someone understand the page by reading only headings, labels and numbers?
   - Does each section or region have exactly one job?
   - Is every card, border, badge and icon earning its place?
   - Does every motion clarify something?
   - What is the one thing someone will remember?
5. Remove one accessory: find the least necessary decoration and delete it.
6. Fix what you found, then screenshot again.

If you cannot render, say so plainly, do a careful code-level review against this checklist instead, and suggest the user check specific things (named viewports, states) in a browser.

## 8. Record the decisions

When you've designed something new (not for one-off components), write or update a `DESIGN.md` in the project root, unless one exists elsewhere. Keep it short:

- Register, thesis and dials
- Tokens (or a pointer to where they live) with the reason for each key choice
- Type scale and spacing scale
- Patterns: when to use cards, how sections are spaced, motion rules
- Voice and terminology (the words the interface uses for its things)
- Things tried and rejected, and why

Future sessions and other agents read this file in step 0 and stay consistent instead of reinventing the system every time.

---

## Writing in the interface

Words are part of the design. Every label, button and message should make the interface easier to understand or use.

- Name things the way users think of them, not how the system is built ("Notifications", not "Webhook config").
- Buttons say exactly what happens: "Save changes", "Send invoice", not "Submit" or "OK". Keep the verb through the flow: the "Publish" button produces a "Published" confirmation.
- Sentence case for UI text. Plain verbs. No filler, no exclamation marks in errors, no apologising.
- One job per piece of copy. If deleting a third of the copy makes the page better, keep deleting.
- Never put prompt language or design commentary into the UI ("A bold, modern hero section that…").
- Product UI uses utility copy: what this is, what state it's in, what you can do. If a sentence could appear in an ad, rewrite it.

## When asked to review or polish existing UI

Don't redesign unprompted. Report first, then fix what's asked.

1. Read the code (and screenshot it if possible).
2. List findings grouped by severity — **blocking** (broken, inaccessible, unusable), **important** (hierarchy, consistency, missing states), **polish** (spacing, type details, motion).
3. For each finding: where (file and line, or the screen region), what's wrong, why it matters, and the concrete fix.
4. Note what's already good, so it isn't changed by accident.
5. Apply fixes in severity order, staying inside the existing system.
