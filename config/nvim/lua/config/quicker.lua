require("quicker").setup {
  -- NOTE: the target sets this to false, which switches off the one feature
  -- quicker exists for -- editing the quickfix list and `:w` to apply the
  -- changes across every file in it.
  edit = {
    enabled = true,
  },
  max_filename_width = function()
    return math.floor(math.min(40, vim.o.columns / 2))
  end,
}
