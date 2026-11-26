{ pkgs-unstable, ... }:

{
  environment.systemPackages = [ pkgs-unstable.claude-code ];

  my.links = {
    ".claude/keybindings.json" = "claude/keybindings.json";
    ".claude/statusline.sh" = "claude/statusline.sh";
  };
}
