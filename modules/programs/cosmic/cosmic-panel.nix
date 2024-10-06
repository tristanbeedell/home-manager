{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  inherit (types) attrsOf submodule;

  ron = import ./ron.nix { inherit lib; };
  cfg = config.programs.cosmic;

  mapApplets = applets: {
    plugins_wings = "Some(${
        ron.tuple [
          (ron.stringArray applets.start)
          (ron.stringArray applets.end)
        ]
      })";
    plugins_center = "Some(${ron.stringArray applets.center})";
  };
  mapPanel = panel: panel.options // mapApplets panel.applets;
  mapPanelConfigs = panels:
    builtins.listToAttrs (map (name: {
      name = "com.system76.CosmicPanel.${name}";
      value.options = mapPanel panels.${name} // {
        name = ron.toQuotedString name;
      };
    }) (builtins.attrNames panels));

  mapPanelEntries = panels: {
    "com.system76.CosmicPanel".options.entries =
      ron.stringArray (builtins.attrNames cfg.panels);
  };

  mapPanels = panels: (mapPanelEntries panels) // (mapPanelConfigs panels);

  PanelAnchor = types.enum [ "Left" "Right" "Top" "Bottom" ];
  PanelSize = types.enum [ "XS" "S" "M" "L" "XL" ];
  Layer = types.enum [ "Background" "Bottom" "Top" "Overlay" ];
  KeyboardInteractivity = types.enum [ "None" "Exclusive" "OnDemand" ];
  # TODO: allow name
  CosmicPanelOuput = types.str;
  # types.enum ["All" "Active" "Name(String)"];
  CosmicPanelBackground = types.str;
  # TODO: allow colour config
  # types.enum [
  #   /// theme default color with optional transparency
  #   ThemeDefault,
  #   /// theme default dark
  #   Dark,
  #   /// theme default light
  #   Light,
  #   /// RGBA
  #   Color([f32; 3]),
  # ];

  # TODO: either "None" or AutoHide
  AutoHide = types.str;
  # Option<AutoHide>
  # pub struct AutoHide {
  #     /// time in milliseconds without pointer focus before hiding
  # default 1000
  #     pub wait_time: u32,
  #     /// time in milliseconds that it should take to transition
  # default 200
  #     pub transition_time: u32,
  #     /// size of the handle in pixels
  #     /// should be > 0
  # default 4
  #     pub handle_size: u32,
  # }
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
            description = ''
              Set of options defined here: https://github.com/pop-os/cosmic-panel/blob/0ce85da198f02f94ad75441e64c0e165c41eb4ae/cosmic-panel-config/src/panel_config.rs#L299
            '';
            type = types.submodule {
              options = {
                # default opts: https://github.com/pop-os/cosmic-panel/blob/master/cosmic-panel-config/src/panel_config.rs#L364
                anchor = mkOption {
                  type = PanelAnchor;
                  default = "Top";
                  description = ''
                    edge which the panel is locked to
                  '';
                };
                anchor_gap = mkOption {
                  type = types.bool;
                  default = false;
                  description = ''
                    gap between the panel and the edge of the ouput
                  '';
                };
                layer = mkOption {
                  type = Layer;
                  default = "Top";
                  description = ''
                    configured layer which the panel is on
                  '';
                };
                keyboard_interactivity = mkOption {
                  type = KeyboardInteractivity;
                  default = "None";
                  description = ''
                    configured interactivity level for the panel
                  '';
                };
                size = mkOption {
                  type = PanelSize;
                  default = "M";
                  description = ''
                    configured size for the panel
                  '';
                };
                output = mkOption {
                  type = CosmicPanelOuput;
                  default = "All";
                  description = ''
                    name of configured output (Intended for dock or panel), or None to place on active output (Intended for wrapping a single application)
                  '';
                };
                background = mkOption {
                  type = CosmicPanelBackground;
                  default = "ThemeDefault";
                  description = ''
                    customized background, or
                  '';
                };
                expand_to_edges = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    whether the panel should stretch to the edges of output
                  '';
                };
                padding = mkOption {
                  type = types.ints.u32;
                  default = 4;
                  description = ''
                    padding around the panel
                  '';
                };
                spacing = mkOption {
                  type = types.ints.u32;
                  default = 4;
                  description = ''
                    space between panel plugins
                  '';
                };
                border_radius = mkOption {
                  type = types.ints.u32;
                  default = 8;
                };
                exclusive_zone = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    exclusive zone
                  '';
                };
                autohide = mkOption {
                  type = AutoHide;
                  default = "None";
                  description = ''
                    enable autohide feature with the transitions lasting the supplied wait time and duration in millis
                  '';
                };
                margin = mkOption {
                  type = types.ints.u16;
                  default = 4;
                  description = ''
                    margin between the panel and the edge of the output
                  '';
                };
                opacity = mkOption {
                  type = types.float;
                  default = 0.8;
                  description = ''
                    opacity of the panel
                  '';
                };
              };
            };
          };
        };
      });
    };

  };
  config = {
    programs.cosmic.settings =
      if cfg.panels == { } then { } else mapPanels cfg.panels;
  };
}
