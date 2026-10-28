# MUI patterns

Worked examples for the tasks listed in SKILL.md. Written for MUI v6/v7; the Grid section shows v5 for comparison. TypeScript is used; drop the types for JS projects.

## Contents

1. [Theme setup with dark mode](#theme-setup-with-dark-mode)
2. [sx and styled](#sx-and-styled)
3. [App shell](#app-shell)
4. [Grid by version](#grid-by-version)
5. [Forms](#forms)
6. [Forms with react-hook-form](#forms-with-react-hook-form)
7. [Tables](#tables)
8. [DataGrid](#datagrid)
9. [Dialog](#dialog)
10. [Snackbar](#snackbar)
11. [Loading states](#loading-states)

---

## Theme setup with dark mode

`src/theme.ts`:

```tsx
import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  cssVariables: true,                 // v6+: enables CSS vars, prevents dark-mode flicker
  colorSchemes: { light: true, dark: true },
  palette: {
    primary: { main: '#1e5eff' },
    secondary: { main: '#ff6f00' },
  },
  shape: { borderRadius: 8 },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: { fontSize: '2.25rem', fontWeight: 600 },
  },
  components: {
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: { root: { textTransform: 'none' } },
    },
    MuiTextField: {
      defaultProps: { size: 'small', fullWidth: true },
    },
  },
});
```

`src/main.tsx`:

```tsx
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { theme } from './theme';

<ThemeProvider theme={theme}>
  <CssBaseline />
  <App />
</ThemeProvider>
```

Toggling the color scheme (v6+):

```tsx
import { useColorScheme } from '@mui/material/styles';

function ModeToggle() {
  const { mode, setMode } = useColorScheme();
  return (
    <IconButton aria-label="toggle dark mode" onClick={() => setMode(mode === 'dark' ? 'light' : 'dark')}>
      {mode === 'dark' ? <LightModeIcon /> : <DarkModeIcon />}
    </IconButton>
  );
}
```

For v5, create two themes with `palette.mode: 'light' | 'dark'` and swap them in `ThemeProvider` from state.

---

## sx and styled

`sx` for one-off styling, with theme tokens and responsive values:

```tsx
<Box
  sx={{
    p: 2,
    mb: { xs: 2, md: 4 },
    bgcolor: 'background.paper',
    borderRadius: 1,
    border: 1,
    borderColor: 'divider',
    display: 'flex',
    gap: 1,
    '&:hover': { boxShadow: 2 },
  }}
>
```

Access the theme in a callback when you need computed values:

```tsx
sx={{ width: (theme) => theme.spacing(30), color: (t) => t.palette.text.secondary }}
```

`styled()` for a reusable element, with a custom prop that should not reach the DOM:

```tsx
import { styled } from '@mui/material/styles';

const StatusDot = styled('span', {
  shouldForwardProp: (prop) => prop !== 'active',
})<{ active?: boolean }>(({ theme, active }) => ({
  width: 8,
  height: 8,
  borderRadius: '50%',
  display: 'inline-block',
  backgroundColor: active ? theme.palette.success.main : theme.palette.grey[400],
}));
```

---

## App shell

Fixed AppBar with a permanent Drawer on desktop and content offset correctly:

```tsx
const drawerWidth = 240;

export function Shell({ children }: { children: React.ReactNode }) {
  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar position="fixed" sx={{ zIndex: (t) => t.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" noWrap>My App</Typography>
        </Toolbar>
      </AppBar>

      <Drawer
        variant="permanent"
        sx={{
          width: drawerWidth,
          display: { xs: 'none', md: 'block' },
          '& .MuiDrawer-paper': { width: drawerWidth, boxSizing: 'border-box' },
        }}
      >
        <Toolbar /> {/* spacer so the list starts below the AppBar */}
        <List>
          <ListItemButton selected>
            <ListItemIcon><DashboardIcon /></ListItemIcon>
            <ListItemText primary="Dashboard" />
          </ListItemButton>
        </List>
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar /> {/* spacer */}
        {children}
      </Box>
    </Box>
  );
}
```

For mobile, add a second `Drawer variant="temporary"` controlled by state and a menu `IconButton` in the AppBar shown only at `xs`.

---

## Grid by version

**v7** (and v6 via `@mui/material/Grid2`):

```tsx
import Grid from '@mui/material/Grid'; // v6: '@mui/material/Grid2'

<Grid container spacing={2}>
  <Grid size={{ xs: 12, md: 8 }}><MainPanel /></Grid>
  <Grid size={{ xs: 12, md: 4 }}><Sidebar /></Grid>
  <Grid size="grow"><Flexible /></Grid>
</Grid>
```

**v5**:

```tsx
import Grid from '@mui/material/Grid';

<Grid container spacing={2}>
  <Grid item xs={12} md={8}><MainPanel /></Grid>
  <Grid item xs={12} md={4}><Sidebar /></Grid>
</Grid>
```

For a simple row or column, prefer `Stack`:

```tsx
<Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center">
```

---

## Forms

Controlled fields, validation surfaced through `error` + `helperText`:

```tsx
function SignupForm() {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('');
  const [agree, setAgree] = useState(false);
  const emailError = email !== '' && !email.includes('@');

  return (
    <Stack component="form" spacing={2} onSubmit={(e) => { e.preventDefault(); /* submit */ }}>
      <TextField
        label="Email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={emailError}
        helperText={emailError ? 'Enter a valid email' : ' '}
        required
      />

      <FormControl>
        <InputLabel id="role-label">Role</InputLabel>
        <Select labelId="role-label" label="Role" value={role} onChange={(e) => setRole(e.target.value)}>
          <MenuItem value="admin">Admin</MenuItem>
          <MenuItem value="editor">Editor</MenuItem>
        </Select>
      </FormControl>

      <FormControlLabel
        control={<Checkbox checked={agree} onChange={(e) => setAgree(e.target.checked)} />}
        label="I agree to the terms"
      />

      <Button type="submit" variant="contained" disabled={!agree || emailError}>
        Create account
      </Button>
    </Stack>
  );
}
```

Note the `helperText=" "` fallback: it reserves the line so the layout doesn't jump when an error appears.

---

## Forms with react-hook-form

Wrap MUI inputs in `Controller`; don't use `register` because MUI inputs are not plain DOM refs.

```tsx
import { useForm, Controller } from 'react-hook-form';

type FormValues = { name: string; plan: string };

function PlanForm() {
  const { control, handleSubmit } = useForm<FormValues>({ defaultValues: { name: '', plan: '' } });

  return (
    <Stack component="form" spacing={2} onSubmit={handleSubmit((v) => console.log(v))}>
      <Controller
        name="name"
        control={control}
        rules={{ required: 'Name is required' }}
        render={({ field, fieldState }) => (
          <TextField {...field} label="Name" error={!!fieldState.error} helperText={fieldState.error?.message ?? ' '} />
        )}
      />
      <Controller
        name="plan"
        control={control}
        render={({ field }) => (
          <TextField {...field} select label="Plan">
            <MenuItem value="free">Free</MenuItem>
            <MenuItem value="pro">Pro</MenuItem>
          </TextField>
        )}
      />
      <Button type="submit" variant="contained">Save</Button>
    </Stack>
  );
}
```

`TextField select` is simpler than `FormControl + Select` when you don't need the extra control.

---

## Tables

```tsx
<TableContainer component={Paper}>
  <Table size="small" aria-label="users">
    <TableHead>
      <TableRow>
        <TableCell>Name</TableCell>
        <TableCell align="right">Age</TableCell>
      </TableRow>
    </TableHead>
    <TableBody>
      {rows.map((r) => (
        <TableRow key={r.id} hover>
          <TableCell>{r.name}</TableCell>
          <TableCell align="right">{r.age}</TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
</TableContainer>
```

Once you need sorting, filtering, pagination or editing, switch to DataGrid rather than reimplementing them.

---

## DataGrid

Install `@mui/x-data-grid` (keep its major version aligned with `@mui/material` per the MUI X compatibility table).

```tsx
import { DataGrid, type GridColDef } from '@mui/x-data-grid';

const columns: GridColDef[] = [
  { field: 'name', headerName: 'Name', flex: 1 },
  { field: 'age', headerName: 'Age', type: 'number', width: 100 },
  { field: 'createdAt', headerName: 'Created', type: 'date', width: 140, valueGetter: (v) => new Date(v) },
];

<Box sx={{ height: 480 }}>
  <DataGrid
    rows={rows}
    columns={columns}
    loading={isLoading}
    pageSizeOptions={[25, 50]}
    initialState={{ pagination: { paginationModel: { pageSize: 25 } } }}
    disableRowSelectionOnClick
  />
</Box>
```

DataGrid needs a bounded height (or `autoHeight`) or it renders zero rows.

---

## Dialog

```tsx
function ConfirmDelete({ open, onClose, onConfirm }: Props) {
  return (
    <Dialog open={open} onClose={onClose} aria-labelledby="confirm-delete-title">
      <DialogTitle id="confirm-delete-title">Delete this item?</DialogTitle>
      <DialogContent>
        <DialogContentText>This can't be undone.</DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={onConfirm} color="error" variant="contained">Delete</Button>
      </DialogActions>
    </Dialog>
  );
}
```

Keep the dialog mounted and drive it with `open` — don't conditionally render it, or the close animation is lost.

---

## Snackbar

A small context so any component can call `notify('Saved')` without owning Snackbar state:

```tsx
const SnackbarContext = createContext<(msg: string, severity?: AlertColor) => void>(() => {});
export const useNotify = () => useContext(SnackbarContext);

export function SnackbarProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<{ msg: string; severity: AlertColor } | null>(null);
  const notify = useCallback((msg: string, severity: AlertColor = 'success') => setState({ msg, severity }), []);

  return (
    <SnackbarContext.Provider value={notify}>
      {children}
      <Snackbar open={!!state} autoHideDuration={4000} onClose={() => setState(null)}>
        <Alert severity={state?.severity} onClose={() => setState(null)} variant="filled">
          {state?.msg}
        </Alert>
      </Snackbar>
    </SnackbarContext.Provider>
  );
}
```

---

## Loading states

Skeleton that mirrors the final layout:

```tsx
{isLoading ? (
  <Stack spacing={1}>
    <Skeleton variant="text" width="60%" />
    <Skeleton variant="rectangular" height={120} />
    <Skeleton variant="text" />
  </Stack>
) : (
  <ArticleCard article={article} />
)}
```

Button with inline progress:

```tsx
<Button variant="contained" disabled={saving} startIcon={saving ? <CircularProgress size={16} color="inherit" /> : null}>
  {saving ? 'Saving…' : 'Save'}
</Button>
```