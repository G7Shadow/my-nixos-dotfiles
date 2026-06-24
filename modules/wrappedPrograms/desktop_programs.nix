{ ... }:
{
  flake.nixosModules.desktop-packages =
    { pkgs, inputs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [
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

        brightnessctl
        lm_sensors
        ffmpeg
        pulsemixer
        pwvucontrol
        imagemagick
        obs-studio
        feh
        thunar
        file-roller

        waybar
        hyprpaper
        hyprlock
        hypridle
        wlogout
        waypaper
        rofi
        inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
        swaynotificationcenter
        wl-clipboard
        cava
        mangohud
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        vesktop
        spotify
        obsidian
        netflix
        localsend
        prismlauncher
        zed-editor

        matugen
        bibata-cursors
        nerd-fonts.jetbrains-mono
        rubik
        noto-fonts-cjk-sans
        adwaita-icon-theme
        (papirus-icon-theme.override { color = "black"; })
        adwsteamgtk
        nwg-look
        adw-gtk3
        libsForQt5.qt5ct
        kdePackages.qt6ct
        pywalfox-native

        playerctl
        nitch
        fastfetch
        protonup-ng
        hyprshutdown

        vscode-langservers-extracted
        lua-language-server
        typescript-language-server
        nil
        clang-tools
        hyprls
        pyright
        tree-sitter
        kdePackages.qtdeclarative

        virt-manager
      ];
    };
}
