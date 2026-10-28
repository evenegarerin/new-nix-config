---
name: mui
description: How to build React UI with MUI (Material UI) — setup, theming, the sx prop, layout, forms, tables, dialogs, dark mode, and version-specific APIs. Use this skill whenever a task touches frontend UI in a React project, even if the user never says "MUI" — creating or editing components, pages, forms, layouts, dashboards, navigation, modals, tables, or styling. Also use it when the user mentions @mui/material, @mui/icons-material, MUI X, DataGrid, Material Design, createTheme, ThemeProvider, or the sx prop, and when reviewing or refactoring existing MUI code. MUI is the default UI library; only skip this skill if the user explicitly names a different one.
---

# Working with MUI

MUI is the default UI library for frontend work. This skill covers how to use it well so components look consistent, stay themeable, and don't fight the framework.

## Before writing any code

1. **Check the installed version.** Open `package.json` and note the `@mui/material` major version. The Grid API changed between v5, v6 and v7, and getting it wrong produces code that silently renders nothing or fails type-checks. See [Version differences](#version-differences) below.
2. **Look at what already exists.** Search for an existing `theme.ts`/`theme.js`, a `ThemeProvider`, and any shared components (`components/ui`, `components/common`). Reuse them instead of creating parallel ones.
3. **Match the project's styling convention.** If the codebase already uses `sx` everywhere, use `sx`. If it uses `styled()` for everything, follow that. Consistency beats personal preference.

If the project has no MUI yet, install `@mui/material @emotion/react @emotion/styled`, plus `@mui/icons-material` if icons are needed. Don't install `@mui/styles` — it's legacy and tied to React 16/17.

## Core rules

**Use MUI components, not hand-rolled HTML.** `<Button>` not `<button>`, `<TextField>` not `<input>`, `<Typography>` not `<p>`. Raw elements bypass the theme and break dark mode, spacing and typography consistency. Plain `<div>` is fine for pure structure, but reach for `<Box>` when it needs any styling.

**Style with `sx`, theme tokens, and `styled()`.** Never inline `style={{}}`, never a separate CSS file for component styling, never Tailwind alongside MUI. The theme is the single source of truth:

- Spacing: `sx={{ p: 2, mt: 3 }}` (theme units, 1 = 8px), not `padding: '16px'`.
- Colors: `color: 'primary.main'`, `bgcolor: 'background.paper'`, `color: 'text.secondary'`, not hex strings.
- Responsive values: `sx={{ width: { xs: '100%', md: 400 } }}`.
- Typography: `<Typography variant="h6">`, not font-size overrides.

Use `sx` for one-off styling on a single component. Use `styled()` when the same styled element is reused in several places or needs variants/props.

**Theme once, globally.** Wrap the app in `ThemeProvider` with `CssBaseline`. Put brand colors, typography, shape and component defaults in `createTheme`, not scattered across components. If every `Button` needs `disableElevation`, set it in `theme.components.MuiButton.defaultProps`, not on 40 call sites.

**Layout with Stack, Box, Grid and Container.** `Stack` for one-dimensional flex layouts (most cases), `Grid` for two-dimensional responsive grids, `Container` for page-width constraint, `Box` as the generic styled wrapper. Avoid nesting Grid inside Grid for simple vertical stacking — that's what `Stack` is for.

**Icons: import individually.** `import AddIcon from '@mui/icons-material/Add'` rather than `import { Add } from '@mui/icons-material'`. The barrel import pulls thousands of modules into dev builds and slows them badly.

## Common tasks

Each of these has a worked example in `references/patterns.md`. Read that file when implementing them rather than guessing at prop names.

| Task | Use | Notes |
|---|---|---|
| App shell / page layout | `AppBar`, `Drawer`, `Toolbar`, `Container` | Offset content below a fixed AppBar with `<Toolbar />` spacer |
| Forms | `TextField`, `Select`, `Checkbox`, `FormControl`, `FormHelperText` | Controlled components; pair with react-hook-form `Controller` if the project uses it |
| Validation errors | `error` + `helperText` on `TextField` | Don't render a separate error `<span>` |
| Small tables | `Table`, `TableContainer`, `TableHead`, `TableBody` | Wrap in `Paper` via `TableContainer component={Paper}` |
| Large / sortable / paginated tables | MUI X `DataGrid` (`@mui/x-data-grid`) | Separate package; free tier covers sorting, filtering, pagination |
| Modals | `Dialog`, `DialogTitle`, `DialogContent`, `DialogActions` | Not `Modal` directly unless you need fully custom chrome |
| Notifications | `Snackbar` + `Alert` | Or a project-level snackbar context; don't stack ad-hoc Snackbars per component |
| Loading | `Skeleton` for content, `CircularProgress` for actions, `LinearProgress` for page-level | Skeleton over spinners wherever the layout is known |
| Lists / menus | `List`, `ListItemButton`, `Menu`, `MenuItem` | `ListItemButton` for clickable rows, not `ListItem button` (removed) |
| Dark mode | `colorSchemes: { dark: true }` in `createTheme` (v6+) or two themes toggled by mode | See patterns file; v6+ CSS-variable approach avoids flicker |

## Version differences

The Grid component is the main trap. Confirm the major version first.

- **v5**: `<Grid container spacing={2}><Grid item xs={12} md={6}>`. `Grid2` exists as `@mui/material/Unstable_Grid2`.
- **v6**: Old `Grid` still works but is deprecated. `Grid2` at `@mui/material/Grid2` uses `size={{ xs: 12, md: 6 }}` and no `item` prop.
- **v7**: `Grid2` was renamed to `Grid`. `import Grid from '@mui/material/Grid'` and use `size={{ xs: 12, md: 6 }}` with no `item` prop. The old API is gone from `Grid` (available as `GridLegacy`).

Other removed/deprecated things to avoid regardless of version: `makeStyles`/`withStyles` from `@mui/styles`, `Hidden` (use `sx={{ display: { xs: 'none', md: 'block' } }}`), `ListItem button` (use `ListItemButton`), `Box` with `clone` or `component` hacks for layout that `Stack` handles.

## Accessibility

MUI components are accessible by default only when given the right props:

- Every `TextField` has a `label` (or `aria-label` if visually unlabeled).
- `IconButton` always gets `aria-label`.
- `Dialog` gets `aria-labelledby` pointing at its `DialogTitle` id.
- Don't suppress focus rings with `outline: none` in `sx`.

## Verify before finishing

Run whatever the project uses — typically `tsc --noEmit` (or the type-check script), the linter, and a dev build. Grid API mistakes and wrong icon imports surface here, not at runtime. If the project has Storybook or component tests, run those for the components touched.

## When not to use MUI

Only when the user explicitly names another library, or the project is already built on one (Tailwind + shadcn, Chakra, Ant Design). In that case follow the existing convention and don't introduce MUI alongside it.