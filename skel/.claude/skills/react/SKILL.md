---
name: react
description: Best practices for writing, reviewing, refactoring and debugging React code (components, hooks, state, effects, forms, data loading, Server Components, performance, accessibility, tests). Use this skill whenever a task touches .jsx/.tsx files, React components or hooks, Next.js / React Router / Remix / Vite React apps, or React bugs such as stale state, infinite re-renders, lost input focus, hydration mismatches or flickering — even if the user never says "best practices". Also use it before adding any useEffect, useMemo/useCallback, Context, or a new state library.
---

# React

Guidance for producing React code that is correct first, idiomatic second, and fast third. General JavaScript/TypeScript rules live in a separate skill; this one covers only what is specific to React.

## Workflow

### 1. Inspect the project before writing code

Most React advice online silently assumes one setup (usually "React 19 + Next.js + React Compiler"). Applying the wrong assumptions produces code that doesn't compile, fights the codebase, or quietly regresses performance. Spend a minute checking:

- **React version** (`package.json` → `react`, `react-dom`). This decides which APIs exist. See the version table below.
- **Framework and rendering model**: Next.js App Router (`app/` dir) vs Pages Router, React Router / Remix framework mode, Vite SPA, Expo/React Native. Server Components only exist in RSC-capable frameworks.
- **React Compiler**: look for `babel-plugin-react-compiler`, `reactCompiler: true` in `next.config.*`, or the compiler in the Vite/Babel config. Its presence changes the memoization advice (see Performance).
- **Libraries already in use** for data fetching (TanStack Query, SWR, RTK Query, Apollo, framework loaders), state (Zustand, Redux, Jotai…), forms (React Hook Form…), styling, and component primitives (Radix, React Aria, shadcn/ui…).
- **Conventions**: open two or three neighbouring components and copy their file layout, naming, export style, prop typing and test style.
- **Tooling**: lint config (is `eslint-plugin-react-hooks` on?), typecheck command, test runner.

Use what the project already has. Do not add a new library, state manager or pattern family without saying why and asking first.

### 2. Write the code using the principles below

Load a reference file when the task goes deep into its area:

| Task involves | Read |
|---|---|
| Any `useEffect` / `useLayoutEffect`, syncing, subscriptions, "run on mount", fetching in a component | `references/effects.md` |
| Where state lives, derived values, forms, server data, URL state, Context | `references/state-and-data.md` |
| Component API design, props, children, compound components, refs, error boundaries | `references/components.md` |
| `"use client"`, `"use server"`, Server Components, Server Actions, hydration, SSR | `references/server-components.md` |
| Slowness, re-renders, memo/useMemo/useCallback, Compiler, large lists, transitions, bundle size | `references/performance.md` |
| Interactive widgets, forms, dialogs, focus, keyboard, screen readers | `references/accessibility.md` |
| Writing or fixing tests for components or hooks | `references/testing.md` |

### 3. Verify

Don't stop at "it looks right". Run what the project offers: the linter (the hooks rules catch real bugs), the typechecker, related tests, and, if a dev server is available, render the affected screen. If Strict Mode reveals a double effect run or a hydration warning appears, treat it as a bug report, not noise.

### 4. Self-review with the checklist at the bottom of this file.

## Version awareness

| Feature | Available from |
|---|---|
| `useId`, `useSyncExternalStore`, `useTransition`/`useDeferredValue`, automatic batching | 18 |
| Actions, `useActionState`, `useOptimistic`, `use()`, `useFormStatus` (react-dom), `ref` as a regular prop, `<Context>` as provider, `<title>`/`<meta>` hoisting, ref cleanup functions | 19 |
| `<Activity>`, `useEffectEvent`, `cacheSignal` (server) | 19.2 |
| React Compiler 1.0 (stable, works with 17/18/19) | build-tool opt-in |

On React 18 or older, don't emit 19-only APIs; use `forwardRef`, `Context.Provider`, and manual pending state. On 19+, `forwardRef` still works but isn't needed for new code. If a project uses Server Components on an early 19.x release, mention that late-2025 patch releases fixed critical security issues in the RSC packages and an upgrade is advisable.

When you are unsure whether an API exists in the installed version, check the installed package's types or changelog rather than guessing. Don't invent APIs.

## Core principles

### Render must be pure

Rendering is a calculation: same props, state and context in → same JSX out. During render, don't mutate props, state, or module-level variables, don't read or write refs (except lazy init), and don't trigger side effects (fetches, subscriptions, `setState` of another component, logging analytics). Side effects belong in event handlers first, effects second. Strict Mode double-renders in development specifically to expose impure renders, and the React Compiler assumes purity — impure code may break under it.

### Treat state as immutable snapshots

A state value is a snapshot for that render. Replace objects/arrays instead of mutating them, use the updater form (`setCount(c => c + 1)`) when the next value depends on the previous one, and remember that a variable read right after `setX` still holds the old value.

### Keep the minimum state; derive the rest

