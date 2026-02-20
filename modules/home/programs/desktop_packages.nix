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
      curl
      jq
      docker

      # Terminals & CLI utilities
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
      mangohud
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      vesktop
      spicetify-cli
      netflix
      localsend

      # Theming
      matugen
      bibata-cursors
      nerd-fonts.jetbrains-mono
      adwaita-icon-theme
      adwsteamgtk
      nwg-look
      adw-gtk3
      libsForQt5.qt5ct
      kdePackages.qt6ct

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
      vscodium

      # Virtualization
      virt-manager
    ];
  };
}
