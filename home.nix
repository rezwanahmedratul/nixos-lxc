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

  # Git configuration (modern Home Manager syntax)
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
      # Modern file listing
      ll = "eza -l --icons";
      la = "eza -la --icons";
      ls = "eza --icons";
      lt = "eza --tree --level=2 --icons";

      # Modern pager
      cat = "bat";

      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gb = "git branch";

      # Editor aliases
      v = "nvim";
      sv = "sudo nvim";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";

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
      ll = "eza -l --icons";
      la = "eza -la --icons";
      ls = "eza --icons";
      cat = "bat";
      gs = "git status";
      v = "nvim";
      sv = "sudo nvim";
      ".." = "cd ..";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d";
    };
  };

  # Starship cross-shell prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # Zoxide smart directory jumping
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # Fzf fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # Bat cat-clone with syntax highlighting
  programs.bat.enable = true;

  # Eza modern ls-replacement
  programs.eza.enable = true;

  # Additional user packages
  home.packages = with pkgs; [
    fastfetch
    htop
    btop
    ripgrep
    fd
    jq
    tmux
  ];
}
