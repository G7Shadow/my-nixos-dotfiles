{
  flake.homeModules.desktop_packages = {
    pkgs,
    inputs,
    ...
  }: {
    home.packages = with pkgs; [
      # Dev tools
      alejandra
      cmake
      gcc
      opencode
      gnumake
      nodejs
      unzip
      git
      jq
      docker

      # Terminals & CLI utilities
      alacritty
      kitty
      htop
      btop
      lsof
      tree
      wget
      zoxide
      ripgrep
      fzf
      bat
      eza
      fd
      tmux

      # Media & system utilities
      libva
      libva-utils
      brightnessctl
      lm_sensors
      ffmpeg
      pulsemixer
      pwvucontrol
      imagemagick
      obs-studio
      feh
      nautilus
      mesa

      # Desktop tools (Wayland environment)
      waybar
      hyprpaper
      wlogout
      rofi
      swww
      swaynotificationcenter
      wl-clipboard
      cava
      nwg-look
      gamemode
      mangohud
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      vesktop
      spotify
      netflix

      # Theming
      pywal
      matugen
      bibata-cursors
      nerd-fonts.jetbrains-mono
      adwaita-icon-theme
      nwg-look

      # Misc
      playerctl
      nitch
      fastfetch
      protonup-ng

      # Language servers
      vscode-langservers-extracted
      lua-language-server
      typescript-language-server
      nil
      hyprls
      pyright

      # Editors
      vscode

      # Virtualization
      virt-manager
    ];
  };
}
