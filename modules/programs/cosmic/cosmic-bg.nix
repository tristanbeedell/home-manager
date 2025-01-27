{ pkgs, lib, config, ... }:
let
  inherit (lib) concatMapAttrs mkOption types;
  inherit (types) submodule either attrsOf;

  ron = import ./ron.nix { inherit lib; };
  inherit (ron) array toQuotedString serialise path;

  scalingToString = { mode, color }:
    if mode == "Fit" then "Fit(${ron.tuple color})" else mode;
  _mapBackground = display: background: {
    ${if display == "all" then "all" else "output.${display}"} = serialise {
      inherit (background)
        filter_by_theme filter_method sampling_method rotation_frequency;
      scaling_mode = scalingToString background.scaling;
      output = toQuotedString display;
      source = path background.source;
    };
  };
  mapBackgrounds = backgrounds:
    (concatMapAttrs _mapBackground backgrounds) // {
      "backgrounds" =
        array (map toQuotedString (builtins.attrNames backgrounds));
    };

  cfg = config.programs.cosmic.background;

in {
  options.programs.cosmic.background = {
    displays = mkOption {
      default = { };
      description = ''
        Cosmic Wallpaper options on a display.
        Use the display name "all", to apply to all displays.
      '';
      example = lib.literalExpression ''
        {
          DP-1 = {
            source = ./image.png;
          };
        };
      '';
      type = attrsOf (submodule {
        options = {
          source = mkOption {
            type = either types.path types.str;
            description = ''
              The image source. Can be an individual image, or a folder for a slideshow.
            '';
          };
          # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L79
          filter_by_theme = mkOption {
            default = true;
            description = ''
              Whether the images should be filtered by the active theme
            '';
            type = types.bool;
          };
          filter_method = mkOption {
            default = "Lanczos";
            # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L155
            description = ''
              Mode used to scale images
            '';
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
          scaling = {
            mode = mkOption {
              default = "Zoom";
              # https://github.com/pop-os/cosmic-bg/blob/584f6b3c0454396df25d36c6c2b59b018946e81e/config/src/lib.rs#L188
              description = "Image scaling mode";
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
      });
    };
    extraConfig = mkOption {
      default = { };
      description = "Extra configuration options for cosmic-bg";
      type = attrsOf types.anything;
    };
  };

  config = lib.mkIf (cfg != { }) {
    programs.cosmic.settings."com.system76.CosmicBackground".options =
      (mapBackgrounds cfg.displays) // cfg.extraConfig;
  };
}
