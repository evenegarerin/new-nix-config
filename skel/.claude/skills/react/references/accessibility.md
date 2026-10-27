# Accessibility in React

Target WCAG 2.2 AA unless the project states otherwise. Most of accessibility is just correct HTML; React adds a few specific pitfalls around focus, IDs, and dynamic updates.

## Contents
1. Semantic elements first
2. Names and labels
3. IDs
4. Focus management
5. Announcing dynamic changes
6. Custom widgets
7. Motion and visual concerns
8. Tooling

## 1. Semantic elements first

- Actions are `<button type="button">` (or `type="submit"` in forms); navigation is `<a href>` / the router's `Link`. A `<div onClick>` is not keyboard-focusable, has no role, and doesn't respond to Enter/Space.
- Use headings in order, landmarks (`<main>`, `<nav>`, `<header>`, `<footer>`), lists for lists, `<table>` for tabular data.
- Prefer native controls (`<select>`, `<input type="checkbox">`, `<dialog>`, `<details>`) when they meet the design need.
- Fragments help avoid wrapper `div`s that break semantics (e.g. extra elements inside `<ul>` or `<tr>`).

## 2. Names and labels

- Every form control has a visible `<label htmlFor>` (or wraps the input). Placeholders are not labels.
- Icon-only buttons need `aria-label` (or visually hidden text); decorative icons get `aria-hidden="true"`.
- Images: meaningful `alt`, or `alt=""` for decorative ones.
- Link text should make sense on its own ("View invoice #123", not "click here").
- Associate help and error text with `aria-describedby`; mark invalid fields with `aria-invalid`.

## 3. IDs

Use `useId()` to generate IDs for `htmlFor`, `aria-describedby`, `aria-labelledby`, `aria-controls`. It's stable across server and client and unique per component instance. Don't hard-code IDs in reusable components (duplicates when rendered twice) and never use random values (hydration mismatch). `useId` is not for list keys.

## 4. Focus management

Single-page apps break the browser's default focus behaviour, so handle it explicitly:

- **Dialogs/modals**: move focus into the dialog on open, trap it while open, close on Escape, return focus to the trigger on close, make the background inert. Native `<dialog>` with `showModal()` or the project's dialog primitive does most of this.
- **Client-side route changes**: move focus to the new page's main heading or container, or rely on the framework's route announcer if it has one.
- **Content that appears after an action** (inline editor, revealed panel): focus the first relevant control.
- **Deleting the focused item**: move focus to a sensible neighbour, not `<body>`.
- Use a ref and call `.focus()` in the event handler or a ref callback — not via an effect keyed to a boolean, when avoidable.
- Never remove the focus outline without a visible replacement (`:focus-visible` styles).

## 5. Announcing dynamic changes

Screen reader users don't see async results appear. Use a live region that **exists in the DOM before** the message changes:

- `role="status"` (polite) for "Saved", "12 results", loading done.
- `role="alert"` (assertive) for errors that need immediate attention.

Don't mount the live region together with its message; it often won't be announced. Keep one region and update its text.

## 6. Custom widgets

Tabs, menus, comboboxes, listboxes, tree views, date pickers, and tooltips have specific keyboard and ARIA contracts (WAI-ARIA Authoring Practices). Hand-rolled versions are usually wrong. Use the project's headless library (Radix, React Aria, Headless UI, Ariakit, shadcn/ui built on them). If you must build one, follow the APG pattern exactly: roles, `aria-expanded`/`aria-selected`/`aria-activedescendant`, roving `tabIndex`, arrow-key handling.

ARIA rule of thumb: no ARIA is better than wrong ARIA. Don't add `role="button"` to a `<div>` when a `<button>` works.

## 7. Motion and visual concerns

- Respect `prefers-reduced-motion` for non-essential animation.
- Don't convey information by colour alone; ensure text contrast (4.5:1 for body text).
- Interactive targets should be comfortably sized (24×24 CSS px minimum per WCAG 2.2).
- Content must work at 200% zoom and in narrow viewports without horizontal scrolling for text.

## 8. Tooling

- `eslint-plugin-jsx-a11y` catches many static issues — enable it if the project has it.
- Test with `@testing-library` role queries (`getByRole('button', { name: /save/i })`): if the query can't find it, assistive tech likely can't either.
- `axe-core` (e.g. `vitest-axe`/`jest-axe`, `@axe-core/playwright`) for automated checks in tests.
- Automated tools catch only part of the issues. For important flows, do a quick keyboard-only pass: Tab through, operate everything, check focus visibility and order.
