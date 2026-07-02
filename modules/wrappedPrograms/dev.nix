{ self, ... }:
{
  flake.nixosModules.dev =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      wrappedGit = self.packages.${pkgs.system}.git;
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
        gnumake
        nodejs
        unzip
        wrappedGit
        curl
        jq
        docker

        vscode-langservers-extracted
        lua-language-server
        typescript-language-server
        nil
        nixd
        clang-tools
        hyprls
        pyright
        tree-sitter
        kdePackages.qtdeclarative
      ];
    };
}
