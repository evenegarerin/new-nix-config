# Performance

Order of impact in typical apps: request waterfalls and slow data > client bundle size > rendering huge amounts of DOM > unnecessary re-renders of expensive subtrees > everything else. Work in that order, and measure before and after.

## Contents
1. Measure
2. React Compiler
3. Manual memoization (no Compiler)
4. Structural fixes that beat memo
5. Keeping input responsive: transitions and deferred values
6. Large lists and heavy DOM
7. Hidden UI: `<Activity>`
8. Bundle size and code splitting

## 1. Measure

- React DevTools Profiler (record, look for components with long render times or many commits), "Highlight updates" to see what re-renders.
- React 19.2 adds React-specific Performance Tracks to Chrome DevTools' Performance panel.
- Test with a production build; dev builds and Strict Mode inflate costs.
- A re-render is not a problem by itself. It matters when it's expensive or causes visible lag.

## 2. React Compiler

If the project has the Compiler enabled (`babel-plugin-react-compiler`, `reactCompiler: true` in Next.js config, or equivalent):

- Don't add `useMemo`, `useCallback`, or `memo` in new code; the Compiler memoizes at a finer granularity. Leave existing manual memoization alone unless asked to clean it up — removing it can change effect dependency behaviour.
- Write code that follows the Rules of React (pure render, no mutation of props/state, hooks at top level). The Compiler skips components it can't prove safe; lint rules in recent `eslint-plugin-react-hooks` versions report these.
- `"use no memo"` at the top of a function opts it out — a temporary escape hatch for a known issue, not a pattern.
- Keep `useMemo`/`useCallback` where a stable identity is semantically required by an external API and you're not sure the Compiler covers it (e.g. a value used as an effect dependency that must not change).

If the Compiler is **not** enabled, don't assume it. You may suggest enabling it (official guidance: recommended for new apps; existing apps can start with the lint rules), but write code for the setup that exists.

## 3. Manual memoization (no Compiler)

Use it when it buys something measurable:

- `useMemo` for genuinely expensive calculations (sorting/filtering thousands of items, heavy formatting) or to keep an object/array identity stable when it's passed to a memoized child or used as an effect dependency.
- `useCallback` only when the function goes to a `memo` child or into an effect/hook dependency array.
- `memo(Component)` for components that are expensive and frequently re-rendered with the same props. It's useless if a prop is a new object/function every render — fix that or don't bother.
- Not worth it: cheap expressions, primitives, components that render little, handlers on DOM elements.
- Hoist static values (constant arrays/objects, default props like `items = EMPTY`) to module scope instead of memoizing them.

## 4. Structural fixes that beat memo

- **Move state down**: if only a small part reacts to typing/hovering, put that state in a small child so the big sibling doesn't re-render.
- **Lift content up via `children`**: a stateful wrapper that receives the expensive tree as `children` doesn't re-render it.
- **Split contexts** so frequent updates don't re-render every consumer; or use a store with selectors.
- **Subscribe narrowly**: don't read state in a component that only uses it inside a callback (read it at call time via the store/updater instead).
- **Updater functions** (`setItems(prev => …)`) remove state from callback dependencies and avoid stale closures.
- **Lazy state init**: `useState(() => expensive())`.
- **Never define components inside components** (forces remount, which is far worse than a re-render).

## 5. Transitions and deferred values

- `startTransition` / `useTransition` mark an update as non-urgent so urgent updates (typing, clicking) stay responsive. Use for tab switches, filtering a big list, navigation. `isPending` gives a cheap pending indicator. Controlled input values themselves must not be updated in a transition.
- `useDeferredValue(value)` lets an expensive child render with a lagging copy while the input stays immediate. Pair with `memo` on the expensive child (or the Compiler) so it actually skips work.
- Prefer these over debouncing for render cost; debouncing is still right for limiting network requests.
- Wrapping a Suspense-triggering update in a transition keeps the old UI visible instead of flashing a fallback.

## 6. Large lists and heavy DOM

- Virtualize lists of more than a few hundred rich rows (use the project's library — TanStack Virtual, react-window, etc.).
- Paginate or progressively load where virtualization isn't suitable.
- CSS `content-visibility: auto` can cheaply skip rendering work for off-screen sections of long static pages.
- Stable keys are a correctness and performance requirement for lists.
- Avoid rendering hidden content just to toggle it with CSS when it's expensive; but see `<Activity>` when you need to preserve state.

## 7. `<Activity>` (React 19.2+)

`<Activity mode="visible" | "hidden">` hides a subtree while keeping its state and DOM, unmounting its effects while hidden and rendering updates at low priority. Good for tabs, back-navigation caches, and pre-rendering likely next screens. Prefer it over `display: none` hacks when state preservation matters, and over conditional rendering when remounting is costly. Make sure effects clean up properly, since they will be torn down and recreated when visibility toggles.

## 8. Bundle size and code splitting

- Split heavy, rarely used UI (rich editors, charts, maps, admin panels) with `lazy()` + `Suspense`, or the framework's dynamic import helper. Trigger preload on hover/focus or route intent for perceived speed.
- In RSC apps, keep heavy libraries in Server Components when they only produce markup (markdown rendering, syntax highlighting, date formatting) so they never ship to the client.
- Import from specific entry points of large component/icon libraries if the bundler doesn't tree-shake their barrel files well; check the project's existing import style and bundler config first.
- Load third-party scripts (analytics, chat widgets) after hydration or via the framework's script component with a non-blocking strategy.
