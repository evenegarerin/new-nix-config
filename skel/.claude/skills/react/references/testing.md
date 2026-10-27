# Testing React components and hooks

Use the project's existing runner and setup (Vitest or Jest, Testing Library, Playwright/Cypress). Don't introduce a new runner for one test. Test-runner configuration and general JS testing conventions belong elsewhere; this covers React-specific practice.

## Contents
1. What to test
2. Queries
3. Interactions
4. Async UI
5. Network and data
6. Hooks
7. Server Components and Actions
8. Common smells

## 1. What to test

Test behaviour the user can observe, not implementation details. A good component test renders, interacts like a user, and asserts on what's visible or announced. It should survive refactors that don't change behaviour (renaming state, splitting components, swapping a hook).

Don't assert on: internal state, how many times a component rendered, which hooks were called, CSS class names (unless the class *is* the behaviour), or component instance methods.

Cover: the happy path, loading/error/empty states, validation messages, keyboard operation for interactive widgets, and the bug you're fixing (write the failing test first when fixing a bug).

## 2. Queries

Query priority (Testing Library):

1. `getByRole` with `name` — mirrors how assistive tech sees the page and doubles as an accessibility check.
2. `getByLabelText` for form fields, `getByPlaceholderText` only if there's no label (and then fix the label).
3. `getByText` for non-interactive content.
4. `getByTestId` only as a last resort.

Use `screen` rather than destructuring from `render`. `getBy*` throws when missing, `queryBy*` returns null (use for asserting absence), `findBy*` waits (use for things that appear asynchronously).

## 3. Interactions

Use `@testing-library/user-event` (create an instance with `userEvent.setup()` and `await` each action) over `fireEvent`; it simulates real sequences (focus, keydown, input, keyup, click) and catches bugs `fireEvent` misses.

```tsx
test('adds a todo', async () => {
  const user = userEvent.setup();
  render(<TodoApp />);
  await user.type(screen.getByLabelText(/new todo/i), 'Buy milk');
  await user.click(screen.getByRole('button', { name: /add/i }));
  expect(screen.getByRole('listitem')).toHaveTextContent('Buy milk');
});
```

## 4. Async UI

- Wait for outcomes with `findBy*` or `waitFor(() => expect(...))`. Put only the assertion inside `waitFor`, not side effects.
- Avoid arbitrary `setTimeout` sleeps. Use fake timers for debounce/timeout logic (and tell `userEvent.setup({ advanceTimers })` about them).
- An "update not wrapped in act(...)" warning means something updated after the test thought it was done — usually a missing `await` or an unawaited async effect. Fix the wait; don't wrap random lines in `act`.
- Suspense: render inside a boundary and `await screen.findBy…` the resolved content.

## 5. Network and data

- Mock at the network layer (MSW) instead of mocking your fetch wrapper or query hooks; it tests the real data path and works for both client and server code.
- Give each test a fresh query client / store and wrap with the same providers the app uses, via a shared `renderWithProviders` helper (create it if the project lacks one and many tests need it).
- Disable retries in the test query client so error states appear immediately.

## 6. Hooks

Prefer testing hooks through a component that uses them. For reusable hooks with an API of their own, use `renderHook` from `@testing-library/react`, update via `act`, and assert on `result.current`. Reducers and pure helpers extracted from components can be unit-tested as plain functions — often the cheapest high-value tests.

## 7. Server Components and Actions

Async Server Components aren't well supported by unit-test renderers. Test them by: unit-testing the data functions and Server Action logic directly (authorization, validation, return values), unit-testing the Client Components they render, and covering the full page with an end-to-end test (Playwright/Cypress) against a running app.

## 8. Common smells

- Large snapshot tests of whole components — brittle and rarely reviewed. Use small targeted snapshots only for stable output (e.g. a serialized config).
- Mocking child components by default. Mock only things that are slow, nondeterministic, or outside your control.
- Tests that pass only because of a fixed order or shared state between tests.
- `getByTestId` everywhere — usually signals inaccessible markup.
- Asserting a spy was called instead of asserting the visible result, when a visible result exists.
