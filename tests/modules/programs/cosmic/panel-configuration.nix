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
          options = { anchor = "Top"; };
        };
        Dock = { applets = { center = [ "com.system76.CosmicAppList" ]; }; };
      };
    };

    nmt.script = ''

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicPanel/v1/entries \
        ${pkgs.writeText "entries" ''["Dock","Panel"]''}

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicPanel.Panel/v1/name \
        ${pkgs.writeText "plugins_wings" ''"Panel"''}

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings \
        ${
          pkgs.writeText "plugins_wings" ''
            Some((["com.system76.CosmicAppletWorkspaces"],["com.system76.CosmicAppletTime","com.system76.CosmicAppletAudio"]))''
        }

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicPanel.Dock/v1/plugins_center \
        ${
          pkgs.writeText "plugins_center"
          ''Some(["com.system76.CosmicAppList"])''
        }

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicPanel.Dock/v1/keyboard_interactivity \
        ${pkgs.writeText "keyboard_interactivity" "None"}
    '';
  };
}
