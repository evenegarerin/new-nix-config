# Neovim config — staged rebuild

This directory is the **live** config (`~/.config/nvim` symlinks here via `home.nix:39`).

`../nvim.bak/` is the **target**: [jdhao/nvim-config](https://github.com/jdhao/nvim-config),
98 plugins across ~4850 lines. It is too much to adopt in one go, so this document
breaks it into 14 stages. Each stage leaves you with a working editor, and each one
is small enough to actually read and understand before moving on.

**All 14 stages are done.** 59 plugins, counting lazy.nvim itself. Nothing is
parked or deferred — every mapping in `lua/mappings.lua` is live.

> ⚠️ **One thing still outstanding:** `sudo nixos-rebuild switch --flake .#default`.
> Stage 4 added eight language servers to `../../configuration.nix` and Stage 6
> added the treesitter parser derivation to `../../home.nix`. Until that runs,
> nvim warns once at startup that `nixd` and `lua_ls` are missing, and the
> treesitter symlinks point at a store path built for testing.

> ⚠️ **Stage 4 added packages to `../../configuration.nix` — run
> `sudo nixos-rebuild switch --flake .#default` or nothing LSP-related works.**
> Until then nvim warns once at startup that `nixd` and `lua_ls` are missing.

The rebuild above is the only remaining step.

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
| `lua/symbol_icon.lua` | 81 | Central icon table | 1 ✅ |
| `lua/mappings.lua` | 252 | ~50 plugin-independent keymaps | 1 ✅ |
| `lua/custom-autocmd.lua` | 313 | 15 autocmd groups: yank highlight, auto-mkdir, auto-read, number toggle, large-file mode, highlight overrides, auto-save, git-repo detection | 1 ✅ (11 of 15) |
| `lua/plugin_specs.lua` | 840 | lazy.nvim bootstrap + every plugin spec | 3 |
| `lua/ui.lua` | 172 | 25 colorschemes, picks one at random per start; enables the experimental message UI | 3 |
| `lua/lsp_utils.lua` | 95 | `get_default_capabilities()`, attached-LSP lookup, `:LspAttached` nui popup | 4 ✅ |
| `lua/lsp_conf.lua` | 231 | `LspAttach` keymaps, server enable table, `:LspInfo`/`:LspLog`/`:LspInlayHints` | 4 ✅ |
| `lua/diagnostic-conf.lua` | 70 | `vim.diagnostic.config`, diagnostics→quickfix, float-on-CursorHold | 4 ✅ |
| `lua/dotenv.lua` | 29 | Reads `~/.config/.env` into a table. Nothing in the config requires it | skip |

### Vimscript layer

| File | What it does | Stage |
|---|---|:---:|
| `autoload/utils.vim` | `Cabbrev` (cmdline abbreviations), `VimFolds`/`MyFoldText`, `ToggleCursorCol`, `SwitchLine`/`MoveSelection` (Alt-j/k line moving), `iso_time`, `CaptureCommandOutput`, `MultiEdit` | 2 ✅ |
| `autoload/buf_utils.vim` | `GoToBuffer` — the `gb`/`gB` count-aware buffer jump | 2 ✅ |
| `autoload/text_obj.vim` | `iu` (URL), `iB` (whole buffer), markdown code-block text objects | 2 ✅ |
| `plugin/command.lua` | `:CopyPath`, `:JSONFormat`, `:TermHL` | 2 ✅ |
| `plugin/command.vim` | `:Redir`, `:Edit` (multi-file glob), `:Datetime`, `:ToPDF` (pandoc→xelatex) | 2 ✅ |
| `plugin/abbrev.vim` | Two typo abbreviations | 2 ✅ |
| `plugin/log-autocmds.vim` | `:LogAutocmds` debug tool (the command is **not** `:VerboseAutocmds`). Toggles logging of every autocmd to `/tmp/vim_log_autocommands`. Off until invoked | 2 ✅ |
| `ftdetect/*.vim` | Filetypes for `.pdc` and `.snippets` | 12 ✅ (`pdc` only) |

### Plugin configs (`lua/config/`)

| File | Lines | Plugin | Stage |
|---|---:|---|:---:|
| `lualine.lua` | 488 | Statusline. The single biggest config file | 8 ✅ |
| `nvim-cmp.lua` | 124 | nvim-cmp (disabled — `blink` is selected at `plugin_specs.lua:25`) | skip |
| `blink-cmp.lua` | 115 | Completion engine | 5 ✅ |
| `colorful_menu.lua` | 92 | Syntax-highlighted completion items | 5 ✅ |
| `hlslens.lua` | 82 | Search match counter (`n`/`N`/`*`/`#`) || 10 ✅ |
| `treesitter.lua` | 65 | On-demand parser install per filetype | 6 ✅ rewritten — parsers come from nix |
| `gitsigns.lua` | 58 | Sign-column git diff + hunk maps || 9 ✅ |
| `statuscolumn.lua` | 144 | Two fixed gutter cells: gitsigns gets its own | 9 ✅ |
| `fzf-lua.lua` | 55 | Fuzzy finder + `<leader>f*` maps | 7 ✅ |
| `bufferline.lua` | 52 | Buffer tabline | 8 ✅ |
| `diffview.lua` | 51 | Full-window diff/history view || 9 ✅ |
| `treesitter-textobjects.lua` | 50 | `af`/`if`/`ac`/`ic`/`as` text objects | 6 ✅ |
| `nvim_ufo.lua` | 47 | Better folding, LSP/treesitter-backed | **removed** -- tried in Stage 8, dropped |
| `git-linker.lua` | 47 | Yank a permalink to the current line on the forge || 9 ✅ |
| `nvim_hop.lua` | 28 | `f` → jump anywhere on screen || 10 ✅ |
| `fugitive.lua` | 27 | `<leader>g*` git maps || 9 ✅ |
| `nvim-statuscol.lua` | 23 | Clickable number/sign/fold column | **removed** -- tried in Stage 8, dropped |
| `gx.lua` | 21 | Open URL under cursor (mac/win only, `plugin_specs.lua:275`) | skip |
| `vim-illuminate.lua` | 20 | Highlight other occurrences of word under cursor || 10 ✅ |
| `lightbulb.lua` | 20 | Sign when a code action is available || 10 ✅ |
| `aerial.lua` | 19 | Symbol outline sidebar || 10 ✅ |
| `yanky.lua` | 17 | Yank ring, `[y`/`]y` to cycle past pastes | **removed** — tried in Stage 11, dropped |
| `snacks.lua` | 12 | Prettier `vim.ui.input` and `vim.ui.select` | 7 ✅ |
| `glance.lua` | 12 | Peek definitions/references in a float || 10 ✅ |
| `nvim-notify.lua` | 10 | Notification popups | 8 ✅ |
| `nvim-colorizer.lua` | 9 | Render `#rrggbb` in its own colour | optional |
| `live-command.lua` | 9 | Live preview for `:norm`/`:g`/`:s` | 11 ✅ |
| `quicker.lua` | 8 | Editable quickfix | **removed** -- tried in Stage 10, dropped |
| `nvim-tree.lua` | 8 | File explorer | 3 ✅ |
| `vimade.lua` | 7 | Dim inactive windows | **removed** -- tried in Stage 13, dropped |
| `iron.lua` | 7 | REPL integration (python) | skip |
| `which-key.lua` | 6 | Keymap popup | 8 ✅ |
| `treesj.lua` | 6 | `gS` split/join a node across lines | 6 ✅ |
| `bqf.lua` | 6 | Quickfix preview || 10 ✅ |
| `iswap.lua` | 5 | `gs<`/`gs>` swap function arguments | **removed** -- tried in Stage 6, dropped |
| `fidget-nvim.lua` | 1 | LSP progress spinner | 4 ✅ |

### Filetype layer

| Path | Contents |
|---|---|
| `after/lsp/*.lua` | Per-server overrides, merged on top of `vim.lsp.config("*")`. 10 files: clangd, emmylua_ls, golangci_lint_ls, gopls, lua_ls, pyrefly, pyright, ruff, ty, typos_lsp |
| `after/ftplugin/*` | 18 files upstream; **11 taken** (12 ✅). Per-filetype options, `<F9>` run-this-file maps, formatters |
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

### Stage 1 — Icons, mappings, autocommands ✅ done

**Files:** `lua/symbol_icon.lua`, `lua/mappings.lua`, `lua/custom-autocmd.lua`,
plus `utils.filesize` and the `options.lua` char swap. Still zero plugins.

> ⚠️ This section used to say *"replace the ASCII `listchars` with
> `opt.fillchars = symbol_icon.fillchars`"*. Those are **two different options**.
> The target sets them separately: `fillchars` from `symbol_icon` at
> `options.lua:9`, and `listchars` as its own literal table at `options.lua:133-140`
> that never touches `symbol_icon`. Both are now set; `trail = "°"` is kept from the
> previous config, which the target does not set at all.

**Mappings adopted in full**, including every behaviour-changing one:

| Mapping | Effect |
|---|---|
| `;` → `:` | No shift to reach the cmdline. `;` as repeat-`f` is gone — which pairs with hop.nvim taking `f` in Stage 10 |
| `c`/`C`/`cc`/visual `p` → `"_` | Change and paste-over-selection no longer clobber the unnamed register |
| `q` reminds, `Q` records | No more accidental macro recording |
| `H`/`L` → `^`/`g_` | Line start/end. No more screen-top/bottom jumps |
| `j`/`k` → `gj`/`gk` when `v:count == 0` | Screen lines, but `5j` and relativenumber jumps still move real lines |
| arrows → `<C-w>hjkl` | Window switching |
| `<Esc>` → `fclose!` | Closes floating windows |

> **`q` in help and quickfix now does nothing but print the reminder.** Stock nvim
> maps nothing to `q` there either (verified: `maparg("q", "n")` is empty in both),
> so this is not a regression from vim behaviour — but if you had the habit, it is
> gone. Use `\x` for quickfix/loclist, `<leader>q` for any window, `:helpclose` for
> help. Plugins that set a buffer-local `q` still win; nvim-tree still closes on it.

Changed from the target:

| Change | Why |
|---|---|
| **`<Esc>` wraps `fclose!` in `pcall`** (`mappings.lua:248-252`) | The target calls it bare. With no floating window open `:fclose!` throws **E444**, so plain `<Esc>` in normal mode would error |

**Nine mappings are parked**, commented out at the bottom of `lua/mappings.lua`
with the stage that unblocks them. Stage 2 is a matter of uncommenting:
`<leader>cl`, `<A-j>`/`<A-k>` (normal and visual), `gb`/`gB`, `iu`/`iB` need
`autoload/`; `<leader><space>` needs whitespace.nvim from Stage 11.

**11 of the 15 autocmd groups** landed. The four that did not are listed at the
bottom of `lua/custom-autocmd.lua`:

| Group | Lines | Why not |
|---|---:|---|
| `auto_close_win` | 204-228 | Quits nvim when only `qf`/`NvimTree` windows remain. Deliberately not adopted |
| `git_repo_check` | 230-237 | Needs `utils.inside_git_repo()` → **Stage 2** |
| `format check` | 267-301 | Runs `stylua --check`/`black --check` on `BufWritePost`. **`stylua` is not on PATH**, so every Lua save would print `stylua not found!` |
| `auto_save` | 303-313 | `silent! update` on `InsertLeave`/`TextChanged`. With Stage 4's format-on-save it reformats at nearly every typing pause |

Two blocks **moved here** from the temporary homes Stage 3 gave them:

- `open_nvim_tree` (the `VimEnter` directory handler) came out of the nvim-tree
  spec's `init` in `plugin_specs.lua`. This module is required before
  `plugin_specs`, so the autocmd still exists before `VimEnter` fires.
- the `custom_highlight` `ColorScheme` hook came out of `lua/ui.lua`, and the
  transparency rules are now merged into the target's `YankColor`/`Cursor`/
  `Cursor2`/`FloatBorder`/`NormalFloat`/`Pmenu`/`MatchParen`/`Illuminated*` block.
  **It has to stay exactly one autocmd in that group** — a second one with
  `clear = true` would wipe the first.

`Cursor`/`Cursor2` are not decoration: `options.lua` already points `guicursor` at
them. `IlluminatedWord*` is for vim-illuminate in Stage 10 and is harmless early.

**Verify:** yank something — it flashes green. `relativenumber` turns off in insert
mode and back on when you leave. `:set fillchars?` and `:set listchars?` show the
nerd-font glyphs. `:w` into a path whose directories do not exist creates them.

---

### Stage 2 — Vimscript helpers and user commands ✅ done

**Copied whole:** `autoload/utils.vim`, `autoload/buf_utils.vim`,
`autoload/text_obj.vim`, `plugin/command.lua`, `plugin/command.vim`,
`plugin/abbrev.vim`, `plugin/log-autocmds.vim`, `resources/head.tex`.

Files under `plugin/` are sourced automatically by nvim — no `require` needed.
`autoload/` functions load lazily on first call, so `exists("*utils#Foo")` returns
0 until something calls into that file. That is normal, not a missing function.

**Unblocked from Stage 1:** the nine parked mappings are now live — `<leader>cl`,
`<A-j>`/`<A-k>` (normal and visual), `gb`/`gB`, `iu`/`iB`. Only
`<leader><space>` is still parked, waiting on whitespace.nvim in Stage 11.

**`utils.inside_git_repo()`** is in `lua/utils.lua` and the `git_repo_check`
autocmd is in `lua/custom-autocmd.lua`. It fires a custom `User InGitRepo` event
on `VimEnter` and `DirChanged` — **this is what the Stage 9 git plugins lazy-load
on.** Without it they never load and nothing tells you why.

**`plugin_specs.lua`** picked up the `pi`/`pud`/`pc`/`ps` → `Lazy …` abbreviations
it had been waiting on.

Changed from the target:

| Change | Why |
|---|---|
| **`:Edit` is `-nargs=*`**, and `utils#MultiEdit` falls back to a bare `:edit` when given no patterns | The target is `-nargs=+` and then aliases `edit` → `Edit`, so a bare `:edit` (reload the current file) dies with **E471: Argument required**. Confirmed by typing it, not by reading it — `vim.cmd("edit")` bypasses cmdline abbreviations entirely and will not reproduce this |
| **`buf_utils#GoToBuffer` notifies at level 3, not 4** | `vim.notify` at `ERROR` level *raises* when called from vimscript, so an invalid count like `999gb` aborted the function and printed `function buf_utils#GoToBuffer, line 17: Invalid bufnr: 999` instead of a plain warning |
| **`:TermHL` uses `vim.notify`, not `vim._log`** | `vim._log` is not an API function on 0.12.4. Same fix as `utils._get_branch` in Stage 8 |
| **`:Run` added** to `plugin/command.lua` | Recovered from the pre-rebuild config (§6). Detached `jobstart`, so a GUI program you launch outlives the nvim session |

`:ToPDF` is included along with `resources/head.tex`, but **`pandoc` and `xelatex`
are not installed** — it exits with `pandoc not found` until you add them to
`../../configuration.nix` (a xelatex-providing texlive is a 2–3 GB closure).

**Verify:** `:Datetime` · `:CopyPath nameonly` · `:Run <something>` · `<A-j>` on a
line · `gb`/`3gb` between buffers · `yiB` yanks the buffer · `:edit` alone reloads,
`:edit some/glob/*.lua` opens every match.

---

### Stage 3 — Plugin manager and colorscheme ✅ done

**Files:** `lua/plugin_specs.lua`, `lua/ui.lua`, `lazy-lock.json`

`plugin_specs.lua` is the lazy.nvim bootstrap (`plugin_specs.lua:4-17` verbatim) plus
`require("lazy").setup{}` (`plugin_specs.lua:820-832` — rounded border, `concurrency = 5`,
`rocks` disabled, because hererocks pulls a whole Lua toolchain otherwise).

Plugins so far:

```lua
{ "rebelot/kanagawa.nvim", priority = 1000 },
{ "nvim-mini/mini.icons", version = false, lazy = true, config = ... },
{ "nvim-tree/nvim-tree.lua", dependencies = { "nvim-mini/mini.icons" }, ... },
```

Deliberately changed from the target:

- **One colorscheme, not 25.** `ui.lua` takes only the `use_theme` helper
  (`ui.lua:6-17`) and `kanagawa-dragon` (`ui.lua:81-83`). `M.rand_colorscheme()`
  picking a random scheme per start makes every highlight problem irreproducible.
  Note `:colorscheme` reports `kanagawa`, not `kanagawa-dragon` — the variant file is
  one line, `require("kanagawa").load "dragon"`, and it does not touch `g:colors_name`.
- **`mini.icons` is declared as a dependency of nvim-tree**, not bare `lazy = true` as
  at `plugin_specs.lua:190-198`. `mock_nvim_web_devicons()` is a compat shim, and
  nvim-tree is a plugin that only knows nvim-web-devicons — the shim has to be installed
  *before* nvim-tree loads. As a dependency, lazy.nvim guarantees that ordering; left
  bare, nothing ever requires it and the tree renders without icons.
- **`kanagawa` gets `priority = 1000`** where the target has `lazy = true`
  (`plugin_specs.lua:172`). The target can defer it because `rand_colorscheme` requires
  the module by name; with a fixed scheme it has to be loaded before `ui.lua` runs.
- **`Cabbrev` shortcuts** (`pi`, `pud`, `pc`, `ps` → `Lazy install`/`update`/`clean`/`sync`)
  were deferred until Stage 2 brought `utils#Cabbrev`; they are in `plugin_specs.lua` now.
- **The transparency rules** from the previous config's `lua/highlights.lua`
  (kitty runs at `background_opacity 0.8`, so an opaque `Normal` reads as a solid
  box) lived at the top of `ui.lua` while Stage 1 was outstanding. They are now in
  the `custom_highlight` hook in `lua/custom-autocmd.lua`, which loads earlier —
  `ui.lua` is just the `use_theme` helper and one `colorscheme` call again.

  > `nvim_set_hl` **replaces** a group rather than patching it, so
  > `nvim_set_hl(0, "Normal", { bg = "none" })` also throws away the scheme's
  > foreground — which is what `highlights.lua` did. The hook reads the group back
  > with `nvim_get_hl(0, { name = group, link = false })` and overrides only `bg`.

- **Skipped** `ui.lua:149-170` (`require("vim._core.ui2").enable{}`) — private API,
  and the target expects nvim 0.12.6 while 0.12.4 is installed.

`lazy-lock.json` is written by lazy.nvim and committed, same as
`../nvim.bak/lazy-lock.json`. It is what makes the plugin set reproducible.

> ⚠️ `~/.local/share/nvim/lazy/` still holds all 98 clones from the pre-rebuild setup,
> so `:Lazy` lists ~95 plugins as removable and every later stage installs instantly
> and offline. **Do not run `:Lazy clean` until the rebuild is finished.**

**Verify:** `:Lazy` opens with a rounded "Plugin Manager" border, three plugins loaded,
none failed; `:lua =vim.api.nvim_get_hl(0, {name="Normal"})` shows a foreground and no
background.

---

### Stage 4 — LSP ✅ done

**Files:** `lua/lsp_conf.lua`, `lua/diagnostic-conf.lua`, the rest of
`lua/lsp_utils.lua`, `lua/config/fidget-nvim.lua`, and five `after/lsp/` overrides.
**Plugins:** `neovim/nvim-lspconfig`, `folke/lazydev.nvim`, `j-hui/fidget.nvim`.

Uses the native **`vim.lsp.config` / `vim.lsp.enable` API** (nvim 0.11+), not
`lspconfig.setup{}`. nvim-lspconfig only supplies each server's default `cmd`,
`root_markers` and `filetypes`.

#### ⚠️ Requires a rebuild

Stage 4 added these to `../../configuration.nix`, just below `neovim`:

```
nixd  lua-language-server  stylua  typescript-language-server
bash-language-server  yaml-language-server  marksman  pyright
```

**None of them exist until you run `sudo nixos-rebuild switch --flake .#default`.**
`elm-language-server`, `elm-format`, `ruff` and `nixfmt` were already there.

#### Servers

`lsp_conf.lua` maps server name → executable and enables a server only if the
executable is on `PATH`. Missing **non-optional** servers warn; missing optional
ones stay quiet.

| Server | Executable | Optional | Override |
|---|---|:-:|---|
| `nixd` | `nixd` | no | `after/lsp/nixd.lua` |
| `lua_ls` | `lua-language-server` | no | `after/lsp/lua_ls.lua` |
| `elmls` | `elm-language-server` | yes | `after/lsp/elmls.lua` |
| `ts_ls` | `typescript-language-server` | yes | — |
| `bashls` | `bash-language-server` | yes | — |
| `yamlls` | `yaml-language-server` | yes | — |
| `marksman` | `marksman` | yes | — |
| `pyright` | `pyright-langserver` | yes | `after/lsp/pyright.lua` |
| `ruff` | `ruff` | yes | `after/lsp/ruff.lua` |

`after/lsp/nixd.lua` carries the previous config's flake-options settings, with
two corrections: it pointed at `/home/castle/nixos-config`, which does not exist
(the repo is `/home/castle/nix-config`), and asked for `nixpkgs-fmt`, which is not
installed — `nixfmt` is.

Changed from the target:

| Change | Why |
|---|---|
| **Missing-server warnings are batched into one `vim.schedule`d notification** | The target calls `vim.notify` once per server, inline during startup. Two or more overflow the message area and you get **"Press ENTER or type command to continue" on every single launch**. Verified against a real pty before and after |
| **`:LspRestart` is actually implemented** | The target defines it as `lsp restart`, which is not a command. Nor does nvim provide one — nvim-lspconfig dropped `:LspRestart`/`:LspStart`/`:LspStop` when it moved to `vim.lsp.enable`, and `exists(":LspRestart")` is **0** on 0.12.4. It now stops the attached clients and reloads the buffer, which re-attaches them |
| **`after/lsp/pyright.lua` drops `cmd`** | The target pins `delance-langserver`, a pyright fork that is not in nixpkgs. Without the line, lspconfig's default `pyright-langserver --stdio` applies |
| **`show_lsp_menu` notifies when nothing is attached** | The target mounts an empty popup — a blank box you cannot distinguish from a broken one |
| **Diagnostics are inline, not quiet** | The target sets `underline`/`virtual_text`/`virtual_lines` all false. The previous config's `virtual_text` + `underline` + `update_in_insert` is used instead. Set `virtual_text = false` in `diagnostic-conf.lua` for the target's behaviour |

The statusline's LSP component is wired to `lsp_utils.show_lsp_menu` now, so
clicking it gives the same popup as `:LspAttached` — that was deferred in Stage 8
because `lsp_utils` did not exist yet.

**Keymaps** (the target's bare `<space>` prefix rewritten per §4):

```
gd  definition (duplicates collapsed)   <C-]>  raw definition
K   hover                               <C-k>  signature help
<leader>lr  rename      <leader>la  code action    <leader>lf  format
<leader>lwa / lwr / lwl   workspace folders
<leader>dw  window diagnostics -> qf    <leader>db  buffer diagnostics -> qf
```

Still **not** adopted: the `format check` autocmd (`custom-autocmd.lua:267-301`).
`stylua` exists after the rebuild, so it is unblocked — it was declined in Stage 1,
not blocked. `<leader>lf` covers formatting on demand.

**Verify** (after the rebuild): open a `.nix` file → `:LspAttached` lists `nixd`,
and `services.` completes with real NixOS options. `:checkhealth vim.lsp`.
`:LspRestart`. On a Python file `ruff` already attaches today — that path is
confirmed working, 5 diagnostics on a deliberately broken file.

---

### Stage 5 — Completion ✅ done

**Files:** `lua/config/blink-cmp.lua`, `lua/config/colorful_menu.lua`.
**Plugins:** `saghen/blink.cmp` (1.x) + `rafamadriz/friendly-snippets`,
`xzbdmw/colorful-menu.nvim`, `archie-judd/blink-cmp-words`.

Replaces nvim-cmp + LuaSnip + cmp_luasnip + cmp-nvim-lsp from the previous config.
blink has a built-in LSP source, a Rust fuzzy matcher and its own snippet engine,
so four plugins collapse into one.

Changed from the target:

| Change | Why |
|---|---|
| **colorful-menu is wired into blink** via `completion.menu.draw.components.label` | The target only hooks it into `config/nvim-cmp.lua:64` — the **disabled** engine (`plugin_specs.lua:25` selects blink). Copied as the README said, the plugin loads and does nothing at all. The wiring is from colorful-menu's own README, using `blink_components_text`/`blink_components_highlight` (`init.lua:192`/`204`) |
| **Documentation scrolling moved to `<C-b>`/`<C-f>`** | The target uses `<C-U>`/`<C-D>`, both already bound in insert mode by Stage 1 — `<C-u>` uppercases the word (`mappings.lua:8`), `<C-D>` is forward-delete. blink would shadow them whenever the menu is open |
| **No `ultisnips` source** | Needs the python3 provider, which `globals.lua` disables. `snippets` (blink's own, fed by friendly-snippets) replaces it, so `blink.compat` is not needed either |
| **`pyright` added to colorful-menu's `ls` table** | That table is keyed by LSP *client name*. The target lists `basedpyright` but not `pyright`, which is what `lsp_conf.lua` enables |

`<CR>` is left as the target has it — `select_and_accept`, so with the menu open
Enter always completes (it picks the first item if none is selected) and is only a
newline when the menu is closed. `<C-y>` also accepts, per the `default` preset.

Thesaurus and dictionary completion (`blink-cmp-words`) are enabled for `text`
and `markdown` via `sources.per_filetype`.

> **colorful-menu only colours LSP items.** `blink_highlights` starts with
> `vim.lsp.get_client_by_id(ctx.item.client_id)` and returns nil when there is no
> client, so buffer/path/snippet items get only match highlighting. Its effect is
> therefore **not visible until the Stage 4 rebuild puts `lua_ls`/`nixd` on PATH** —
> the wiring is verified, the colouring is not.

**Verify:** typing in a buffer pops the menu — confirmed over RPC against a live
instance: `blink.is_visible()` true with `alpha_beta_gamma`/`alpha_delta` offered
from the buffer source, Rust fuzzy matcher loaded. After the rebuild, check a
`.lua` and a `.nix` file for LSP items with coloured labels, `<C-space>`, and the
docs popup with `<C-b>`/`<C-f>`.

---

### Stage 6 — Treesitter ✅ done

**Plugins:** `nvim-treesitter/nvim-treesitter` (**`main`**),
`nvim-treesitter/nvim-treesitter-textobjects` (**`main`**), `Wansmer/treesj`,
`andymass/vim-matchup`. (`mizlan/iswap.nvim` was adopted here too, then removed --
it gave `gs<`/`gs>` to swap sibling nodes: arguments, table entries, list items.)
**Files:** `lua/config/treesitter.lua` (rewritten), `treesitter-textobjects.lua`,
`treesj.lua`, plus a new block in `../../home.nix`.

> The `main` branch is the rewritten API. `require("nvim-treesitter.configs").setup{}`
> does **not** exist there. Do not mix `main`-branch code with `master`-branch tutorials.

#### Parsers come from nix, not from nvim-treesitter

This is the one stage that departs from the target structurally.

`main` installs a parser by shelling out to **`tree-sitter build`**
(`install.lua:305`), which needs the tree-sitter CLI *and* a C compiler. On this
machine `tree-sitter`, `cc`, `gcc`, `clang` and `make` are **all absent**, and
nothing else wants them.

So `../../home.nix` builds parsers from nixpkgs' prebuilt grammars instead:

```nix
treesitterLangs = [ "nix" "json" "toml" "yaml" "css" "bash" ];

treesitterParsers = pkgs.runCommand "nvim-treesitter-parsers" { } ''
  … ln -s ${pkgs.vimPlugins.nvim-treesitter-parsers.${lang}}/parser/${lang}.so …
    cp -r ${pkgs.vimPlugins.nvim-treesitter}/runtime/queries/${lang} …
'';
```

and symlinks the result into `~/.local/share/nvim/site/{parser,queries}`.

Three things make that the right target directory:

- it is nvim-treesitter's **own default `install_dir`** (`config.lua:10`), so this
  is where `install()` would have put the same files;
- it is one of the few paths that **survives lazy.nvim's runtimepath rebuild** —
  a plain `set rtp+=…` is silently dropped (verified: appended path gone, `site`
  still present);
- grammars *and* queries come from the same nixpkgs `nvim-treesitter` revision,
  so they cannot drift apart.

`lua/config/treesitter.lua` is therefore rewritten: it only calls
`vim.treesitter.start()`, and never `nvim-treesitter.install()` or
`get_available()`. `build = ":TSUpdate"` is deliberately absent from the spec.
The plugin itself is still needed — for `plugin/query_predicates.lua`, which the
bundled queries rely on, and as the dependency textobjects/treesj expect.

> **To add a language:** add its grammar to `treesitterLangs` in `home.nix`, add the
> *filetype* to `enabled_filetypes` in `lua/config/treesitter.lua`, and rebuild.
> The two lists differ where filetype ≠ language — `sh` maps to the `bash` grammar.

`lua`, `markdown`, `markdown_inline`, `query`, `vim` and `vimdoc` are **bundled with
Neovim** and are deliberately not in `treesitterLangs`: overriding their queries
from a different revision would risk a mismatch with the bundled parsers.

Corrections to what this section used to say:

| Claim | Reality |
|---|---|
| nixpkgs would force the old `master` API | **nixpkgs 26.05 ships `main` too** — `configs.lua` is absent, `get_available`/`install` are present. No rewrite of the API was needed, only of the install path |
| the plugin ships no queries | It ships **323 languages** under `<plugin>/runtime/queries/`. They are not at `<plugin>/queries/`, which is what made them look absent. `install()` links them into `site/queries/<lang>`; since we never call it, nix supplies them instead |
| `vimPlugins.nvim-treesitter.withAllGrammars` | Evaluates to the **same store path** as the plain plugin here — it contributes no parsers. The per-language `vimPlugins.nvim-treesitter-parsers.<lang>` derivations are what actually carry `parser/<lang>.so` |

Other changes from the target:

| Change | Why |
|---|---|
| **`vim.g.no_plugin_maps` left unset** | The target sets it in textobjects' `init` (`plugin_specs.lua:98`). Despite sitting in that spec it disables *every* builtin ftplugin mapping for *every* filetype — `gO` in help, `[[`/`]]` section motions. Nothing in `af`/`if`/`ac`/`ic`/`as` collides with those |
| **A missing grammar is silent** | `language.add` returning false means "add it to `treesitterLangs` and rebuild", not a runtime error worth a message on every file open |

`globals.lua` now sets `vim.g.loaded_matchit = 1` and `vim.g.loaded_matchparen = 1` —
vim-matchup has taken over, and its `init` keeps the target's deferred-matching
performance settings and offscreen-match popup.

Folding and treesitter indent stay commented out in `treesitter.lua`. They were
held for nvim-ufo in Stage 8; ufo has since been removed, so nothing drives
folding now -- uncomment `foldexpr` there if you want treesitter folds back.

**Verify:** confirmed working — `configuration.nix` parses as `nix` with the
highlighter active and a real `source_code` root node; `yaml`/`json`/`toml`/`css`/
`sh`→`bash`/`lua` all attach their parser; `daf` inside a Lua function deleted all
four of its lines. `:InspectTree` on a `.nix` file; `gS` on a table.

> ⚠️ The `site/{parser,queries}` symlinks currently point at a store path created
> for testing. **`sudo nixos-rebuild switch --flake .#default` re-points them** from
> `home.nix`. If nix garbage-collects first they dangle and treesitter quietly has
> no parsers — rebuilding fixes it.

---

### Stage 7 — Fuzzy finding ✅ done

**Plugins:** `ibhagwan/fzf-lua`, `folke/snacks.nvim`.
**Files:** `lua/config/fzf-lua.lua`, `lua/config/snacks.lua` — both taken as-is.

Replaces telescope + telescope-fzf-native. `fzf`, `rg` and `fd` were all already
on PATH, so this stage needed nothing from `configuration.nix`.

Maps, all under `<leader>f`:

| Key | Picker |
|---|---|
| `<leader>ff` | files |
| `<leader>fg` | live grep (`live_grep_native`) |
| `<leader>fh` | helptags |
| `<leader>ft` | LSP document symbols |
| `<leader>fb` | buffers |
| `<leader>fr` | oldfiles |
| `<leader>gbl` | git branches |

`<leader>ff` and `<leader>fg` are the same keys the pre-rebuild config used for
telescope, so muscle memory carries over. No bare `<leader>f` exists, so none of
them waits out `timeoutlen`.

`defaults.file_icons = "mini"` means fzf-lua renders icons through mini.icons,
which Stage 3 already installed — hence the explicit dependency in the spec.

`snacks.nvim` is loaded only for `input` and `picker`; its ~20 other modules stay
off. That is what upgrades `vim.ui.input` and `vim.ui.select`, so `<leader>lr`
(rename) and `<leader>la` (code action) get a proper picker instead of a
cmdline prompt.

Changed from the target:

| Change | Why |
|---|---|
| **telescope and telescope-symbols skipped** | The target keeps telescope installed alongside fzf-lua (`plugin_specs.lua:136-142`, `cmd = "Telescope"`) purely for `telescope-symbols`. Not worth carrying a second finder |
| **`opts = {}` dropped from the snacks spec** | The target sets both `opts` and `config`. lazy.nvim passes `opts` to `config`, but `config/snacks.lua` ignores its arguments and calls `setup` itself, so `opts` did nothing |

`files.previewer = false` is kept from the target — file search has no preview
pane. Grep does. `bat` and `delta` are not installed; fzf-lua's builtin previewer
does not need them.

**Verify:** confirmed working — `<leader>ff` opens a floating fzf terminal
(1 window → 2, a `term://` buffer in a float). `vim.ui.input` resolves to
`snacks/input.lua` and `vim.ui.select` to `snacks/picker/init.lua`, so the
overrides are genuinely in place. All seven maps present.

---

### Stage 8 — Statusline and window chrome ✅ done

**Plugins:** `nvim-lualine/lualine.nvim`, `akinsho/bufferline.nvim`,
`folke/which-key.nvim`, `rcarriga/nvim-notify`, `Bekaboo/dropbar.nvim`,
`nvim-mini/mini.indentscope`.

lualine landed early — see its own subsection below. The other five came with
this stage.

| Piece | Keys / effect |
|---|---|
| bufferline | buffer tabline · `<leader>tb` pick |
| which-key | popup after any prefix |
| nvim-notify | takes over `vim.notify` |
| dropbar | breadcrumb winbar |
| mini.indentscope | current-indent guide, animation off |

Changed from the target:

| Change | Why |
|---|---|
| **`foldcolumn = "auto:1"`**, not `"1"` | The target adds a permanent fold column to every window, on top of the sign column. (Moot now: ufo was removed, so `foldcolumn` is back to `0`, and the gutter is drawn by `lua/statuscolumn.lua` -- see Stage 9.) |
| **`timeoutlen` 200 → 400** | which-key is only as useful as the window you get to read it in. The target uses 500; 400 keeps two-key sequences snappy. This stage's own note suggested ~400 |
| **`<space>bp` → `<leader>tb`** | Bare `<space>` collides with the leader. See §4 |
| **nvim-notify `background_colour` `#2E3440` → `#181616`** | The target hardcodes a **Nord** colour, which clashes with kanagawa-dragon. A concrete value is needed at all because `custom-autocmd.lua` makes `Normal` transparent, so there is no background to inherit. `#181616` is kanagawa-dragon's own |
| **dropbar is `lazy = false`**, not `event = "VeryLazy"` | dropbar self-initialises from a **`once` FileType autocmd in its own `plugin/dropbar.lua`**. Any lazy trigger firing after the first buffer's FileType leaves *that* buffer with no winbar until you switch away and back. Verified: with the target's setting the startup buffer's `winbar` is empty; eager loading sources the plugin file first and both buffers get it. `BufWinEnter` does **not** fix it — same race |
| **`luukvbaal/statuscol.nvim` removed** | Adopted during this stage, then dropped. It rebuilt `'statuscolumn'` as ordered, clickable segments (signs / numbers / folds) with fold indicators capped at depth 3. The gutter is nvim's stock one again. It drew whatever fold column was available; nvim-ufo (also since removed) was declared as its dependency to guarantee load order |
| **`cond = firenvim_not_active` dropped from bufferline** | firenvim is not installed |

Treesitter folding is still commented out in `lua/config/treesitter.lua`. It was
redundant while ufo drove folding through its own provider chain (LSP
`foldingRange` → treesitter → indent); with ufo gone nothing folds automatically,
so uncommenting `foldexpr` there is the way to get folds back. The
`foldingRange` capability has been dropped from `lsp_utils.get_default_capabilities()`
along with ufo -- it had no other consumer.

**Verify:** confirmed working — all 6 plugins load with 0 errors; `tabline` set;
`<leader>tb` present and `<space>bp` gone; `winbar` set on both the startup
buffer and later ones. (While ufo was in, `zM` closed folds covering 290 of 332
lines and `zR` reopened them — its treesitter fallback worked before the LSP
rebuild.)

> `vim.notify` becomes a **table**, not a function — nvim-notify's module is
> callable via `__call`. Calling it works; `debug.getinfo(vim.notify)` does not.

#### lualine (landed earlier)

What changed from `../nvim.bak/lua/config/lualine.lua`:

| Change | Why |
|---|---|
| **`lualine_a` is `mode`**, filename moved to `lualine_c` with `path = 1` | The target has no mode component anywhere, yet `options.lua` sets `showmode = false`. Taken verbatim you get no mode indicator at all. The comment on `options.lua:117` was wrong and is now fixed |
| **Dropped the ahead/behind counter** (`lualine.lua:78-111`) | It ran `git fetch origin` in the background every 3s for the whole session. This also made `utils.throttle` unnecessary |
| **`virtual_env` adopted, and moved** (227-235) | Dropped at first ("no python here"), then added back on request. It lives in `lualine_b` **right after `branch`**, not the target's `lualine_z`, and without the target's `fg = "black", bg = "#F1CA81"` so it inherits section b's colours like `diff` and `diagnostics`. Returns `""` when no venv is active, which makes lualine skip the component and its icon entirely — the same way `branch` vanishes outside a git repo. Needs `utils.get_virtual_env`, copied from the target's `utils.lua` |
| **Dropped `ime_state`** (122-137) | macOS-only Chinese IME indicator; `vim.g.is_mac` is false |
| **Dropped the LSP `on_click` menu** (363-380) | It needs `lsp_utils.show_lsp_menu`, which belongs with `:LspAttached` in Stage 4. The LSP *indicator* is there and shows 🚫 until Stage 4 attaches a server |
| **`trailing_space` rewritten** (139-168) | The target calls `fn.getline` + `fn.match` for every line of the buffer, every second. Now one `nvim_buf_get_lines` and a Lua pattern, plus a 10k-line bail-out — same answer, far cheaper |
| **`utils._get_branch` returns `{}` on failure** | The target calls `vim._log`, which is not an API function on 0.12.4 and would error inside the branch menu |
| **Branch menu `on_submit` strips the label** (335-347) | The target passes `item.text` straight to `git checkout`, but that string is `"  <icon> <branch>"` — every checkout from the menu would fail. The branch name is now split out of the label |

Components that are live but inert until a later stage: the `diff` counts read
`vim.b.gitsigns_status_dict` and stay blank until gitsigns lands in Stage 9; the LSP
name needs Stage 4.

`nui.nvim` is spec'd `lazy = true` and is deliberately **not** in lualine's
`dependencies` — lazy.nvim loads a plugin's dependencies eagerly along with it, and
only the branch-menu click handler needs nui. Its `require("nui.menu")` trips lazy's
module loader on demand. Stage 4's `:LspAttached` popup can reuse it.

**Still to do in this stage:**

`which-key` (`preset = "modern"`, icons off) is the payoff for every `desc = "…"`
in the mappings you copied. Its popup speed is governed by which-key's own
`opts.delay`, **not** `timeoutlen` -- see `lua/config/which-key.lua`, where
`delay = 0` and `options.lua` keeps `timeoutlen = 200`.

`bufferline` adds `<space>bp` (pick a buffer) — see §4.

`dropbar.nvim` needs no config; it uses the LSP/treesitter from Stages 4 and 6
for the breadcrumb bar.

Stage 1 also wires `symbol_icon.fillchars` into `options.lua` and
`symbol_icon.indent` / `.tabline` into mini.indentscope and bufferline — those keys
are sitting in `lua/symbol_icon.lua` unused for now.

**Verify:** statusline shows mode/branch/diagnostics; click the branch name for a
checkout menu; `zR`/`zM` fold; `<leader>` alone pops up which-key.

---

### Stage 9 — Git ✅ done

**Plugins:** `lewis6991/gitsigns.nvim`, `tpope/vim-fugitive`,
`sindrets/diffview.nvim`, `ruifm/gitlinker.nvim` (+ `nvim-lua/plenary.nvim`).
**Files:** `lua/config/{gitsigns,fugitive,diffview,git-linker}.lua`.

`fugitive` and `gitlinker` load on **`User InGitRepo`** — a custom event that only
fires because `utils.inside_git_repo()` runs from the `git_repo_check` autocmd
added in Stage 2. If the git maps do nothing, check that first; `:Lazy` will show
them as never-loaded. (Verified working: both load in this repo.)

| Keys | What |
|---|---|
| `]c` `[c` | next / previous hunk |
| `<leader>hp` `<leader>hb` | preview hunk · blame line |
| `<leader>hs` `<leader>hr` | stage / reset hunk (also visual, on the selection) |
| `<leader>hu` `<leader>hS` `<leader>hR` | undo stage · stage buffer · reset buffer |
| `<leader>gs` `gw` `gc` `gpl` `gpu` `gf` | fugitive: status · add · commit · pull · push · fetch |
| `<leader>gbn` `<leader>gbd` | new / delete branch (both prompt) |
| `<leader>gb` *(visual)* | blame the selection |
| `<leader>gl` `<leader>gbr` | permalink to line · open repo in browser |
| `:DiffviewOpen` · `]C` `[C` · `<leader>gC{t,o,a}` | diff view, conflict nav, choose theirs/ours/both |

Corrections to what this section used to say:

| Claim | Reality |
|---|---|
| "gitsigns config maps hunk navigation **and staging**" | The target maps `]c`/`[c`, `<leader>hp` and `<leader>hb` and **nothing else** — no staging at all, which is the main reason to run gitsigns. `<leader>h{s,r,u,S,R}` were added here, including visual-range stage/reset |
| "`<leader>gb` (visual blame) will wait for `timeoutlen` because `gbn`/`gbd`/`gbl`/`gbr` share its prefix" | **They do not compete — the modes differ.** `<leader>gb` is visual-only; `gbn`, `gbd`, `gbl` and `gbr` are all normal-mode. Verified: in visual mode the only `<leader>g` maps are `gb` and `gl`, so blame fires immediately |

Other changes from the target:

| Change | Why |
|---|---|
| **gitlinker declares `plenary.nvim`** | It requires plenary (`gitlinker/git.lua:3`). The target only gets it because **neogit** lists plenary as a dependency — dropping neogit without this would have broken `<leader>gl` at keypress time, not at startup |
| **neogit and vim-flog skipped** | neogit is a magit-style UI that overlaps fugitive almost entirely; this section already recommended picking one |
| **diffview also loads on `:DiffviewFileHistory`** | The target only lists `cmd = { "DiffviewOpen" }`, so the file-history command would not load the plugin |
| **gitsigns gets its own gutter cell**: `lua/statuscolumn.lua` (new) + `signcolumn = "no"` / `statuscolumn` in `options.lua` | Signs share one native column and `%s` packs them left, so gitsigns -- the lowest-priority producer at **6**, against diagnostics **13** and lightbulb 10 -- was never drawn on a line that also had a diagnostic. Raising the priority and widening to `yes:2` was tried first and is **not** sufficient: priority decides the *order* signs are drawn in, not which cell they land in, so a line with a diagnostic and no git change still put the diagnostic in cell 1. `statuscolumn.lua` renders two fixed cells instead -- cell 1 is gitsigns and nothing else, blank when the line is unchanged; cell 2 is everything else, highest priority first -- then the line number (`relativenumber` included, since setting `'statuscolumn'` replaces the whole gutter). Both cells are padded to a fixed display width (git glyphs are 1 cell, the diagnostic/lightbulb emoji are 2) or the number column shifts. Measured: `'~🆇    9 '` git+diagnostic, `' ⚠️  12 '` diagnostic only, `'     15 '` neither -- all width 8. gitsigns namespaces are matched by name prefix, not by taking the first `pairs()` hit: there are several (`gitsigns_signs_`, staged, blame) and the iteration order is undefined. nvim-tree, quickfix and help keep their own gutters -- the module returns early for any `buftype ~= ""` |

**Verify:** confirmed working — in a tracked file with buffer-only edits, gitsigns
reports `head=main added=2 changed=1`, the gutter shows `+` and `~` from
`symbol_icon.git.diff`, and **lualine's diff section renders `+2 ~1`** — the
component that had been inert since Stage 8 now has its data source. All nine
hunk maps are buffer-local; all eight fugitive maps and both gitlinker maps exist.

---

### Stage 10 — Navigation, outline, quickfix ✅ done

**Plugins:** `nvim-tree/nvim-tree.lua` (landed in Stage 3), `stevearc/aerial.nvim`,
`smoka7/hop.nvim`, `kevinhwang91/nvim-hlslens`, `kevinhwang91/nvim-bqf`,
`dnlhc/glance.nvim`, `kosayoda/nvim-lightbulb`,
`RRethy/vim-illuminate`.

| Keys | What |
|---|---|
| `f` + 2 chars | hop: jump anywhere on screen (normal, visual, operator-pending) |
| `n` `N` `*` `#` | hlslens: same motions, with a `[1/2]` counter at the match |
| `[t` `]t` · `<leader>to` | aerial: prev/next symbol (buffer-local) · toggle outline |
| `<leader>gd` `gr` `gi` | glance: peek definitions / references / implementations |
| `<leader>ee` `ef` `ec` | nvim-tree: toggle · focus · change root (Stage 3) |
| in `qf` | bqf preview |

Everything except nvim-tree and vim-illuminate is lazy — `keys`, `cmd` or
`ft = "qf"` triggers — so none of them costs anything at startup.

Changed from the target:

| Change | Why |
|---|---|
| **`stevearc/quicker.nvim` removed** | Adopted during this stage, then dropped. It made the quickfix list a modifiable buffer so `:w` wrote edits back across every file in it -- verified working before removal. Noted here because the target ships it with `edit = { enabled = false }`, which switches off that single feature; anyone re-adopting it needs `edit = { enabled = true }` |
| **`vim-illuminate` allowlist rewritten** | The target's list is `go java javascript json lua python sh toml typescript yaml` — **no `nix`**, the language this repo is mostly written in. go and java dropped; nix, elm, css, html and markdown added |
| **`<space>t` → `<leader>to`**, **`<space>gd/gr/gi` → `<leader>gd/gr/gi`** | Bare `<space>` collides with the leader. See §4. The glance maps share the `<leader>g` namespace with fugitive but collide with none of them |
| **hop declares its modes** | `keys = { { "f", mode = { "n", "x", "o" } } }` rather than bare `keys = { "f" }`, so the lazy stub exists in operator-pending too and `df<2 chars>` works on first press |
| **aerial declares nvim-treesitter** | It is aerial's symbol backend until the LSP rebuild lands |

> **`f` is now hop, not vim's within-line find.** `F`, `t` and `T` are untouched
> (verified). `;`-as-f-repeat was already gone — Stage 1 made `;` = `:` — so these
> two changes do go together, as this section said.

`hlslens` needs `shortmess+=S` or nvim prints its own search count over the
virtual text; `options.lua:167` already appends `cS`.

`bqf` brings the preview pane (`auto_preview = false`, so press `p`). The quickfix
list is read-only again now that quicker is gone -- use `:cdo` for bulk edits.

**Verify:** confirmed working, driven against a live instance — `f` then `fo`
moved the cursor from `{1,0}` to `{2,11}`, landing on `foxtrot` two lines down;
`/alpha` then `n` renders `[1/2]` beside the match. All eight plugins present,
0 errors, `F`/`t`/`T` still vim's.

---

### Stage 11 — Text objects and editing power ✅ done

Eleven of twelve adopted. Mostly `init`-only plugins; only live-command has a
config file.

| Plugin | Gives you |
|---|---|
| `wellle/targets.vim` | `ci,` `da(` `in[` — arguments, next/last variants of every pair |
| `machakann/vim-sandwich` | `sa`/`sd`/`sr` add/delete/replace pairs. Maps `s` to `<Nop>` — use `cl` |
| `windwp/nvim-autopairs` | Auto-close brackets and quotes |
| `tpope/vim-commentary` | `gcc`, `gc{motion}` |
| `tpope/vim-repeat` | Makes `.` work with the above |
| `tpope/vim-eunuch` | `:Rename`, `:Delete`, `:Move`, `:Chmod`, `:Mkdir` |
| `smjonas/live-command.nvim` | Live preview of `:Norm`, `:g`, `:s` |
| `chrisbra/unicode.vim` | `ga` → what character is this |
| `nvim-zh/whitespace.nvim` | Trailing-space highlight + `:StripTrailingWhitespace` |
| `nvim-zh/better-escape.vim` | `jk` to leave insert mode (200ms) |
| `itchyny/vim-highlighturl` | Underlines URLs |

**`<leader><space>` is no longer parked.** whitespace.nvim provides
`:StripTrailingWhitespace`, so the last deferred mapping in `lua/mappings.lua` is
live and that file has no commented-out section left.

`vim-highlighturl` also improves Stage 2's `iu` text object: `text_obj#URL()`
checks the runtimepath for it and uses its URL pattern, falling back to an
`expand('<cfile>')` length heuristic when absent.

Changed from the target:

| Change | Why |
|---|---|
| **`gbprod/yanky.nvim` removed** | Adopted during this stage, then dropped. It remapped `p`/`P` and added a `[y`/`]y` yank ring; `p`/`P` are vim's own again. Two bugs found in the target's version while it was in, kept here as a record: it maps `p`/`P` in `{ "n", "x" }`, which would have silently taken over the visual `p` (`"_c<Esc>p`) chosen in Stage 1; and `cmd = "YankyRingHistory"` was its only load trigger, so the maps and the yank-recording autocmd never existed until that command was run by hand — **the plugin was inert as shipped** |
| **`vim-eunuch` and `unicode.vim` list more triggers** | The target loads eunuch only on `:Rename`/`:Delete`, so `:Move`/`:Chmod`/`:Mkdir` never loaded it; unicode.vim had no trigger for `ga` at all |

**Verify:** confirmed working — `saiw"` turned `word here` into `"word" here`;
`s` is `<Nop>` with
`sa`/`sd`/`sr` live; `<leader><space>` resolves to `:StripTrailingWhitespace`
and the command exists; `:Norm` appears once `CmdlineEnter` loads live-command.

---

### Stage 12 — Filetype layer ✅ done

**Taken from `after/ftplugin/`** (11 of 18): `lua.lua`, `vim.vim`, `markdown.vim`,
`json.lua`, `yaml.vim`, `toml.vim`, `gitconfig.vim`, `text.vim`, `help.lua`,
`man.lua`, `qf.vim`. Plus `.stylua.toml` and `ftdetect/pdc.vim`.

**Skipped:** `python.lua`, `go.lua`, `cpp.vim`, `tex.lua`, `sql.vim`,
`javascript.vim`, `markdown.lua` — languages not in use here. `ftdetect/snippets.vim`
and `my_snippets/` go with **ultisnips**, which needs the python3 provider that
`globals.lua` disables; `friendly-snippets` (Stage 5) covers snippets instead.
`_typos.toml` needs typos-lsp and `.emmyrc.json` needs emmylua_ls — neither installed.

**Plugins:** `MeanderingProgrammer/render-markdown.nvim` (ft-lazy),
`godlygeek/tabular` (cmd-lazy), `vim-pandoc/vim-markdownfootnotes` (ft-lazy).
The footnote plugin is what activates the guarded `^^`/`@@` block already in
`markdown.vim`.

Changed from the target:

| Change | Why |
|---|---|
| **`set` → `setlocal` in all four `.vim` ftplugins** | Every option they touch (`formatoptions`, `keywordprg`, `concealcursor`, `synmaxcol`, `wrap`, `colorcolumn`, `commentstring`) is buffer- or window-local, so plain `set` also writes the **global** default and leaks it to other buffers. **Confirmed**: opening one `.vim` file left `keywordprg` as `:help` globally — it had been `:Man`. With `setlocal` it returns to `:Man` on leaving the buffer |
| **`vim.vim` loses its fold settings** | It sets `foldmethod=expr` with `utils#VimFolds`. Held back because nvim-ufo owned folding globally and set `foldmethod=manual`. **ufo has since been removed**, so `.vim` buffers now have no automatic folding at all; `utils#VimFolds`/`utils#MyFoldText` are still in `autoload/utils.vim` and the three `setlocal` lines needed to restore them are noted in `after/ftplugin/vim.vim` |
| **`q` added to `help.lua` and `qf.vim`** | The target only restores `q`-to-close for **man** pages. Stage 1's global `q` reminder cost it in help and quickfix too; these are the same buffer-local fix. The global mapping, and `Q` for macros, are untouched |
| **`<Space>f` → `<leader>lf` in `lua.lua` and `json.lua`** | Bare `<space>` collides with the leader (§4). Both are buffer-local, so they shadow the global `<leader>lf` (`vim.lsp.buf.format`) only for those filetypes — stylua for lua, `:JSONFormat` for json |
| **`checktime` added after stylua** | stylua rewrites the file on disk behind nvim's back. Without it the buffer shows stale text until the `auto_read` autocmd happens to fire |

> `markdown.vim` rebinds `ic`/`ac` buffer-locally to `text_obj#MdCodeBlock`
> (Stage 2), shadowing treesitter-textobjects' class objects. That is deliberate
> — "class" means nothing in markdown, "code block" does.

**Verify:** confirmed working — in a `.lua` buffer `<leader>lf` is buffer-local
and runs stylua + `checktime`, `<F9>` is `:luafile %`, `formatoptions` is `qlcj`
(no `o`/`r`); `q` is buffer-local `<cmd>quit<CR>` in **both** help and quickfix;
the quickfix window opens 5 lines high; `.vim` buffers get `keywordprg=:help`
and `<F9>` `:source %` with `foldmethod=manual`; markdown gets buffer-local
`ic`/`ac`, the `+` list operator, `wrap`, and render-markdown loaded.

---

### Stage 13 — Optional and skipped ✅ done

**Adopted:** `catgoose/nvim-colorizer.lua`, `tpope/vim-scriptease`,
`tpope/vim-obsession`. (`tadaa/vimade` was adopted here too, then removed -- see below.) (`plugin/log-autocmds.vim` and `resources/head.tex` came
earlier, with Stage 2.)

| Plugin / file | Why it's here | Verdict |
|---|---|---|
| `catgoose/nvim-colorizer.lua` | Renders colour literals | ✅ — this repo has several CSS files plus hex colours through the nvim config |
| `tadaa/vimade` | Dims inactive windows | **removed** -- ran with `fadelevel = 0.5` and animation off, then dropped |
| `tpope/vim-scriptease` | `:Messages`, `:Scriptnames`, `:Verbose` | ✅ cmd-lazy |
| `tpope/vim-obsession` | `:Obsess` session recording | ✅ cmd-lazy |
| `glacambre/firenvim` | Edit browser textareas | skip — `enabled` win/mac only |
| `chrishrb/gx.nvim` | Open URL under cursor | skip — **`gx` is a builtin in nvim 0.12** (`vim/_core/defaults:157`), verified mapped out of the box |
| `lervag/vimtex` | LaTeX authoring | skip. `:ToPDF` + `resources/head.tex` were taken in Stage 2 and error cleanly without pandoc |
| `iron.lua` | Python REPL | skip — needs the python3 provider `globals.lua` disables |
| `lyokha/vim-xkbswitch`, `Neur1n/neuims` | IME switching | skip — mac/win only |
| `ojroques/vim-oscyank` | Clipboard over SSH | skip — nvim has OSC52 builtin |
| `esmuellert/codediff.nvim` | `:CodeDiff` | skip — diffview (Stage 9) covers it |
| `skywind3000/asyncrun.vim` | `:AsyncRun` into quickfix | skip — `:Run` (Stage 2) and `vim.system` cover it |
| `nickjvandyke/opencode.nvim` | opencode agent integration | skip |
| `mg979/vim-visual-multi` | Multi-cursor | skip — commented out upstream too |
| `lua/dotenv.lua` | Reads `~/.config/.env` | skip — nothing requires it |

> **colorizer only highlights the visible viewport.** It will look broken if you
> test it headlessly or with the cursor away from the colours — `is_buffer_attached`
> returns true while the namespace holds zero extmarks. Verified in a real
> terminal: with the cursor on `custom-autocmd.lua:190` the namespace holds 3
> extmarks (`hl = colorizer_mb_34495e`). `names` parsing is off, so the word
> "red" in prose is not highlighted.

**Verify:** `:Messages` and `:Obsess` exist; colour literals render in `.css` and
in the config's own hex values; inactive windows dim.

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
| ~~`<space>s` nvim-tree toggle~~ | `config/nvim-tree.lua:5` | resolved — see below |
| `<space>t` aerial toggle | `config/aerial.lua` | — |
| `<space>bp` bufferline pick | `config/bufferline.lua` | — |
| `<space>gd`/`gr`/`gi` glance | `config/glance.lua` | shares `<leader>g` with fugitive (resolvable) |

**Rule: translate every bare `<space>X` into a two-key `<leader>` sequence.**
Never leave a one-key `<leader>` mapping that is a prefix of another.

Suggested scheme — LSP under `l`, diagnostics under `d`, toggles under `t`:

| Target | Use instead | What |
|---|---|---|
| `<space>rn` | `<leader>lr` | rename ✅ |
| `<space>ca` | `<leader>la` | code action ✅ |
| `<space>wa` / `wr` / `wl` | `<leader>lwa` / `lwr` / `lwl` | workspace folders ✅ |
| `<Space>f` (stylua) | `<leader>lf` | format buffer ✅ (via `vim.lsp.buf.format`) |
| `<space>qw` | `<leader>dw` | window diagnostics → quickfix ✅ |
| `<space>qb` | `<leader>db` | buffer diagnostics → quickfix ✅ |
| `<space>s` | `<leader>ee` / `<leader>ef` / `<leader>ec` | nvim-tree toggle / focus / change root ✅ |
| `<space>t` | `<leader>to` | aerial outline ✅ |
| `<space>bp` | `<leader>tb` | bufferline pick ✅ |
| `<space>gd` / `gr` / `gi` | `<leader>gd` / `gr` / `gi` | glance ✅ — no conflict with fugitive's `<leader>g*` |

Keep from the previous config, unchanged: `<leader>w` save, `<leader>ff` /
`<leader>fg` find, `<leader>p` paste.

> The previous config's `<leader>e` focus / `<leader>ee` toggle is itself an instance
> of the rule above: the one-key map is a prefix of the two-key one, so it only fires
> after `timeoutlen`. Hence `<leader>e{e,f,c}` with no bare `<leader>e`.

Mappings that **don't** involve leader and transplant verbatim:
`gd`, `K`, `<C-k>`, `<C-]>` (LSP) · `[t`/`]t` (aerial) ·
`gS` (treesj) · `f` (hop) ·
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
| iron.nvim + `utils.get_py_env`/`get_py_cmd` | Python REPL | Skip. **`get_virtual_env` is the exception** — it was taken, and backs the venv component in `lualine.lua` (Stage 8). The other two are REPL-only |
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
| `lua/plugins/lsp.lua` | nixd flake-options settings | ✅ `after/lsp/nixd.lua` (+ `after/lsp/elmls.lua`) |
| `lua/highlights.lua` | transparent `Normal`/`NormalNC`/`SignColumn` | ✅ `ui.lua`, moves to the `ColorScheme` autocmd in Stage 1 |
| `lua/commands.lua` | `:Run` — detached `jobstart` | ✅ `plugin/command.lua` |
| `lua/keymaps.lua` | `<leader>k` opens kitty in cwd; `<A-j>` to escape insert | `mappings.lua` (Stage 1) — note better-escape.vim (Stage 11) does `jk` instead |
| `lua/plugins/nvimtree.lua` | diagnostic icons in the tree | ✅ `config/nvim-tree.lua` |

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
