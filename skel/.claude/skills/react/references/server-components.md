# Server Components, Server Actions, SSR and hydration

Only applies in RSC-capable setups (e.g. Next.js App Router, React Router / other frameworks with RSC enabled). In a Vite SPA or Next.js Pages Router there are no Server Components — don't add `"use client"`/`"use server"` there.

## Contents
1. Mental model
2. Placing the client boundary
3. What may cross the boundary
4. Data fetching on the server
5. Server Actions and security
6. Hydration mismatches
7. Common mistakes

## 1. Mental model

- Server Components render on the server (at build or request time), may be `async`, can read databases/files/secrets directly, and ship no JS for themselves. They can't use state, effects, event handlers, or browser APIs.
- Client Components are the familiar React components. They are pre-rendered to HTML on the server too (SSR) and then hydrated in the browser.
- `"use client"` marks a **module as an entry point into the client bundle**. Everything that module imports becomes client code too. It is not "this component runs only in the browser".
- `"use server"` marks **Server Functions** (callable from the client, typically as Actions). It does not mark Server Components — those are the default and need no directive.

## 2. Placing the client boundary

Push `"use client"` down to the leaves that need interactivity. A page that is mostly static with one interactive button should be a Server Component that renders a small client `<LikeButton>`.

Client Components can still render Server Components that are passed in as `children` or other props:

```tsx
// Server Component
<ClientTabs>
  <ServerRenderedPanel />   {/* stays a Server Component */}
</ClientTabs>
```

Providers (theme, query client) are usually a small `"use client"` wrapper that receives `children` — the children remain server-rendered.

Mark modules that must never reach the client with the `server-only` package when the framework supports it, and client-only modules with `client-only`.

## 3. What may cross the boundary

Props passed from a Server Component to a Client Component are serialized. Allowed: primitives, plain objects/arrays, `Date`, `Map`/`Set`, typed arrays, promises, JSX, and Server Functions. Not allowed: regular functions, class instances, symbols that aren't globally registered.

- Pass only the fields the client needs. Everything passed is sent to the browser — **never pass secrets, tokens, or full database rows with private columns**. Map to a DTO.
- Avoid sending the same large data twice (e.g. both a list and a sorted copy); derive on the client if cheap.

## 4. Data fetching on the server

- Fetch in the Server Component that needs the data; deduplicate repeated reads within one request with `cache()` (React) or the framework's built-in request memoization.
- Start independent fetches in parallel rather than awaiting one after another; nested async components that each await create waterfalls. Lift the starts up, or pass promises down and read them with `use()` under Suspense.
- Wrap slow parts in `<Suspense>` so the rest of the page streams first.
- Don't keep per-request data in module-level variables; the module is shared across requests and users.
- `cacheSignal()` (19.2) lets you abort work tied to a `cache()` entry once the render no longer needs it.

## 5. Server Actions and security

A Server Function is a **public HTTP endpoint**, whether or not your UI exposes the button. Treat it like an API route:

- Authenticate and authorize **inside** the function, every time. Don't rely on the page that renders the form having checked.
- Validate and parse all arguments (e.g. with the project's schema library). `FormData` and arguments are attacker-controlled.
- Don't trust IDs from the client to imply ownership — verify the resource belongs to the user.
- Return serializable, minimal results (errors for display, not stack traces).
- Revalidate the affected data after mutating (framework APIs like `revalidatePath`/`revalidateTag`, or redirect).
- Keep the React/framework RSC packages patched; several critical RSC vulnerabilities were fixed in late-2025 patch releases. If the project is on an older 19.x with RSC, flag it.

## 6. Hydration mismatches

The HTML rendered on the server must match the first client render. Common causes and fixes:

- **Browser-only values in render** (`window`, `localStorage`, `matchMedia`, `navigator`): read them through `useSyncExternalStore` with a `getServerSnapshot`, or render a stable placeholder first and update after mount. Don't branch on `typeof window` during render.
- **Time and randomness** (`new Date()`, `Math.random()`): compute on the server and pass down, or render on client only. For a single text node like a timestamp that legitimately differs, `suppressHydrationWarning` on that element is acceptable — not as a blanket fix.
- **IDs**: use `useId`, never counters or random values.
- **Invalid HTML nesting** (`<div>` inside `<p>`, `<a>` inside `<a>`, missing `<tbody>`): browsers repair it, causing mismatches. Fix the markup.
- **Locale/timezone formatting differences** between server and client: format with an explicit locale/timezone or format on one side only.
- **Browser extensions** modifying the DOM can cause warnings you can't fix; don't chase those.

For a theme flash (dark mode), set the class with a tiny inline script before hydration or via a cookie read on the server — not with an effect after mount.

## 7. Common mistakes

- Adding `"use client"` to a page/layout to fix one hook, turning a whole tree into client code.
- Importing a server-only module (DB client, secrets) from a client module — it either fails or leaks.
- Passing event handlers from a Server Component to a Client Component (not serializable). Define the handler in the client component or pass a Server Function.
- Using context in a Server Component (not supported; move the consumer to a client component).
- Calling a Server Action from an effect on mount to "load data" — fetch in the Server Component instead.
- Awaiting everything at the top of a page so nothing streams.
