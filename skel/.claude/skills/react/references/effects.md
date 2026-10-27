# Effects

An effect synchronizes a component with something outside React while the component is on screen. Most bugs around effects come from using them for things that are not synchronization.

## Contents
1. Triage: do I need this effect?
2. Replacements for common anti-patterns
3. Writing an effect that should exist
4. Fetching data when you must do it in an effect
5. `useEffectEvent` (19.2+)
6. `useLayoutEffect`
7. Red flags in review

## 1. Triage

Walk this list top-down; take the first match.

1. **The value can be computed from props/state** → compute it during render.
2. **It happens because the user did something** (click, submit, drag) → put it in the event handler.
3. **It loads data for the screen** → framework loader / Server Component / query library. If the user triggered it, start it from the handler.
4. **A child pushes data or state up to a parent via an effect** → lift the state, or fetch in the parent and pass down.
5. **It reads an external store that has subscribe + snapshot** (browser API like `navigator.onLine`, a non-React store) → `useSyncExternalStore` or the library's own hook.
6. **The whole subtree should start fresh when an identity changes** → `key`.
7. **Only part of the state should adjust when a prop changes** → derive it during render, or store something that doesn't need adjusting (e.g. an ID instead of the object).
8. **Real synchronization with a named external system remains** → it's a legitimate effect. Put non-trivial ones in a descriptively named custom hook (`useChatConnection`, `useIntersection`), not inline.

## 2. Replacements

**Derived value**

```tsx
// ✗ extra render, can be momentarily stale
const [fullName, setFullName] = useState('');
useEffect(() => setFullName(`${first} ${last}`), [first, last]);

// ✓
const fullName = `${first} ${last}`;
```

If it's genuinely expensive and the Compiler isn't enabled, wrap it in `useMemo` — still no effect.

**Event-specific logic**

```tsx
// ✗ state flag → effect → reset flag
const [submitted, setSubmitted] = useState(false);
useEffect(() => {
  if (submitted) { post(form); toast('Saved'); setSubmitted(false); }
}, [submitted]);

// ✓
function handleSubmit() {
  post(form);
  toast('Saved');
}
```

The test: would this run *because the component appeared*, or *because the user did X*? Only the first is an effect.

**Resetting all state on identity change**

```tsx
// ✗
useEffect(() => { setComment(''); }, [userId]);

// ✓ parent
<CommentBox key={userId} userId={userId} />
```

**Adjusting part of state on prop change** — usually redesign instead:

```tsx
// ✗ stores the selected object, then "fixes" it when items change
useEffect(() => setSelection(null), [items]);

// ✓ store the id and derive
const [selectedId, setSelectedId] = useState<string | null>(null);
const selection = items.find(i => i.id === selectedId) ?? null;
```

**Notifying the parent**

```tsx
// ✗ child effect calls parent callback after state changes
useEffect(() => { onChange(isOn); }, [isOn]);

// ✓ update both in the same handler
function toggle() {
  const next = !isOn;
  setIsOn(next);
  onChange(next);
}
// or make the component fully controlled by the parent
```

**Chains of effects** that set state that triggers another effect → compute the whole next state in the event handler (or a reducer).

**Subscribing to an external store**

```tsx
function subscribe(cb: () => void) {
  window.addEventListener('online', cb);
  window.addEventListener('offline', cb);
  return () => {
    window.removeEventListener('online', cb);
    window.removeEventListener('offline', cb);
  };
}
export function useOnlineStatus() {
  return useSyncExternalStore(subscribe, () => navigator.onLine, () => true);
}
```

The third argument is the server snapshot; it keeps SSR and hydration consistent. Define `subscribe` outside the component (or keep it stable) so React doesn't resubscribe each render.

**App initialization that must run once per app load** (not per mount) → module-level code or a module-level guard, not `useEffect([])`.

## 3. Writing an effect that should exist

- **Name the system** you're syncing with. If you can't, go back to triage.
- **Every reactive value read inside goes in the dependency array.** Don't suppress the lint rule. If dependencies cause too many re-runs, change the code: move objects/functions created during render *inside* the effect, depend on primitive fields instead of whole objects, use the updater form of `setState`, or move non-reactive logic into `useEffectEvent`.
- **Return a cleanup** that undoes what setup did (disconnect, unsubscribe, clear timer, abort request, remove listener). Setup → cleanup → setup must behave like a single setup; Strict Mode runs exactly that sequence in development to prove it.
- **One effect per concern.** Two unrelated syncs in one effect will re-run each other.
- **Don't write a "mounted" ref** to dodge Strict Mode double execution; fix the cleanup instead.

```tsx
function useChatConnection(roomId: string) {
  useEffect(() => {
    const conn = createConnection(roomId);
    conn.connect();
    return () => conn.disconnect();
  }, [roomId]);
}
```

## 4. Fetching in an effect (last resort)

Only when there's no framework data layer or query library and adding one isn't appropriate. Handle races — responses can arrive out of order when inputs change quickly:

```tsx
useEffect(() => {
  const controller = new AbortController();
  setStatus('loading');
  fetchResults(query, { signal: controller.signal })
    .then(data => { setResults(data); setStatus('success'); })
    .catch(err => { if (!controller.signal.aborted) setStatus('error'); });
  return () => controller.abort();
}, [query]);
```

Still missing: caching, deduplication, retries, background refresh, SSR. That's why a query library or framework loader is the default recommendation once more than a couple of screens fetch data.

## 5. `useEffectEvent` (React 19.2+)

Use it when an effect must *read* the latest value of something without *re-running* when it changes — e.g. logging with the current theme when a connection opens.

```tsx
const onConnected = useEffectEvent(() => {
  showNotification('Connected', theme); // always latest theme
});

useEffect(() => {
  const conn = createConnection(roomId);
  conn.on('connected', () => onConnected());
  conn.connect();
  return () => conn.disconnect();
}, [roomId]); // theme not a dependency, and onConnected must not be listed
```

Rules: only call the returned function from inside effects (or other effect events); don't pass it to other components or hooks; don't use it just to silence a dependency you actually should react to. On older versions, a ref updated in a layout effect ("latest ref" pattern) is the usual workaround — keep it inside a named hook.

## 6. `useLayoutEffect`

Only for reading layout and synchronously adjusting before the browser paints (measure a tooltip and reposition it, restore scroll). It blocks paint, and it doesn't run on the server. It is not a fix for "my effect flickers" — that usually means the state shouldn't have been set in an effect at all.

## 7. Red flags in review

- `useEffect(() => setX(f(y)), [y])`
- an effect whose only job is to call `setState`, or to call a parent's callback
- a boolean state that exists only to trigger an effect
- `// eslint-disable-next-line react-hooks/exhaustive-deps`
- `fetch` + `setState` in an effect with no abort/ignore logic
- objects or functions created during render listed as dependencies
- effects that rely on running exactly once
- a missing cleanup for a listener, timer, subscription or connection
