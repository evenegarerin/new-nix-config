{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    interactiveShellInit = ''
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      zvm_after_init_commands+=("source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh")
    '';
  };

  my.links.".zshrc" = "zsh/.zshrc";
}
