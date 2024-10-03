{ pkgs, config, ... }:
let inherit (config.lib.cosmic) Actions;
in {
  config = {
    programs.cosmic = {
      enable = true;
      input = {
        binds = {
          Super.h = Actions.Focus "Left";
          Super.Shift.h = Actions.Move "Left";
          Super.Space = Actions.ToggleTiling;
          Super.Shift.q.action = "Close";
          Super.a = Actions.Spawn (pkgs.writeShellScriptBin "my-script" "");
          Super."1" = Actions.Workspace 1;
          Super.Shift."1" = Actions.MoveToWorkspace "1";
          Super."o" = Actions.System "HomeFolder";
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom \
        ${./keybinds.ron}
    '';
  };
}
