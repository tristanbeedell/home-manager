{ pkgs, lib, config, ... }:
let
  inherit (lib) concatMapAttrs mapAttrs' nameValuePair mkOption types;
  inherit (types) submodule literalExpression attrsOf anything;

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
    enable = lib.mkEnableOption "COSMIC DE";

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
    xdg.configFile = concatMapAttrs
      (application: options: mapCosmicSettings application options)
      cfg.settings;
  };

  imports = [ ./cosmic-panel.nix ./cosmic-input.nix ./cosmic-bg.nix ];
}
