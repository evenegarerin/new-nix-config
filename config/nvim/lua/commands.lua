vim.api.nvim_create_user_command("Run", function(opts)
  local cmd = opts.args

  if cmd == "" then
    print("No command provided")
    return
  end

  vim.fn.jobstart(cmd, {
    detach = true,
    stdout = "null",
    stderr = "null",
  })
end, {
  nargs = "+",
})