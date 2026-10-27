# State and data

## Contents
1. Classify the state first
2. Shaping local state
3. Context
4. Server data
5. URL state
6. Forms and Actions
7. Optimistic updates

## 1. Classify the state first

Different kinds of state have different homes. Mixing them (e.g. copying server data into a global store) is a top source of staleness bugs.

| Kind | Example | Home |
|---|---|---|
| Derived | filtered list, totals, `isValid` | computed during render |
| UI / local | open/closed, hovered, input draft | `useState` / `useReducer` in the lowest component that needs it |
| Shared client | theme, auth user, cart in an SPA | lifted state, Context, or the project's store |
| Server cache | lists, records from an API | framework loader, Server Component, or query library (TanStack Query, SWR, RTK Query…) |
| URL | filters, tab, page, search query, selected id | route params / search params |
| Form | field values, validation | native form + Actions, or the project's form library |

Ask "should this survive a reload or be shareable as a link?" → URL. "Does it come from the server and can go stale?" → server cache. Otherwise local, lifted only as needed.

## 2. Shaping local state

- Group values that always change together into one object; split values that change independently.
- Avoid contradictory booleans (`isLoading` + `isError` + `isSuccess`); use a single status union.
- Avoid redundancy (storing both `items` and `selectedItem`): store the id, derive the object.
- Avoid deep nesting; normalize into `byId` maps if updates get awkward.
- Move to `useReducer` when there are many event types updating the same state, or when the next state depends on several pieces of current state. Reducers are pure and easy to unit test.
- Lazy initialisation for expensive initial values: `useState(() => parse(raw))`, not `useState(parse(raw))`.
- Don't initialise state from a prop and expect it to follow the prop. Either the component is controlled (use the prop directly), or the prop is explicitly an initial value (name it `initialX`/`defaultX`) and the parent uses `key` to reset.
- Values that don't affect rendering (timer ids, previous values for imperative APIs, DOM nodes) go in `useRef`, not state.

## 3. Context

Context is dependency injection, not a performance-friendly global store.

- Every consumer re-renders when the provided value changes. Keep provided values stable (state values directly, or an object memoized if not using the Compiler) and split unrelated concerns into separate contexts — often state and actions/dispatch separately.
- Provide a typed custom hook (`useCart()`) that throws a clear error when used outside the provider.
- For frequently-changing values read by many components (cursor position, large client stores), prefer a store with selector subscriptions (the project's library, or `useSyncExternalStore`).
- In React 19 you can render `<CartContext value={...}>` and read with `use(CartContext)` (which, unlike `useContext`, may be called conditionally). On 18, use `.Provider` and `useContext`.

## 4. Server data

Order of preference:

1. **Server Components** (RSC frameworks): fetch on the server where the data is needed; pass results down.
2. **Framework loaders** (React Router/Remix loaders, Next.js data APIs).
3. **A query library** for client fetching: caching, dedup, retries, refetch on focus, invalidation after mutations.
4. **`useEffect` fetch** — last resort, with race handling (see `effects.md`).

Watch for **waterfalls**: a parent awaits data, renders a child, the child then starts its own fetch. Start independent requests in parallel at the highest sensible point (loader, page Server Component, or parallel queries), then pass promises or data down. Child components can read passed-in promises with `use()` inside a Suspense boundary (19+). Don't create the promise during a Client Component render — it's recreated each render; create it on the server, in a loader, or in a cache.

After a mutation, invalidate or revalidate the relevant cache (query invalidation, `revalidatePath`/`revalidateTag`, loader revalidation) rather than hand-editing several copies of data.

## 5. URL state

Filters, sorting, pagination, tabs and selected items usually belong in the URL: shareable, survives refresh, works with back/forward. Read them through the router's APIs (or a helper such as `nuqs` if the project uses it) and treat the URL as the single source of truth — don't mirror it into `useState` and sync with an effect.

## 6. Forms and Actions

- Uncontrolled inputs with `name` + `FormData` are fine and often simpler; use controlled inputs when the UI must react to each keystroke (live validation, formatting, dependent fields).
- With React 19, a `<form action={fn}>` runs `fn(formData)` in a transition; `useActionState` gives you the last result and a pending flag; `useFormStatus` (from `react-dom`) lets a submit button inside the form read pending state. In RSC frameworks the action can be a Server Action, which also works before hydration (progressive enhancement).
- Uncontrolled fields in a form submitted via `action` are reset after a successful action; return the submitted values from the action if you need to re-populate on error.
- If the project uses a form library (React Hook Form, TanStack Form, Formik), follow its patterns instead of mixing approaches in one form.
- Validate on the server regardless of client validation. Show field errors next to fields and associate them (`aria-describedby`), and disable or mark pending the submit button.

```tsx
function SubscribeForm() {
  const [state, formAction, isPending] = useActionState(subscribe, { error: null });
  return (
    <form action={formAction}>
      <label htmlFor="email">Email</label>
      <input id="email" name="email" type="email" required aria-describedby="email-error" />
      {state.error && <p id="email-error" role="alert">{state.error}</p>}
      <button disabled={isPending}>{isPending ? 'Subscribing…' : 'Subscribe'}</button>
    </form>
  );
}
```

## 7. Optimistic updates

`useOptimistic` (19+) shows a provisional value while an action is pending and falls back automatically when it settles. Query libraries offer their own optimistic patterns — use whichever matches the data layer. Always handle failure visibly; a silently reverted change is confusing.
