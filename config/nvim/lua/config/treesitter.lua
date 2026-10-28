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

    if not vim.treesitter.language.add(lang) then
      return
    end

    vim.treesitter.start(args.buf, lang)
  end,
})
