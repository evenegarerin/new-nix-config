## Frontend UI library

Use MUI (Material UI) for all frontend work unless the user explicitly specifies a different library.

- Import from `@mui/material` and `@mui/icons-material`.
- Prefer MUI components over hand-rolled HTML/CSS equivalents.
- Use the `sx` prop or MUI theming for styling, not ad-hoc CSS.
- If a project already uses a different UI library, follow the existing convention.