-- Parsers and queries come from nix, not from nvim-treesitter.
--
-- The `main` branch installs parsers by shelling out to `tree-sitter build`
-- (install.lua:305), which needs the tree-sitter CLI and a C compiler. Neither is
-- installed. Instead home.nix builds them from nixpkgs' prebuilt grammars and
-- symlinks them into ~/.local/share/nvim/site/{parser,queries} -- which is
-- nvim-treesitter's own default install_dir, and one of the few paths that
-- survives lazy.nvim's runtimepath rebuild.
--
-- So this file only has to start treesitter; there is nothing to install.
-- `nvim-treesitter.install()` and `get_available()` are deliberately unused.

-- Filetypes to enable treesitter for. `vim.treesitter.language.get_lang` maps
-- each to a language; the grammar list lives in home.nix and must cover it.
-- lua, markdown, markdown_inline, query, vim and vimdoc are bundled with Neovim
-- and need nothing from nix.
local enabled_filetypes = {
  "nix",
  "lua",
  "markdown",
  "json",
  "toml",
  "yaml",
  "css",
  "sh",
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = enabled_filetypes,
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  desc = "start treesitter highlighting",
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)

    if lang == nil then
      return
    end

    -- `language.add` returns false when no parser/<lang>.so is on the rtp.
    -- Stay quiet about it: a missing grammar means adding it to
    -- `treesitterLangs` in home.nix and rebuilding, not a runtime error.
    if not vim.treesitter.language.add(lang) then
      return
    end

    vim.treesitter.start(args.buf, lang)

    -- Folding and treesitter indent stay off until nvim-ufo lands in Stage 8:
    -- vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    -- vim.wo[0][0].foldmethod = "expr"
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
