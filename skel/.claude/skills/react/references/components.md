# Components and composition

## Contents
1. Size and responsibility
2. Props API design
3. Composition patterns
4. Controlled vs uncontrolled
5. Refs
6. Custom hooks
7. Error boundaries and Suspense
8. Typing component props

## 1. Size and responsibility

Split a component when a part has its own state, is reused, or makes the parent hard to read — not to hit a line count. Keep data-loading and presentational concerns separable where it helps testing, but don't force a "container/presenter" split everywhere; hooks already separate logic from markup.

One component per file is a common convention; follow the project. Keep components at module scope (never declared inside another component's body).

## 2. Props API design

- Name props by meaning (`variant="danger"`), not by implementation (`redBorder`).
- Prefer a single enum-like prop over several booleans that can conflict (`size="sm" | "md"` rather than `small` + `large`).
- Event props are `onSomething`; handler functions inside are `handleSomething`.
- Forward unknown DOM props to the root element (`...rest`) for leaf UI primitives so consumers can pass `aria-*`, `data-*`, `className`.
- Don't pass whole objects when a child needs two fields — it couples the child to a shape and widens re-render triggers. Do pass objects when the child truly represents that entity.
- Avoid prop drilling through more than two or three levels by first trying composition (pass `children` or elements), then Context.

## 3. Composition patterns

**Children / slots instead of config props**

```tsx
// ✗ grows a prop for every variation
<Card title="Plan" showFooter footerText="Upgrade" footerAction={upgrade} icon="star" />

// ✓
<Card>
  <Card.Header icon={<StarIcon />}>Plan</Card.Header>
  <Card.Body>…</Card.Body>
  <Card.Footer><Button onClick={upgrade}>Upgrade</Button></Card.Footer>
</Card>
```

**Explicit variants instead of modes**: when a component has `isEditing`, `isReadOnly`, `isThread` toggles with branching inside, create `EditMessage`, `ReadOnlyMessage`, `ThreadMessage` that compose shared pieces.

**Compound components** share state through a context scoped to the parent (`<Tabs>`, `<Tabs.List>`, `<Tabs.Panel>`). Expose the parts; keep the context private; throw a helpful error if a part is used outside the parent.

**Passing elements as props / children to avoid re-renders**: elements created by a parent and passed through as `children` don't re-render when the intermediate component's state changes. This is often a better fix than `memo`.

**Render props** are still fine when the consumer needs data from the component to decide what to render (virtualized list rows, headless components). Prefer `children` when it doesn't.

**Higher-order components** are rarely the right choice in new code; a custom hook or composition usually is.

## 4. Controlled vs uncontrolled

A reusable input-like component should support both: `value` + `onChange` (controlled) and `defaultValue` (uncontrolled). Don't switch between them over a component's lifetime (`value` going from `undefined` to a string triggers a warning). Never keep a "local copy" of a controlled value in state.

## 5. Refs

- Refs are an escape hatch for imperative DOM work: focus, scroll, measuring, integrating non-React widgets. If you're using a ref to drive what renders, it should be state.
- Don't read or write `ref.current` during render.
- React 19: function components receive `ref` as a normal prop; ref callbacks may return a cleanup function. React 18: use `forwardRef`.
- Expose a narrow imperative API with `useImperativeHandle` when parents need it (`focus()`, `scrollToItem()`), rather than leaking the whole DOM node — only if the project does that already or there's a clear need.
- Callback refs are the right tool when you need to know when a node attaches/detaches (measure on mount, observe with `ResizeObserver`).

## 6. Custom hooks

- Extract a hook to share *stateful logic*, or to give an effect a meaningful name. Don't make a hook for code that uses no hooks — that's a plain function.
- Name by purpose (`useOnlineStatus`, `useDebouncedValue`), not by lifecycle (`useMount`, `useUpdateEffect`) — lifecycle-named hooks hide what's being synchronized and encourage effect misuse.
- Each call to a hook has independent state; hooks share logic, not state. To share state, lift it or use Context/a store.
- Return a small, stable surface. Tuples for two values (`[value, setValue]`), objects for more.
- Follow the Rules of Hooks: call at the top level of components or hooks only, never conditionally or in loops. (`use()` is the exception and may be called conditionally.)

## 7. Error boundaries and Suspense

- Place Suspense boundaries where a loading state makes sense to the user (a panel, a list), not just at the root. Nested boundaries let content stream in progressively. Avoid boundaries so granular that the page "pops" in many pieces.
- Pair them with error boundaries at similar granularity so one failing widget doesn't blank the page. Offer a retry that resets the boundary.
- Error boundaries don't catch errors in event handlers or async code outside rendering — handle those where they happen and surface them via state.
- Error boundaries still require a class component; use `react-error-boundary` if the project has it. Framework apps often provide route-level error files/components — use those.
- To keep showing old content while new content loads (instead of a fallback flashing), trigger the update in a transition (`startTransition`, or navigation in frameworks that already use transitions).

## 8. Typing component props (TypeScript projects)

Only the React-specific parts; general TS conventions belong to the JS/TS skill.

- Type props with a `type`/`interface` named `XProps`; follow the project on which.
- Extend native element props for wrappers: `type ButtonProps = ComponentProps<'button'> & { variant?: 'primary' | 'ghost' }`.
- `children: ReactNode` for anything renderable; `ReactElement` only when you actually need an element.
- Event handler types: `(event: React.ChangeEvent<HTMLInputElement>) => void`, or `ComponentProps<'input'>['onChange']`.
- Avoid `React.FC` unless the codebase uses it consistently; plain function declarations with typed props are the norm.
- Use discriminated unions for props that are valid only together (`{ mode: 'link'; href: string } | { mode: 'button'; onClick: () => void }`).
