{ self, ... }:
{
  flake.homeModules.desktop-packages =
    {
      pkgs,
      inputs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        # Dev tools
        alejandra
        cmake
        gcc
        (python3.withPackages (
          ps: with ps; [
            pygobject3
            gst-python
          ]
        ))
        opencode
        ntfs3g
        gvfs
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
        lazygit
        tmux
        ryzenadj
        radeontop

        # Media & system utilities
        libva
        libva-utils
        libvdpau
        libvdpau-va-gl
        libva-vdpau-driver
        brightnessctl
        lm_sensors
        ffmpeg
        pulsemixer
        pwvucontrol
        imagemagick
        obs-studio
        feh
        nautilus
        file-roller
        mesa

        # Desktop tools (Wayland)
        waybar
        hyprpaper
        hyprlock
        hypridle
        wlogout
        waypaper
        rofi
        inputs.awww.packages.${stdenv.hostPlatform.system}.awww
        swaynotificationcenter
        wl-clipboard
        cava
        mangohud
        inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
        vesktop
        spotify
        obsidian
        netflix
        localsend
        prismlauncher

        # Theming
        matugen
        bibata-cursors
        nerd-fonts.jetbrains-mono
        rubik
        noto-fonts-cjk-sans
        adwaita-icon-theme
        papirus-icon-theme
        adwsteamgtk
        nwg-look
        adw-gtk3
        libsForQt5.qt5ct
        kdePackages.qt6ct
        pywalfox-native

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
        tree-sitter

        # Virtualization
        virt-manager
      ];
    };
}
