{ pkgs, ... }:

let
  commonAliases = {
    # File listing
    ll = "ls -l";
    la = "ls -la";
    l = "ls -CF";

    # Editor
    v = "vim";
    sv = "sudo vim";

    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";

    # Git
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
in
{
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

    shellAliases = commonAliases;
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = commonAliases;
  };
}

