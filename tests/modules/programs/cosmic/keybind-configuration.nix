{ pkgs, ... }: {
  config = {
    programs.cosmic = {
      enable = true;
      input = {
        keybindings = [
          {
            modifiers = [ "Super" ];
            key = "g";
            action = "Disable";
          }
          {
            modifiers = [ "Super" "Shift" ];
            key = "g";
            action = "ToggleWindowFloating";
          }
          {
            modifiers = [ "Super" ];
            key = "Return";
            action = "Spawn";
            value = pkgs.writeShellScriptBin "script" "";
          }
          {
            modifiers = [ "Super" ];
            key = "1";
            action = "Workspace";
            value = 1;
          }
        ];
      };
    };

    nmt.script = ''
      assertFileContent home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom ${
        ./keybinds.ron
      }
    '';
  };
}
