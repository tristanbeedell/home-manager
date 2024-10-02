{ pkgs, lib, config, ... }:
let
  inherit (lib)
    concatMapAttrs mapAttrs' nameValuePair maintainers mkOption types;
  inherit (types) submodule either literalExpression attrsOf anything;

  ron = import ./ron.nix { inherit lib; };
  inherit (ron) array toQuotedString serialise path;

  mapCosmicSettings = application: options:
    mapAttrs' (k: v:
      nameValuePair "cosmic/${application}/v${options.version}/${k}" {
        enable = true;
        text = serialise v;
      }) options.options;

  scalingToString = { mode, color }:
    if mode == "Fit" then "Fit(${ron.tuple color})" else mode;

  _mapBackground = display: background: {
    "cosmic/com.system76.CosmicBackground/v1/${
      if display == "all" then "all" else "output.${display}"
    }" = {
      text = serialise {
        inherit (background)
          filter_by_theme filter_method sampling_method rotation_frequency;
        scaling_mode = scalingToString background.scaling;
        output = toQuotedString display;
        source = path background.source;
      };
    };
  };
  mapBackgrounds = backgrounds:
    (concatMapAttrs _mapBackground backgrounds) // {
      "cosmic/com.system76.CosmicBackground/v1/backgrounds" = {
        text = array (map toQuotedString (builtins.attrNames backgrounds));
      };
    };

  cfg = config.programs.cosmic;

in {
  meta.maintainers = with maintainers; [ tristan ];
  options.programs.cosmic = {
    enable = lib.mkEnableOption "COSMIC DE";
    background = mkOption {
      default = { };
      description = ''
        Wallpaper Options.

        COSMIC appears to immediately override the same on all displays option,
        so this must be set via the GUI...
      '';
      type = submodule {
        options = {
          displays = mkOption {
            default = { };
            example = literalExpression ''
              {
                DP-1 = {
                  image = ./image.png;
                };
              };
            '';
            type = attrsOf (submodule {
              options = {
                source = mkOption { type = either types.path types.str; };
                filter_by_theme = mkOption {
                  default = true;
                  type = types.bool;
                };
                filter_method = mkOption {
                  default = "Lanczos";
                  # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L155
                  type = types.enum [ "Lanczos" "Linear" "Nearest" ];
                };
                sampling_method = mkOption {
                  default = "Alphanumeric";
                  description = ''
                    How next image in wallpaper slideshow will be picked
                  '';
                  # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L177
                  type = types.enum [ "Alphanumeric" "Random" ];
                };
                rotation_frequency = mkOption {
                  type = types.int;
                  default = 300;
                  description = ''
                    How often to change image in seconds.
                  '';
                };
                scaling = mkOption {
                  default = { };
                  type = submodule {
                    options = {
                      mode = mkOption {
                        default = "Zoom";
                        # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L188
                        type = (types.enum [ "Zoom" "Stretch" "Fit" ]);
                      };
                      color = mkOption {
                        description = ''
                          The colour to display around the background image when using Fit scaling mode.
                        '';
                        default = [ 0.0 0.0 0.0 ];
                        type = types.listOf types.float;
                      };
                    };
                  };
                };
              };
            });
          };
        };
      };
    };

    settings = mkOption {
      default = { };
      type = attrsOf (submodule {
        options = {
          version = mkOption {
            type = types.str;
            default = "1";
          };
          options = mkOption { type = attrsOf anything; };
        };
      });
      description = ''
        An attrset of explicit settings for COSMIC apps, using their full config path.
      '';
      example = literalExpression ''
        {
          "com.system76.CosmicPanel.Dock" = {
            option.opacity = 0.8;
          };
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = (if (cfg.background.displays != { }) then
      (mapBackgrounds cfg.background.displays)
    else
      { }) // concatMapAttrs
      (application: options: mapCosmicSettings application options)
      cfg.settings;
  };

  imports = [ ./cosmic-panel.nix ./cosmic-input.nix ];
}
