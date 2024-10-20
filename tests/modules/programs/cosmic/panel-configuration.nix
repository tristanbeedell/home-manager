{ pkgs, ... }:

{
  config = {
    programs.cosmic = {
      enable = true;
      panels = {
        Panel = {
          applets = {
            start = [ "com.system76.CosmicAppletWorkspaces" ];
            end = [
              "com.system76.CosmicAppletTime"
              "com.system76.CosmicAppletAudio"
            ];
          };
          options = {
            anchor = "Top";
            output = "DP-1";
            autohide.enable = true;
          };
        };
        Dock = { applets = { center = [ "com.system76.CosmicAppList" ]; }; };
      };
    };

    nmt.script = ''
      config=home-files/.config/cosmic/com.system76.CosmicPanel/v1
      panel=home-files/.config/cosmic/com.system76.CosmicPanel.Panel/v1
      dock=home-files/.config/cosmic/com.system76.CosmicPanel.Dock/v1

      assertFileContent \
        $config/entries \
        ${pkgs.writeText "entries" ''["Dock","Panel"]''}

      assertFileContent \
        $panel/name \
        ${pkgs.writeText "plugins_wings" ''"Panel"''}

      assertFileContent \
        $panel/plugins_wings \
        ${
          pkgs.writeText "plugins_wings" ''
            Some((["com.system76.CosmicAppletWorkspaces"],["com.system76.CosmicAppletTime","com.system76.CosmicAppletAudio"]))''
        }

      assertFileContent \
        $dock/plugins_center \
        ${
          pkgs.writeText "plugins_center"
          ''Some(["com.system76.CosmicAppList"])''
        }

      assertFileContent \
        $dock/keyboard_interactivity \
        ${pkgs.writeText "keyboard_interactivity" "None"}

      assertFileContent \
        $panel/output \
        ${pkgs.writeText "output" ''Name("DP-1")''}

      assertFileContent \
        $dock/output \
        ${pkgs.writeText "output" "All"}

      assertFileContent \
        $panel/autohide \
        ${
          pkgs.writeText "autohide"
          "Some((handle_size: 4, transition_time: 200, wait_time: 1000))"
        }

      assertFileContent \
        $dock/autohide \
        ${pkgs.writeText "autohide" "None"}
    '';
  };
}
