{ pkgs, lib, config, ... }:
let
  inherit (lib) concatMapAttrs mapAttrs' nameValuePair mkOption types;
  inherit (types) submodule attrsOf anything;

  ron = import ./ron.nix { inherit lib; };
  inherit (ron) serialise;

  mapCosmicSettings = application: options:
    mapAttrs' (k: v:
      nameValuePair "cosmic/${application}/v${options.version}/${k}" {
        enable = true;
        text = serialise v;
      }) options.options;

  cfg = config.programs.cosmic;

in {
  meta.maintainers = with lib.hm.maintainers; [ tristan ];
  options.programs.cosmic = {
    enable =
      lib.mkEnableOption "configuration for the Cosmic Desktop Environment";

    settings = mkOption {
      default = { };
      type = attrsOf (submodule {
        options = {
          version = mkOption {
            type = types.str;
            default = "1";
            description = ''
              Configuration version number
            '';
          };
          options = mkOption {
            type = attrsOf anything;
            description = ''
              Options to set for this path.

              Attrsets and Lists are converted best-effort into the Ron
              configuration language used by Cosmic.
              Strings will be used as-is. Remember that some strings
              need to be quoted!
            '';
          };
        };
      });
      description = ''
        An attrset of explicit settings for COSMIC apps, using their full config path.
      '';
      example = lib.literalExpression ''
        {
          "com.system76.CosmicTk".options = {
            show_maximize = true;
          };
          "com.system76.CosmicEdit".options = {
            auto_indent = true;
          };
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = concatMapAttrs
      (application: options: mapCosmicSettings application options)
      cfg.settings;
  };

  imports =
    [ ./cosmic-panel.nix ./cosmic-input.nix ./cosmic-bg.nix ./cosmic-comp.nix ];
}