Before adding state, ask: can this be computed from props or existing state during render? If so, compute it. Duplicated state drifts out of sync and is the source of most "sync it with an effect" code. Prefer storing IDs over copies of objects, and prefer one status value (`'idle' | 'loading' | 'error' | 'success'`) over several booleans that can contradict each other.

### Effects are for synchronizing with external systems — nothing else

If you can't name the external system (DOM API, network connection, browser API, third-party widget, timer, subscription), you probably don't need an effect. Data transformations go in render; responses to user actions go in event handlers; resets go through `key`. See `references/effects.md` for the triage tree. This single rule prevents a large share of real-world React bugs.

### Colocate, then lift only as far as needed

State lives in the lowest component that needs it. Lift it to the closest common parent when siblings need it. Reach for Context only for values that many distant components read (theme, current user, locale) and for a feature's compound components — not as a general state manager. Server data is a cache, not app state: it belongs in the framework loader, a Server Component, or a query library.

### Compose instead of configuring

Prefer `children` and small composable parts over components with a growing list of boolean props (`showHeader`, `isCompact`, `withIcon`…). When a component sprouts modes, split it into explicit variants or a compound component. See `references/components.md`.

### Identity matters: types and keys

React decides whether to keep or reset state by component type and position, plus `key`.

- **Never define a component inside another component.** It's a new type every render, so its subtree remounts: inputs lose focus, state resets, effects re-run. Define components at module level and pass props.
- Give list items keys from the data (a stable ID). Index keys are fine only when the list is static — never reordered, filtered or inserted into — and items hold no state. Never generate keys during render (`Math.random()`, `crypto.randomUUID()`).
- Use `key` deliberately to reset a subtree: `<Profile key={userId} />`.

### Design for every state the UI can be in

For anything async, handle loading, error, empty and success. Use Suspense boundaries for loading and error boundaries for failures at meaningful granularity (a widget, a route segment), not one around the whole app only. Disable or mark pending UI during submissions so double submits are impossible.

### Accessible by default

Use the semantic element (`<button>`, `<a href>`, `<label>`, `<dialog>`, lists, headings) before reaching for `div` + handlers + ARIA. Every input has a label, every icon-only button has an accessible name, focus is managed when content appears or disappears. For complex widgets (combobox, menu, tabs, date picker) use the project's headless library rather than hand-rolling. Details in `references/accessibility.md`.

### Performance: correct first, then measure

Don't sprinkle `useMemo`/`useCallback`/`memo` by default. Fix structure first (state colocation, moving state down, passing `children`), measure with the Profiler, then memoize what's proven slow. If the React Compiler is enabled, rely on it and don't add manual memoization in new code. Big wins usually come from avoiding waterfalls, shrinking client bundles, and virtualizing long lists — not from micro-memoization. See `references/performance.md`.

## Outdated folklore to avoid repeating

Several popular React guides and skills still spread these. Don't follow them:

- *"Never create functions inline in JSX, it causes re-renders."* Inline handlers are normal. It only matters when the child is memoized and actually expensive — and the Compiler handles it anyway.
- *"Never use index as key."* Too absolute — see the rule above.
- *"Wrap everything in useMemo/useCallback."* Adds cost and noise; it's a targeted tool.
- *"`useEffect(fn, [])` means run once."* In development Strict Mode it runs, cleans up, and runs again. Write effects whose cleanup makes that safe; don't add `didRun` refs to suppress it.
- *"Swap to `useLayoutEffect` to fix the flicker"* as a general fix. It's only for measuring layout before paint; usually the real fix is not using an effect at all.
- *"Fetch data in `useEffect` + `useState`."* Acceptable only as a last resort and only with race-condition handling; prefer the framework or a query library.
- *"Always `import React from 'react'`."* Unnecessary with the modern JSX transform; follow the project's existing style.
- *"Class components for error boundaries are legacy, avoid classes."* Error boundaries still require a class (or a small library such as `react-error-boundary`).

## Final checklist

Before finishing, check the changed code against this list:

- [ ] Uses only APIs available in the installed React version; matches project conventions and libraries.
- [ ] Render is pure: no mutations, no side effects, no ref reads/writes during render.
- [ ] No state that could be derived; no effect that only transforms data or relays an event.
- [ ] Every remaining effect names its external system, has correct dependencies (no lint suppressions), and cleans up.
- [ ] Async work handles races/aborts, loading, error and empty states.
- [ ] No components defined inside components; list keys are stable IDs.
- [ ] Props API is small and composable; no boolean-prop pile-up.
- [ ] In RSC apps: `"use client"` placed as low as possible; props crossing the boundary are serializable; Server Actions authenticate and validate input.
- [ ] Semantic HTML, labelled controls, keyboard operable, focus handled.
- [ ] No speculative memoization; perf changes are justified by measurement or an obvious hot path.
- [ ] Lint, typecheck and relevant tests run (or you state which couldn't run and why).
