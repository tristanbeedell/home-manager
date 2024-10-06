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

  mapPanel = panel:
    panel.options // {
      output = mapPanelOutput panel.options.output;
      autohide = mapAutohide panel.options.autohide;
    } // mapApplets panel.applets;

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

  OuputOpts = [ "All" "Active" ];
  CosmicPanelOuput = types.either (types.enum OuputOpts) types.str;

  mapPanelOutput = output:
    if builtins.elem output OuputOpts then
      output
    else
      ron.enum {
        name = "Name";
        value = ron.toQuotedString output;
      };

  CosmicPanelBackground = types.enum [ "ThemeDefault" "Dark" "Light" ];

  AutoHide = types.submodule {
    options = {
      enable = lib.mkEnableOption "autohide";
      wait_time = mkOption {
        type = types.ints.u32;
        description =
          "time in milliseconds without pointer focus before hiding";
        default = 1000;
      };
      transition_time = mkOption {
        default = 200;
        type = types.ints.u32;
        description = "time in milliseconds that it should take to transition";
      };
      handle_size = mkOption {
        description = "size of the handle in pixels";
        default = 4;
        type = types.ints.u32;
      };
    };
  };

  mapAutohide = opt:
    (if !opt.enable then
      "None"
    else
      ron.option (builtins.removeAttrs opt [ "enable" ]));

in {
  options.programs.cosmic = {
    panels = mkOption {
      default = { };
      description = ''
        Cosmic Panel configuration.
        You can have many panels in cosmic - beyond the default Panel and Dock!
      '';
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
                  description = ''
                    Applets shown at the start of the panel.
                  '';
                  default = [ ];
                };
                center = mkOption {
                  type = types.listOf types.str;
                  description = ''
                    Applets shown at the center of the panel.
                  '';
                  default = [ ];
                };
                end = mkOption {
                  type = types.listOf types.str;
                  description = ''
                    Applets shown at the end of the panel.
                  '';
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
                    Edge which the panel is locked to
                  '';
                };
                anchor_gap = mkOption {
                  type = types.bool;
                  default = false;
                  description = ''
                    Gap between the panel and the edge of the ouput
                  '';
                };
                layer = mkOption {
                  type = Layer;
                  default = "Top";
                  description = ''
                    Configured layer which the panel is on
                  '';
                };
                keyboard_interactivity = mkOption {
                  type = KeyboardInteractivity;
                  default = "None";
                  description = ''
                    Configured interactivity level for the panel
                  '';
                };
                size = mkOption {
                  type = PanelSize;
                  default = "M";
                  description = ''
                    Configured size for the panel
                  '';
                };
                output = mkOption {
                  type = CosmicPanelOuput;
                  default = "All";
                  example = "DP-1";
                  description = ''
                    All outputs,
                    Name of configured output (Intended for dock or panel),
                    or Active to place on active output (Intended for wrapping a single application)
                  '';
                };
                background = mkOption {
                  type = CosmicPanelBackground;
                  default = "ThemeDefault";
                  description = ''
                    Customized background, or use Theme.
                  '';
                };
                expand_to_edges = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    Whether the panel should stretch to the edges of output
                  '';
                };
                padding = mkOption {
                  type = types.ints.u32;
                  default = 4;
                  description = ''
                    Padding around the panel
                  '';
                };
                spacing = mkOption {
                  type = types.ints.u32;
                  default = 4;
                  description = ''
                    Space between panel plugins
                  '';
                };
                border_radius = mkOption {
                  type = types.ints.u32;
                  description = ''
                    Smooth radius on corners of the panel.
                  '';
                  default = 8;
                };
                exclusive_zone = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    Exclusive zone
                  '';
                };
                autohide = mkOption {
                  type = AutoHide;
                  default = { };
                  description = ''
                    Enable autohide feature with the transitions lasting the supplied wait time and duration in millis
                  '';
                };
                margin = mkOption {
                  type = types.ints.u16;
                  default = 4;
                  description = ''
                    Margin between the panel and the edge of the output
                  '';
                };
                opacity = mkOption {
                  type = types.float;
                  default = 0.8;
                  description = ''
                    Opacity of the panel
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
