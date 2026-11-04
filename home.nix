{
  pkgs,
  lib,
  username ? "ratul",
  ...
}:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Rezwan Ahmed Ratul";
        email = "rezwanahmedratul007@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      # Standard file listing
      ll = "ls -l";
      la = "ls -la";
      l = "ls -CF";

      # Editor aliases
      v = "vim";
      sv = "sudo vim";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";

      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gb = "git branch";

      # Nix maintenance
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d";
      nr = "sudo nixos-rebuild switch";
    };
  };

  # Bash configuration with matching aliases
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      l = "ls -CF";
      v = "vim";
      sv = "sudo vim";
      ".." = "cd ..";
      gs = "git status";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d";
    };
  };
}
