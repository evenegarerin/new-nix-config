{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "history"
        "command-not-found"
      ];
      theme = "af-magic";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.variables.BROWSER = "firefox";
  environment.variables.Term = "kitty";
}
