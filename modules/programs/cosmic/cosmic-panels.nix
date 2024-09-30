{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  inherit (types) attrsOf submodule;

  ron = import ./ron.nix { inherit lib; };
  cfg = config.programs.cosmic;

  mapApplets = applets: {
    plugins_wings = ''
      Some(${ron.tuple [
        (ron.stringArray applets.start)
        (ron.stringArray applets.end)
      ]})'';
    plugins_center = "Some(${ron.stringArray applets.center})";
  };
  mapPanel = panel: panel.options // mapApplets panel.applets;
  mapPanels = panels:
    builtins.listToAttrs (map (name: {
      name = "com.system76.CosmicPanel.${name}";
      value.options = mapPanel panels.${name} // { inherit name; };
    }) (builtins.attrNames panels));
in {
  options.programs.cosmic = {
    panels = mkOption {
      default = { };
      example = lib.literalExpression ''
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
      '';
      type = attrsOf (submodule {
        options = {
          applets = mkOption {
            default = { };
            description = ''
              Find applets here: https://github.com/pop-os/cosmic-applets
            '';
            type = submodule {
              options = {
                start = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                center = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                end = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
            };
          };
          options = mkOption {
            default = { };
            type = attrsOf types.anything;
            description = ''
              Set of options defined here: https://github.com/pop-os/cosmic-panel/blob/0ce85da198f02f94ad75441e64c0e165c41eb4ae/cosmic-panel-config/src/panel_config.rs#L299
            '';
          };
        };
      });
    };

  };
  config = {
    programs.cosmic.settings = {
      "com.system76.CosmicPanel".options.entries =
        ron.stringArray (builtins.attrNames cfg.panels);
    } // mapPanels cfg.panels;
  };
}
