{ inputs, ... }: {
  flake.nixosModules.lf = { pkgs, config, ... }: let
    user = config.preferences.user.name;
    direnv = pkgs.direnv;
    bat = pkgs.bat;
    ripdrag = pkgs.ripdrag;

    cfg = pkgs.writeText "lf-config" ''
      set reverse true
      set preview true
      set hidden true
      set drawbox true
      set icons true
      set ignorecase true

      map "\""
      map o
      map d
      map e
      map f
      map . set hidden!
      map D delete
      map p paste
      map dd cut
      map y copy
      map ` mark-load
      map \' mark-load
      map <enter> open
      map a rename
      map r reload
      map C clear
      map U unselect

      map do drag-out

      map g~ cd
      map gh cd
      map g/ /
      map gd cd ~/Downloads
      map gt cd /tmp
      map gv cd ~/Videos
      map go cd ~/Documents
      map gc cd ~/.config
      map gn cd ~/nixconf
      map gp cd ~/Projects
      map gs cd ~/.local/share
      map gm cd /run/media

      map eE $ $EDITOR "$f"
      map ee $ ${direnv}/bin/direnv exec . $EDITOR "$f"
      map e. $ ${direnv}/bin/direnv exec . $EDITOR .
      map V $ ${bat}/bin/bat --paging=always --theme=gruvbox "$f"
      map do $ ${ripdrag}/bin/ripdrag -a -x "$fx"

      map <C-d> 5j
      map <C-u> 5k

      setlocal ~/Projects sortby time
      setlocal ~/Projects/* sortby time
      setlocal ~/Downloads/ sortby time
    '';

    wrapped-lf = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.lf;
      flags = {
        "-config" = "${cfg}";
      };
    };
  in {
    hjem.users."${user}".packages = [ wrapped-lf ];
  };
}
