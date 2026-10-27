# Quality floor checklist

Run through this before calling any UI done. These are the details that separate shippable work from a demo. Most are invisible when right and painful when wrong.

## Contents
1. Accessibility
2. Responsive and viewport
3. Typography details
4. Forms and input
5. Navigation and state
6. Performance and stability
7. Motion
8. Theming
9. Content resilience

## 1. Accessibility
- [ ] Semantic elements: `button` for actions, `a href` for navigation, headings in order without skipped levels, landmarks present.
- [ ] Every input has a visible `label` (placeholders are not labels).
- [ ] `:focus-visible` styles on every interactive element, clearly visible on every background.
- [ ] Logical tab order; dialogs trap focus while open and return it on close; `Esc` closes them.
- [ ] Contrast: 4.5:1 for body text, 3:1 for large text, icons and control boundaries.
- [ ] Color is never the only signal (errors also have text or an icon; links are distinguishable without color where in body text).
- [ ] Icon-only buttons have an accessible name (`aria-label` or visually hidden text).
- [ ] Images: meaningful `alt`, or `alt=""` for decorative ones.
- [ ] Dynamic updates that matter (form errors, toasts) are announced (`aria-live` or a live region).
- [ ] Respects `prefers-reduced-motion`.
- [ ] Page still works at 200% browser zoom.

## 2. Responsive and viewport
- [ ] Works from ~360px to 1920px+. No horizontal page scroll at any width.
- [ ] Wide content (tables, code blocks, diagrams) scrolls inside its own `overflow-x: auto` container.
- [ ] Touch targets ≥44×44px on touch layouts, with enough space between them.
- [ ] Full-height sections use `svh`/`dvh` and account for sticky headers.
- [ ] Fixed/floating elements (chat bubbles, cookie bars, sticky CTAs) never cover content or other controls.
- [ ] `viewport` meta present; safe-area insets respected on notched devices for fixed elements.
- [ ] Hover-only interactions have a touch equivalent.

## 3. Typography details
- [ ] Body text ≥16px; line length ~45–75ch.
- [ ] `tabular-nums` for numbers in tables, prices, timers, counters.
- [ ] Curly quotes and apostrophes, real ellipsis `…`, en dash in ranges (`9–5`), non-breaking space between number and unit where it matters.
- [ ] No orphaned single words on key headlines where avoidable (`text-wrap: balance` for headings, `pretty` for paragraphs).
- [ ] Long words and URLs can't break the layout (`overflow-wrap: anywhere` where needed).

## 4. Forms and input
- [ ] Correct `type` (`email`, `tel`, `url`, `number`, `search`) and `inputmode`.
- [ ] `autocomplete` attributes for names, emails, addresses, passwords, one-time codes.
- [ ] Submit with Enter where expected; button disabled only while submitting, with visible progress.
- [ ] Errors next to fields, specific and actionable; input preserved on failure.
- [ ] No paste-blocking on password or code fields.

## 5. Navigation and state
- [ ] Meaningful UI state in the URL: tabs, filters, search query, sort, pagination, open detail item.
- [ ] Back button does what the user expects.
- [ ] Links are links (middle-click / cmd-click opens a new tab).
- [ ] Current location indicated in navigation (`aria-current="page"`).
- [ ] Unsaved changes warn before navigating away.

## 6. Performance and stability
- [ ] Images have `width`/`height` or `aspect-ratio` (no layout shift); below-the-fold images `loading="lazy"`; modern formats where possible.
- [ ] Fonts: `font-display: swap`, preload the critical one, only weights actually used, metric-compatible fallback.
- [ ] Skeletons match final layout to avoid content jumps.
- [ ] Animations only on `transform`/`opacity`; no animating layout properties; no scroll handlers doing heavy work (use `IntersectionObserver` or CSS scroll-driven animations).
- [ ] Large lists virtualized when they reach hundreds of rows.

## 7. Motion
- [ ] Every animation has a purpose (feedback, orientation, attention).
- [ ] Entrances ease out; exits are quicker than entrances.
- [ ] UI feedback roughly 150–300ms; nothing blocks interaction while animating.
- [ ] Reduced-motion alternative exists.

## 8. Theming
- [ ] All colors come from tokens; no stray hex values in components.
- [ ] If dark mode exists: tokens redefined, not inverted; images and shadows checked; `color-scheme` set so form controls and scrollbars match.
- [ ] Focus rings, borders and disabled states visible in both themes.

## 9. Content resilience
- [ ] Very long names, titles and numbers tested.
- [ ] Translations ~30–40% longer don't break buttons or nav.
- [ ] Missing image, missing avatar, zero-value, null and error data all render sensibly.
- [ ] Empty, loading and error states exist for every data-driven region.
