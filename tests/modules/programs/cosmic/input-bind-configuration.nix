{ pkgs, ... }: {
  config = {
    programs.cosmic = {
      enable = true;
      input = {
        binds = [
          {
            modifiers = [ "Super" ];
            key = "1";
            action = "Workspace";
            value = 1;
          }
          {
            modifiers = [ "Super" "Shift" ];
            key = "1";
            action = "MoveToWorkspace";
            value = 1;
          }
          {
            modifiers = [ "Super" "Shift" ];
            key = "h";
            action = "Move";
            value = "Left";
          }
          {
            modifiers = [ "Super" "Shift" ];
            key = "q";
            action = "Close";
          }
          {
            modifiers = [ "Super" ];
            key = "Space";
            action = "ToggleTiling";
          }
          # this test was flakey because the hash kept changing
          # {
          #   modifiers = [ "Super" ];
          #   key = "a";
          #   action = "Spawn";
          #   value = (pkgs.writeShellScriptBin "my-script" "");
          # }
          {
            modifiers = [ "Super" ];
            key = "h";
            action = "Focus";
            value = "Left";
          }
          {
            modifiers = [ "Super" ];
            key = "o";
            action = "System";
            value = "HomeFolder";
          }
        ];
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom \
        ${./keybinds.ron}
    '';
  };
}
