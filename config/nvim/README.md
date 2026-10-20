# Neovim config — staged rebuild

This directory is the **live** config (`~/.config/nvim` symlinks here via `home.nix:39`).

`../nvim.bak/` is the **target**: [jdhao/nvim-config](https://github.com/jdhao/nvim-config),
98 plugins across ~4850 lines. It is too much to adopt in one go, so this document
breaks it into 14 stages. Each stage leaves you with a working editor, and each one
is small enough to actually read and understand before moving on.

**Right now Stage 0 is done.** Four files, no plugins.

> Terminology below: *[bak]* = file or setting lives in `../nvim.bak`.
> Line references like `lua/mappings.lua:5` are into `../nvim.bak/`.

---

## 1. How the config is wired together

`init.lua` is nothing but an ordered list of `require`s. The order is load-bearing:

```
globals        -- leader key, platform flags, builtin plugin disables.
               -- Must be first: plugin specs branch on vim.g.is_linux etc.,
               -- and mapleader must be set BEFORE any <leader> mapping is defined.
options        -- vim options. Before mappings so expr-mappings see final values.
custom-autocmd -- autocommands. Before plugin_specs so the `User InGitRepo` event
               -- and the ColorScheme hook exist when plugins lazy-load on them.
mappings       -- global keymaps (non plugin-specific).
plugin_specs   -- lazy.nvim bootstrap + every plugin spec. This is where
               -- nvim-lspconfig, treesitter, etc. actually get onto the rtp.
lsp_conf       -- LSP servers + LspAttach keymaps. MUST be after plugin_specs.
diagnostic-conf-- how diagnostics are rendered.
ui             -- colorscheme. MUST be last, so the ColorScheme autocmd
               -- registered in custom-autocmd is already listening when the
               -- scheme is applied. Load it earlier and your highlight
               -- overrides silently do nothing.
```

Our `init.lua` has the same list with the not-yet-written modules commented out.
**Uncomment, never reorder.**

Three cross-cutting modules that everything else pulls from:

| Module | Role |
|---|---|
| `lua/utils.lua` | 18 helpers (`executable`, `rand_element`, `get_titlestr`, `inside_git_repo`, `throttle`, `filesize`, git branch lookups, python env lookups). Required by `globals`, `options`, `custom-autocmd`, `ui`, `lualine`. Grow it stage by stage rather than copying all 286 lines at once. |
| `lua/symbol_icon.lua` | One table of every nerd-font glyph used anywhere — diagnostics signs, git signs, fold chars, statusline separators, `fillchars`. Change an icon in one place, it updates everywhere. 81 lines, no dependencies — worth taking whole in Stage 1. |
| `autoload/*.vim` | Vimscript helpers called by `mappings.lua` via `<cmd>call utils#…<cr>`. If you copy a mapping that calls `utils#SwitchLine` without copying `autoload/utils.vim`, you get `E117: Unknown function` only when you press the key. |

---

## 2. Module map

Everything in `../nvim.bak/`, what it does, and which stage introduces it.

### Core Lua modules

| File | Lines | What it does | Stage |
|---|---:|---|:---:|
| `init.lua` | 41 | The require list above + `vim.loader.enable()` + an nvim version check | 0 |
| `lua/utils.lua` | 286 | Shared helpers (see above) | 0, grown through 8 |
| `lua/globals.lua` | 76 | Leader, platform flags, provider + builtin-plugin disables, python3 host prog | 0 |
| `lua/options.lua` | 241 | All `vim.opt` settings | 0 |
| `lua/symbol_icon.lua` | 81 | Central icon table | 1 |
| `lua/mappings.lua` | 252 | ~50 plugin-independent keymaps | 1 |
| `lua/custom-autocmd.lua` | 313 | 15 autocmd groups: yank highlight, auto-mkdir, auto-read, number toggle, large-file mode, highlight overrides, auto-save, git-repo detection | 1 |
| `lua/plugin_specs.lua` | 840 | lazy.nvim bootstrap + every plugin spec | 3 |
| `lua/ui.lua` | 172 | 25 colorschemes, picks one at random per start; enables the experimental message UI | 3 |
| `lua/lsp_utils.lua` | 95 | `get_default_capabilities()`, attached-LSP lookup, `:LspAttached` nui popup | 4 |
| `lua/lsp_conf.lua` | 231 | `LspAttach` keymaps, server enable table, `:LspInfo`/`:LspLog`/`:LspInlayHints` | 4 |
| `lua/diagnostic-conf.lua` | 70 | `vim.diagnostic.config`, diagnostics→quickfix, float-on-CursorHold | 4 |
| `lua/dotenv.lua` | 29 | Reads `~/.config/.env` into a table. Nothing in the config requires it | skip |

### Vimscript layer

| File | What it does | Stage |
|---|---|:---:|
| `autoload/utils.vim` | `Cabbrev` (cmdline abbreviations), `VimFolds`/`MyFoldText`, `ToggleCursorCol`, `SwitchLine`/`MoveSelection` (Alt-j/k line moving), `iso_time`, `CaptureCommandOutput`, `MultiEdit` | 2 |
| `autoload/buf_utils.vim` | `GoToBuffer` — the `gb`/`gB` count-aware buffer jump | 2 |
| `autoload/text_obj.vim` | `iu` (URL), `iB` (whole buffer), markdown code-block text objects | 2 |
| `plugin/command.lua` | `:CopyPath`, `:JSONFormat`, `:TermHL` | 2 |
| `plugin/command.vim` | `:Redir`, `:Edit` (multi-file glob), `:Datetime`, `:ToPDF` (pandoc→xelatex) | 2 |
| `plugin/abbrev.vim` | Two typo abbreviations | 2 |
| `plugin/log-autocmds.vim` | `:VerboseAutocmds` debug tool. Only useful when hunting an autocmd bug | optional |
| `ftdetect/*.vim` | Filetypes for `.pdc` and `.snippets` | 12 |

### Plugin configs (`lua/config/`)

| File | Lines | Plugin | Stage |
|---|---:|---|:---:|
| `lualine.lua` | 488 | Statusline. The single biggest config file | 8 |
| `nvim-cmp.lua` | 124 | nvim-cmp (disabled — `blink` is selected at `plugin_specs.lua:25`) | skip |
| `blink-cmp.lua` | 115 | Completion engine | 5 |
| `colorful_menu.lua` | 92 | Syntax-highlighted completion items | 5 |
| `hlslens.lua` | 82 | Search match counter (`n`/`N`/`*`/`#`) | 10 |
| `treesitter.lua` | 65 | On-demand parser install per filetype | 6 |
| `gitsigns.lua` | 58 | Sign-column git diff + hunk maps | 9 |
| `fzf-lua.lua` | 55 | Fuzzy finder + `<leader>f*` maps | 7 |
| `bufferline.lua` | 52 | Buffer tabline | 8 |
| `diffview.lua` | 51 | Full-window diff/history view | 9 |
| `treesitter-textobjects.lua` | 50 | `af`/`if`/`ac`/`ic`/`as` text objects | 6 |
| `nvim_ufo.lua` | 47 | Better folding, LSP/treesitter-backed | 8 |
| `git-linker.lua` | 47 | Yank a permalink to the current line on the forge | 9 |
| `nvim_hop.lua` | 28 | `f` → jump anywhere on screen | 10 |
| `fugitive.lua` | 27 | `<leader>g*` git maps | 9 |
| `nvim-statuscol.lua` | 23 | Clickable number/sign/fold column | 8 |
| `gx.lua` | 21 | Open URL under cursor (mac/win only, `plugin_specs.lua:275`) | skip |
| `vim-illuminate.lua` | 20 | Highlight other occurrences of word under cursor | 10 |
| `lightbulb.lua` | 20 | Sign when a code action is available | 10 |
| `aerial.lua` | 19 | Symbol outline sidebar | 10 |
| `yanky.lua` | 17 | Yank ring, `[y`/`]y` to cycle past pastes | 11 |
| `snacks.lua` | 12 | Prettier `vim.ui.input` and `vim.ui.select` | 7 |
| `glance.lua` | 12 | Peek definitions/references in a float | 10 |
| `nvim-notify.lua` | 10 | Notification popups | 8 |
| `nvim-colorizer.lua` | 9 | Render `#rrggbb` in its own colour | optional |
| `live-command.lua` | 9 | Live preview for `:norm`/`:g`/`:s` | 11 |
| `quicker.lua` | 8 | Editable quickfix | 10 |
| `nvim-tree.lua` | 8 | File explorer | 10 |
| `vimade.lua` | 7 | Dim inactive windows | optional |
| `iron.lua` | 7 | REPL integration (python) | skip |
| `which-key.lua` | 6 | Keymap popup | 8 |
| `treesj.lua` | 6 | `gS` split/join a node across lines | 6 |
| `bqf.lua` | 6 | Quickfix preview | 10 |
| `iswap.lua` | 5 | `gs<`/`gs>` swap function arguments | 6 |
| `fidget-nvim.lua` | 1 | LSP progress spinner | 4 |

### Filetype layer

| Path | Contents |
|---|---|
| `after/lsp/*.lua` | Per-server overrides, merged on top of `vim.lsp.config("*")`. 10 files: clangd, emmylua_ls, golangci_lint_ls, gopls, lua_ls, pyrefly, pyright, ruff, ty, typos_lsp |
| `after/ftplugin/*` | 18 files. Per-filetype options, `<F9>` run-this-file maps, formatters |
| `my_snippets/*.snippets` | UltiSnips snippets for 8 filetypes |
| `spell/en.utf-8.add` | Personal spellfile |
| `_typos.toml`, `.stylua.toml`, `.emmyrc.json` | Tool configs for typos-lsp, stylua, emmylua_ls |
| `resources/head.tex` | LaTeX preamble used by `:ToPDF` |

---

## 3. The stages

### Stage 0 — Skeleton ✅ done

**Files:** `init.lua`, `lua/utils.lua`, `lua/globals.lua`, `lua/options.lua`

Deliberately changed from the target:

- `mapleader = " "` instead of `","` — see §4.
- No `utils.is_compatible_version("0.12.6")` check. Installed nvim is **0.12.4**;
  the check is warn-only but prints on every start.
- No python-venv check (`globals.lua:3-13`). It errors unless
  `<config>/.venv/bin/python3` exists. Only ultisnips and iron.nvim need it,
  and both are skipped. `vim.g.loaded_python3_provider = 0` instead.
- No `loaded_matchit`/`loaded_matchparen`. The target disables them because
  vim-matchup replaces them — do that in Stage 6, not before, or you lose `%`
  matching with nothing taking over.
- `listchars` uses ASCII; it becomes nerd-font glyphs via `symbol_icon` in Stage 1.

**Verify:** `nvim --headless -c 'quit'` exits 0 silently.

---

### Stage 1 — Icons, mappings, autocommands

Still zero plugins. This is where the editor starts to *feel* like the target.

**Copy:** `lua/symbol_icon.lua` (whole file), then in `options.lua` replace the
ASCII `listchars` with `opt.fillchars = symbol_icon.fillchars`.

**Copy:** `lua/mappings.lua`, **selectively**. Several entries change long-standing
vim behaviour — adopt them on purpose, not by accident:

| Mapping | Line | Effect |
|---|---:|---|
| `;` → `:` | 5 | No more shift to reach cmdline. Breaks `;` as repeat-`f`. |
| `q` → prints a message, `Q` → record macro | 241-246 | Stops accidental macro recording. Retrains `q` for closing windows. |
| `H` / `L` → `^` / `g_` | 71-72 | Loses screen-top/bottom jumps. |
| `c`/`C`/`cc` → `"_c` | 104-107 | Change no longer clobbers the unnamed register. |
| `p` in visual → `"_c<Esc>p` | 154 | Paste over a selection without losing the register. |
| `<Esc>` → `fclose!` | 248 | Closes floating windows. Harmless until floats exist. |
| arrows → `<C-w>hjkl` | 165-168 | Window switching. |
| `j`/`k` → `gj`/`gk` when no count | 63-64 | Move by screen line. |

Safe and good from the start: `<leader>p`/`<leader>P` (paste on a new line),
`\db`/`\dB` (delete buffer / other buffers), `\x` (close qf+loclist),
`J`/`gJ` without cursor movement (177-194), the undo-break-on-punctuation loop
(197-200), `<C-a>`/`<C-e>` in insert mode.

Mappings that need `autoload/` — defer to Stage 2 or copy both at once:
`<leader>cl`, `<A-j>`/`<A-k>` line moving, `gb`/`gB`, `iu`/`iB`,
`<leader><space>` (needs `:StripTrailingWhitespace` from whitespace.nvim, Stage 11).

**Copy:** `lua/custom-autocmd.lua`, minus three blocks:

- lines **92-110** — auto-open nvim-tree on a directory argument → Stage 10
- lines **204-228** (`auto_close_win`) — references the `NvimTree` filetype → Stage 10
- lines **230-237** (`git_repo_check`) — needs `utils.inside_git_repo()` → Stage 2/9

Also decide on lines **303-313** (auto-save on `InsertLeave`/`TextChanged`).
The previous config formatted via LSP on `BufWritePre`; combined with auto-save
that reformats on nearly every typing pause. **Recommendation: drop the auto-save
autocmd**, keep explicit `<leader>w` and format-on-save.

Lines **170-202** are the `ColorScheme` hook that defines `YankColor`, `Cursor`,
`Cursor2`, `FloatBorder`, `NormalFloat`, `Pmenu`, `MatchParen`. This is the proper
home for the transparent-background highlights the previous config had in
`lua/highlights.lua` (`Normal`/`NormalNC`/`SignColumn` → `bg = "none"`) — put them
here rather than in a standalone module, so they survive a colorscheme change.

`require("custom-autocmd")` and `require("mappings")` in `init.lua`.

**Verify:** yank something — it should flash green. `:set rnu?` toggles off in
insert mode and back on when you leave.

---

### Stage 2 — Vimscript helpers and user commands

**Copy whole:** `autoload/utils.vim`, `autoload/buf_utils.vim`, `autoload/text_obj.vim`,
`plugin/command.lua`, `plugin/command.vim`, `plugin/abbrev.vim`.

Files under `plugin/` are sourced automatically by nvim — no `require` needed.
`autoload/` functions load lazily on first call.

Now enable the mappings deferred from Stage 1, and add `utils.inside_git_repo()`
to `lua/utils.lua` plus the `git_repo_check` autocmd. That autocmd fires a custom
`User InGitRepo` event, which is **what the git plugins in Stage 9 lazy-load on**.
Without it they never load and nothing tells you why.

`:ToPDF` needs `pandoc` + `xelatex`; skip that function if you don't want them.

**Verify:** `:Datetime`, `:CopyPath`, `gb`/`gB` between two buffers, `<A-j>` on a line.

---

### Stage 3 — Plugin manager and colorscheme

**Create** `lua/plugin_specs.lua` with only the lazy.nvim bootstrap
(`plugin_specs.lua:4-17`) and the `require("lazy").setup{}` call
(`plugin_specs.lua:819-831`, rounded border, `concurrency = 5`, `rocks` disabled —
hererocks pulls a whole Lua toolchain otherwise).

Plus the `Cabbrev` shortcuts at the bottom (`pi`, `pud`, `pc`, `ps` → `Lazy install`
etc.) — those need `autoload/utils.vim` from Stage 2.

**First plugins:**

```lua
{ "nvim-lua/plenary.nvim", lazy = true },
{ "nvim-mini/mini.icons", version = false, lazy = true, config = function()
    require("mini.icons").mock_nvim_web_devicons()  -- compat shim
    require("mini.icons").tweak_lsp_kind()
  end },
-- one colorscheme, e.g.:
{ "rebelot/kanagawa.nvim", priority = 1000 },
```

`mini.icons` replaces `nvim-web-devicons` from the previous config; the mock call
keeps plugins that only know devicons working.

**Create** `lua/ui.lua`, but take only the `use_theme` helper (`ui.lua:6-17`) and
**one** entry from `colorscheme_conf`. The target ships 25 schemes and calls
`M.rand_colorscheme()` to pick one at random every start — fun, but it makes every
highlight problem irreproducible.

**Skip** `ui.lua:149-170` (`require("vim._core.ui2").enable{}`) — private API,
and the target expects nvim 0.12.6 while 0.12.4 is installed. Wrap in `pcall` if
you want to try it.

Uncomment `require("plugin_specs")` and `require("ui")` in `init.lua`.

**Verify:** `:Lazy` opens; the colorscheme applies; your Stage 1 highlight
overrides still win (that's the load-order rule paying off).

---

### Stage 4 — LSP

The target uses the **native `vim.lsp.config` / `vim.lsp.enable` API** (nvim 0.11+),
not `lspconfig.setup{}`. nvim-lspconfig is present only to supply the default
`cmd`/`root_markers`/`filetypes` for each server.

**Copy:** `lua/lsp_utils.lua` (drop `show_lsp_menu` until nui.nvim exists, or take
it and add `{ "MunifTanjim/nui.nvim" }`), `lua/lsp_conf.lua`, `lua/diagnostic-conf.lua`.

**Plugins:** `neovim/nvim-lspconfig`, `folke/lazydev.nvim` (`plugin_specs.lua:716-726`),
`j-hui/fidget.nvim`.

`lazydev.nvim` replaces `neodev.nvim` from the previous config — neodev is deprecated.
It also makes the manual `Lua.workspace.library = { vim.env.VIMRUNTIME }` setting
unnecessary.

**Rewrite** the server table at `lsp_conf.lua:104-132` for this machine's stack.
The mechanism is: map server name → executable, enable only if the executable is on
`PATH`, warn only for non-optional ones.

```lua
local enabled_lsp_servers = {
  nixd   = { exe = "nixd",                 optional = false },
  lua_ls = { exe = "lua-language-server",  optional = false },
  elmls  = { exe = "elm-language-server",  optional = true  },
  ts_ls  = { exe = "typescript-language-server", optional = true },
  bashls = { exe = "bash-language-server", optional = true  },
  yamlls = { exe = "yaml-language-server", optional = true  },
}
```

> **Currently on PATH:** `elm-language-server`, `ruff`. Everything else
> (`nixd`, `lua-language-server`, `typescript-language-server`, `bash-language-server`,
> `stylua`) needs adding to `../../configuration.nix` — `neovim` is already there at
> line 233.

**`after/lsp/` is the per-server override directory.** Each file returns a table
merged over the lspconfig default and the `vim.lsp.config("*")` base. Take
`after/lsp/lua_ls.lua` as-is. Create `after/lsp/nixd.lua` and move the previous
config's inline nixd settings into it:

```lua
---@type vim.lsp.Config
return {
  settings = {
    nixd = {
      formatting = { command = { "nixfmt" } }, -- old config said nixpkgs-fmt, which is not installed
      options = {
        nixos = { expr = '(builtins.getFlake "/home/castle/nix-config").nixosConfigurations.default.options' },
        home_manager = { expr = '(builtins.getFlake "/home/castle/nix-config").nixosConfigurations.default.options.home-manager.users.type.getSubOptions []' },
      },
    },
  },
}
```

> The old config pointed these at `/home/castle/nixos-config`, which does not exist —
> the repo is `/home/castle/nix-config`. Fix it while moving it.

Skip `after/lsp/{gopls,golangci_lint_ls,clangd,pyright,ruff,ty,pyrefly}.lua`
unless you pick up those languages. They are still worth reading as examples —
`pyright.lua` shows how to strip duplicate diagnostics when two servers overlap,
which is the same trick you'd need for `ts_ls` + a linter.

**Keymaps** in `lsp_conf.lua:63-79` use a bare `<space>` prefix — must be rewritten,
see §4.

**`diagnostic-conf.lua` is opinionated:** `underline = false`, `virtual_text = false`,
`virtual_lines = false` — signs in the gutter only, with the full message in a float
on `CursorHold` (lines 51-69). Quiet, but if you expect inline errors you'll think
the LSP is broken. Set `virtual_text = true` if you prefer the previous behaviour.

**Verify:** open a `.nix` file, `:checkhealth vim.lsp`, confirm nixd attached;
`:LspAttached` lists it.

---

### Stage 5 — Completion

**Plugins:** `saghen/blink.cmp` (v1.x) + `rafamadriz/friendly-snippets`,
`xzbdmw/colorful-menu.nvim`.

**Copy:** `lua/config/blink-cmp.lua`, `lua/config/colorful_menu.lua`.

Replaces nvim-cmp + LuaSnip + cmp_luasnip + cmp-nvim-lsp from the previous config.
blink has a built-in LSP source, a Rust fuzzy matcher, and its own snippet engine,
so four plugins collapse into one.

**Trim from `blink-cmp.lua`:** the `ultisnips` provider (lines 44-48) and
`"ultisnips"` in `sources.default` (line 42) — ultisnips needs the python3 provider, which
Stage 0 disabled. `friendly-snippets` covers snippets without it.

Optional: the `thesaurus`/`dictionary` providers (`blink-cmp-words`, lines 49-95) wired to
`text` and `markdown` filetypes via `per_filetype`.

Keymap preset is `"default"` (`<C-y>` accepts) with `<Tab>`/`<S-Tab>` to move and
`<CR>` to accept — close to the nvim-cmp config you had.

Capabilities: `lsp_utils.get_default_capabilities()` already advertises
`foldingRange` for nvim-ufo (Stage 8). blink adds its own on top automatically.

**Verify:** completion menu in a `.nix` and a `.lua` file; `<C-space>`; docs popup.

---

### Stage 6 — Treesitter

**Plugins:** `nvim-treesitter/nvim-treesitter` on the **`main` branch**,
`nvim-treesitter/nvim-treesitter-textobjects` (also `main`), `Wansmer/treesj`,
`mizlan/iswap.nvim`, `andymass/vim-matchup`.

> The `main` branch is the rewritten API. `require("nvim-treesitter.configs").setup{}`
> does **not** exist there — `config/treesitter.lua` installs parsers on a `FileType`
> autocmd and calls `vim.treesitter.start()` manually. Do not mix `main`-branch docs
> with `master`-branch tutorials.

**Copy:** `lua/config/treesitter.lua` and edit `ensure_installed` — drop `cpp`, `go`,
`gomod`, `gosum`, `tex`, `python`; add `nix`, `elm`, `tsx`, `css`, `html`.

**Copy:** `lua/config/treesitter-textobjects.lua` (`af`/`if`/`ac`/`ic`/`as`),
`treesj.lua` (`gS`), `iswap.lua` (`gs<` / `gs>`).

Two gotchas:

- `vim.g.no_plugin_maps = true` is set in treesitter-textobjects' `init`
  (`plugin_specs.lua:98`). It disables **all** builtin ftplugin mappings globally,
  for every filetype. Deliberate, but very easy to miss when something stops working.
- **Now** add `vim.g.loaded_matchit = 1` and `vim.g.loaded_matchparen = 1` to
  `globals.lua` — vim-matchup takes over. Its `init` block (`plugin_specs.lua:564-578`)
  sets deferred matching for performance; keep it.

Folding and treesitter-based indent are commented out in `treesitter.lua:58-62` —
leave them until Stage 8 brings in nvim-ufo.

**Verify:** `:InspectTree` on a `.nix` file; `daf` inside a function; `gS` on a table.

---

### Stage 7 — Fuzzy finding

**Plugins:** `ibhagwan/fzf-lua`, `folke/snacks.nvim`.

**Copy:** `lua/config/fzf-lua.lua`, `lua/config/snacks.lua`.

Replaces telescope + telescope-fzf-native. `fzf` is already on PATH.

Maps, all under `<leader>f` — these work fine with `<Space>` as leader:
`ff` files · `fg` live grep · `fh` helptags · `ft` document symbols ·
`fb` buffers · `fr` oldfiles · `<leader>gbl` git branches.

> `<leader>ff` and `<leader>fg` are the same keys the previous config used for
> telescope, so muscle memory carries over.

`snacks.nvim` is loaded only for `input` and `picker` — it upgrades `vim.ui.input`
and `vim.ui.select`, so LSP rename and code-action pickers look right. The plugin
has ~20 other modules, all off by default.

The target keeps telescope installed too (`plugin_specs.lua:136-142`, `cmd = "Telescope"`)
purely for `telescope-symbols`. Not worth it — skip both.

**Verify:** `<leader>ff` and `<leader>fg`; `<leader>la` (code action, after §4 remap)
should open a snacks picker.

---

### Stage 8 — Statusline and window chrome

The most visible stage, and the one with the most moving parts.

**Plugins:** `nvim-lualine/lualine.nvim`, `akinsho/bufferline.nvim`,
`Bekaboo/dropbar.nvim`, `luukvbaal/statuscol.nvim`, `kevinhwang91/nvim-ufo`
(+ `promise-async`), `nvim-mini/mini.indentscope`, `folke/which-key.nvim`,
`rcarriga/nvim-notify`.

**`lua/config/lualine.lua` is 488 lines — do not paste it blind.** It reads from
`symbol_icon` and calls several `utils` functions you may not have copied yet:
`get_virtual_env`, `get_py_env`, `get_git_branches`, `throttle`. **Delete the python
venv component** — it's dead weight here. Build the statusline up section by section;
it is the easiest place in the whole config to lose half an hour to a nil index.

`nvim-ufo` (`nvim_ufo.lua`): `zR` open all · `zM` close all · `zr` open one level ·
`<leader>K` peek folded lines. Its `init` block (`plugin_specs.lua:242-247`) sets
`foldcolumn=1`, `foldlevel=99` — required, folds appear closed otherwise. The
`foldingRange` capability from Stage 4 is what feeds it.

`statuscol.nvim` must come **after** ufo so the fold column is clickable.

`which-key` (`preset = "modern"`, icons off) is the payoff for every `desc = "…"`
in the mappings you copied. Its usefulness scales with `timeoutlen` — consider
raising it from 200 to ~400 in `options.lua` here.

`bufferline` adds `<space>bp` (pick a buffer) — see §4.

`dropbar.nvim` needs no config; it uses the LSP/treesitter from Stages 4 and 6
for the breadcrumb bar.

**Verify:** statusline shows mode/branch/diagnostics; `zR`/`zM` fold; `<leader>` alone
pops up which-key.

---

### Stage 9 — Git

**Plugins:** `lewis6991/gitsigns.nvim`, `tpope/vim-fugitive`, `NeogitOrg/neogit`,
`sindrets/diffview.nvim`, `ruifm/gitlinker.nvim`, `rbong/vim-flog`.

**Copy:** `lua/config/{gitsigns,fugitive,diffview,git-linker}.lua`.

> fugitive, neogit and gitlinker all use `event = "User InGitRepo"`. That event only
> fires because of `utils.inside_git_repo()` from Stage 2. If git commands do nothing,
> check that autocmd first — `:Lazy` will show them as never-loaded.

fugitive maps (`<leader>g…`): `gs` status · `gw` add · `gc` commit · `gpl` pull ·
`gpu` push in a terminal split · `gb` blame (visual) · `gf` fetch ·
`gbn` new branch (prompts) · `gbd` delete branch.
gitlinker adds `<leader>gl` (permalink) and `<leader>gbr` (open in browser).

With `<Space>` as leader these all live under `<Space>g`, alongside
`<leader>gd`/`gr`/`gi` from glance (Stage 10) and `<leader>gbl` from fzf-lua.
They coexist, but `<leader>gb` (visual blame) will wait for `timeoutlen`
before firing because `gbn`/`gbd`/`gbl`/`gbr` share its prefix.

`gitsigns` config maps hunk navigation and staging on `on_attach`.
neogit is a magit-style UI; fugitive is the command wrapper. Having both is
redundant — pick one. Fugitive is the smaller, better-documented choice.

**Verify:** open a file in this repo, make an edit, see signs; `<leader>gs`.

---

### Stage 10 — Navigation, outline, quickfix

**Plugins:** `nvim-tree/nvim-tree.lua`, `stevearc/aerial.nvim`, `smoka7/hop.nvim`,
`kevinhwang91/nvim-hlslens`, `kevinhwang91/nvim-bqf`, `stevearc/quicker.nvim`,
`dnlhc/glance.nvim`, `kosayoda/nvim-lightbulb`, `RRethy/vim-illuminate`.

**Copy** the matching files from `lua/config/`.

**Now re-enable** the three blocks held back in Stage 1:
`custom-autocmd.lua:92-110` (open nvim-tree when nvim is given a directory) and
`custom-autocmd.lua:204-228` (quit when only `qf`/`NvimTree` windows remain).

`nvim-tree` config is 8 lines — `setup{}` plus `<space>s` to toggle. The previous
config had a larger setup with diagnostic icons in the tree; keep that part, it's
strictly better, and keep `<leader>e`/`<leader>ee` if you prefer those keys.

`hop.nvim` binds `f` (`keys = { "f" }`, lazy). Note this shadows vim's `f{char}`.
If `;`→`:` from Stage 1 was adopted, `f` repeat was already gone — these two go together.

`hlslens` wraps `n`/`N`/`*`/`#` to show "3/17" next to the match. This is why
`options.lua` has `shortmess+=S`.

`bqf` and `quicker` both enhance the quickfix window; `bqf` is preview-focused,
`quicker` makes it editable. They can coexist.

`glance` adds `<space>gd`/`gr`/`gi` — see §4.

`aerial` replaces `symbols-outline.nvim` from the previous config:
`[t`/`]t` prev/next symbol, `<space>t` toggle.

**Verify:** `nvim .` opens the tree; `f` then a letter jumps; `/` then `n` shows a count.

---

### Stage 11 — Text objects and editing power

Mostly `init`-only plugins with no config file. Add them in one go or one at a time.

| Plugin | Gives you |
|---|---|
| `wellle/targets.vim` | `ci,` `da(` `in[` — arguments, next/last variants of every pair |
| `machakann/vim-sandwich` | `sa`/`sd`/`sr` add/delete/replace surrounding pairs. **Maps `s` to `<Nop>`** (`plugin_specs.lua:466-471`) — use `cl` instead |
| `gbprod/yanky.nvim` | Yank ring: `[y`/`]y` cycle through previous yanks after a paste |
| `windwp/nvim-autopairs` | Auto-close brackets and quotes |
| `tpope/vim-commentary` | `gcc`, `gc{motion}`. Replaces `Comment.nvim` |
| `tpope/vim-repeat` | Makes `.` work with the plugins above |
| `tpope/vim-eunuch` | `:Rename`, `:Delete`, `:Move` |
| `smjonas/live-command.nvim` | Live preview of `:norm`, `:g`, `:s` |
| `chrisbra/unicode.vim` | `ga` → what character is this |
| `nvim-zh/whitespace.nvim` | Highlights trailing space; provides `:StripTrailingWhitespace` for `<leader><space>` from Stage 1 |
| `nvim-zh/better-escape.vim` | `jk` to leave insert mode |
| `itchyny/vim-highlighturl` | Underlines URLs |

**Verify:** `saiw"` to quote a word; `gcc`; yank three things, paste, `[y`.

---

### Stage 12 — Filetype layer

**Copy selectively from `after/ftplugin/`:**

Worth taking: `lua.lua` (`<F9>` to `:luafile %`, `<Space>f` to run stylua — needs
remapping per §4, and `stylua` is not on PATH yet), `markdown.lua` (`:AddRef`
reference-link helper with completion), `help.lua`, `man.lua`, `qf.vim`,
`json.lua`, `yaml.vim`, `toml.vim`, `gitconfig.vim`, `text.vim`.

Skip: `python.lua`, `go.lua`, `cpp.vim`, `tex.lua`, `sql.vim`, `javascript.vim`
unless relevant. Create `elm.lua` / `nix.lua` on the same pattern if you want
per-filetype run keys.

**Plugins:** `MeanderingProgrammer/render-markdown.nvim`, `godlygeek/tabular`,
`vim-pandoc/vim-markdownfootnotes`.

**Skip `SirVer/ultisnips` and `my_snippets/`** — needs the python3 provider that
Stage 0 disabled. `friendly-snippets` from Stage 5 covers it.

**Tool configs:** copy `.stylua.toml` (2-space indent, matching `options.lua`) and
`_typos.toml` if you add typos-lsp. `.emmyrc.json` only matters for emmylua_ls,
which is commented out upstream.

---

### Stage 13 — Optional and skipped

| Plugin / file | Why it's here | Verdict |
|---|---|---|
| `glacambre/firenvim` | Edit browser textareas in nvim. `enabled` only on win/mac (`plugin_specs.lua:648`) | skip on Linux |
| `lervag/vimtex` + `resources/head.tex` + `:ToPDF` | LaTeX authoring | skip unless you write LaTeX |
| `iron.lua` | Python REPL. Needs python3 provider | skip |
| `chrishrb/gx.nvim` | Open URL under cursor. `enabled` win/mac only | skip; `:!xdg-open` works |
| `lyokha/vim-xkbswitch`, `Neur1n/neuims` | IME switching, mac/win only | skip |
| `ojroques/vim-oscyank` | Clipboard over SSH via OSC52. nvim has this builtin now | skip |
| `nickjvandyke/opencode.nvim` | opencode integration | personal call |
| `tadaa/vimade` | Dims inactive windows | nice-to-have |
| `catgoose/nvim-colorizer.lua` | Renders colour literals | useful for CSS/themes |
| `esmuellert/codediff.nvim` | `:CodeDiff` | redundant with diffview |
| `skywind3000/asyncrun.vim` | `:AsyncRun` into quickfix | redundant with `vim.system` / the old `:Run` command |
| `tpope/vim-obsession` | Session saving | personal call |
| `mg979/vim-visual-multi` | Multi-cursor. Already commented out upstream | — |
| `lua/dotenv.lua` | Reads `~/.config/.env`. Nothing requires it | skip |
| `plugin/log-autocmds.vim` | `:VerboseAutocmds` debug tool | keep around for debugging |
| `glacambre/firenvim`, `tpope/vim-scriptease` | | scriptease is handy: `:Messages`, `:Scriptnames` |

---

## 4. Translating keymaps: the `<Space>` leader problem

**This is the one thing that will bite you in every stage.**

The target sets `mapleader = ","` and then *separately* uses a literal `<space>`
as a second prefix. With `<Space>` as leader those two namespaces merge, and
several pairs collide:

| Target mapping | Source | Collides with |
|---|---|---|
| `<space>rn` rename, `<space>ca` code action | `lsp_conf.lua:73-74` | — |
| `<space>wa`/`wr`/`wl` workspace folders | `lsp_conf.lua:75-79` | **`<leader>w` = save** |
| `<space>qw`/`qb` diagnostics→quickfix | `diagnostic-conf.lua:43-48` | **`<leader>q` = quit** |
| `<Space>f` stylua format | `after/ftplugin/lua.lua` | **`<leader>ff`/`fg`/`fh`/`ft`/`fb`/`fr` = fzf-lua** |
| `<space>s` nvim-tree toggle | `config/nvim-tree.lua:5` | `<leader>s` if you keep the old symbol map |
| `<space>t` aerial toggle | `config/aerial.lua` | — |
| `<space>bp` bufferline pick | `config/bufferline.lua` | — |
| `<space>gd`/`gr`/`gi` glance | `config/glance.lua` | shares `<leader>g` with fugitive (resolvable) |

**Rule: translate every bare `<space>X` into a two-key `<leader>` sequence.**
Never leave a one-key `<leader>` mapping that is a prefix of another.

Suggested scheme — LSP under `l`, diagnostics under `d`, toggles under `t`:

| Target | Use instead | What |
|---|---|---|
| `<space>rn` | `<leader>lr` | rename |
| `<space>ca` | `<leader>la` | code action |
| `<space>wa` / `wr` / `wl` | `<leader>lwa` / `lwr` / `lwl` | workspace folders |
| `<Space>f` (stylua) | `<leader>lf` | format buffer |
| `<space>qw` | `<leader>dw` | window diagnostics → quickfix |
| `<space>qb` | `<leader>db` | buffer diagnostics → quickfix |
| `<space>s` | `<leader>e` / `<leader>ee` | nvim-tree focus / toggle (as before) |
| `<space>t` | `<leader>to` | aerial outline |
| `<space>bp` | `<leader>tb` | bufferline pick |
| `<space>gd` / `gr` / `gi` | keep | glance — no conflict |

Keep from the previous config, unchanged: `<leader>w` save, `<leader>ff` /
`<leader>fg` find, `<leader>p` paste, `<leader>e` tree.

Mappings that **don't** involve leader and transplant verbatim:
`gd`, `K`, `<C-k>`, `<C-]>` (LSP) · `[t`/`]t` (aerial) · `zR`/`zM`/`zr` (ufo) ·
`gs<`/`gs>` (iswap) · `gS` (treesj) · `[y`/`]y` (yanky) · `f` (hop) ·
`af`/`if`/`ac`/`ic`/`as` (treesitter textobjects) · the `\…` family from `mappings.lua`.

> which-key (Stage 8) makes collisions visible: a prefix that waits for more input
> shows a popup. If a single-key mapping feels laggy, something shares its prefix.

---

## 5. Language mapping

The target is built for Python, Go, C++ and LaTeX. The stack here is Nix, Lua, Elm,
TypeScript. Each target component and what it means here:

| Target component | What it does there | Here |
|---|---|---|
| `after/lsp/pyright.lua`, `ruff.lua`, `ty.lua`, `pyrefly.lua` | Python servers; `pyright.lua` strips diagnostics that duplicate ruff's | **Skip, but read `pyright.lua`** — the `tagSupport` capability trick is how you'd deduplicate any two overlapping servers |
| `after/lsp/gopls.lua`, `golangci_lint_ls.lua` | Go + linter-as-LSP | Skip |
| `after/lsp/clangd.lua` | C/C++ | Skip |
| `after/lsp/lua_ls.lua` | Lua runtime version, inlay hints, library paths | **Take as-is.** Combined with `lazydev.nvim`, this is what makes editing *this config* pleasant |
| `after/lsp/typos_lsp.lua` + `_typos.toml` | Spell/typo checking across all filetypes | Language-agnostic — take if you want it |
| `lsp_conf.lua:104-132` | exe-gated server enable table | **Rewrite** for nixd / lua_ls / elmls / ts_ls — see Stage 4 |
| (none) | — | **Create `after/lsp/nixd.lua`** from the previous config's inline nixd settings, fixing the `nixos-config` → `nix-config` path |
| `after/ftplugin/{python,go,cpp,tex}.*` | per-ft options, `<F9>` to run the file | Skip. Use `lua.lua` and `markdown.lua` as the pattern for `nix.lua`/`elm.lua` |
| `treesitter.lua` `ensure_installed` | cpp, go, python, tex, … | Swap for `nix`, `elm`, `typescript`, `tsx`, `lua`, `markdown`, `json`, `yaml`, `toml`, `bash` |
| vimtex + ultisnips + `my_snippets/` + `resources/head.tex` + `:ToPDF` | LaTeX pipeline | Skip. Also removes the python3-provider dependency |
| iron.nvim + `utils.get_py_env`/`get_py_cmd`/`get_virtual_env` | Python REPL and venv display | Skip — **and delete the venv component from `lualine.lua`**, it calls `get_virtual_env` |
| `globals.lua:3-13` python3_host_prog | Points nvim at a config-local venv with pynvim | Already dropped in Stage 0 |

---

## 6. Recovering the previous config

The config in use before this rebuild (12 files, 527 lines) was deleted in commit
`4dedfd2`. It is still in git and is useful as a reference for personal preferences —
nixd settings, the tokyonight theme, the transparent-background highlights, the
`:Run` command, the `<leader>k` "open kitty here" map.

```sh
cd /home/castle/nix-config
git ls-tree -r --name-only HEAD~1 config/nvim        # list it
git show HEAD~1:config/nvim/lua/plugins/lsp.lua      # read one file
git show HEAD~1:config/nvim/lua/highlights.lua
```

Pieces worth pulling back in as you go:

| From | What | Where it goes |
|---|---|---|
| `lua/plugins/lsp.lua` | nixd flake-options settings | `after/lsp/nixd.lua` (Stage 4) |
| `lua/highlights.lua` | transparent `Normal`/`NormalNC`/`SignColumn` | the `ColorScheme` autocmd (Stage 1) |
| `lua/commands.lua` | `:Run` — detached `jobstart` | `plugin/command.lua` (Stage 2) |
| `lua/keymaps.lua` | `<leader>k` opens kitty in cwd; `<A-j>` to escape insert | `mappings.lua` (Stage 1) — note better-escape.vim (Stage 11) does `jk` instead |
| `lua/plugins/nvimtree.lua` | diagnostic icons in the tree | `config/nvim-tree.lua` (Stage 10) |

---

## 7. Quick reference

```sh
# where things are
ls ../nvim.bak/lua/config/          # 35 plugin configs
sed -n '1,80p' ../nvim.bak/lua/plugin_specs.lua

# which plugins does the target pin?
python3 -c "import json;print(len(json.load(open('../nvim.bak/lazy-lock.json'))))"   # 98

# after each stage
nvim --headless -c 'quit'           # must be silent, exit 0
nvim -c 'checkhealth' -c 'only'
:Lazy                               # plugin load state; look for "not loaded"
:map <leader>                       # see what's claimed
```

Installed nvim: **0.12.4**. `../nvim.bak/init.lua` expects 0.12.6 — the check is
warn-only, but a few things (`vim.lsp.config`, `winborder`, `pumborder`,
`vim._core.ui2`) are version-sensitive. If something from the target doesn't exist,
check the version before debugging the config.
