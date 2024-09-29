{
  config = {
    programs.cosmic = {
      enable = true;
      keybindings = [
      {
        modifiers = ["Super"];
        key = "G";
        action = "Disable";
      }
      {
        modifiers = ["Super" "Shift"];
        key = "G";
        action = "ToggleWindowFloating";
      }
      {
        modifiers = ["Super"];
        key = "Return";
        action = {
          type = "Spawn";
          data = "kitty";
        };
      }
      ];
    };

    nmt.script = ''
      assertFileContent home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom ${./keybinds.ron}
    '';
  };
}
