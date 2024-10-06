{ lib, config, ... }:
let
  inherit (builtins) typeOf;

  inherit (lib) mkOption types;
  inherit (types) listOf submodule nullOr either;

  ron = import ./ron.nix { inherit lib; };
  inherit (ron) struct toQuotedString assoc;

  actions = import ./actions.nix { inherit lib; };

  # define the key for a keybind
  defineBinding = binding:
    struct {
      inherit (binding) modifiers;
      key = if isNull binding.key then null else toQuotedString binding.key;
    };

  # map keybinding from list of attrset to hashmap of (mod,key): action
  _mapBindings = bindings:
    map (inner: { "${defineBinding inner}" = actions.toString inner; })
    bindings;
  mapBindings = bindings: assoc (_mapBindings bindings);

  cfg = config.programs.cosmic.input;
in {
  options.programs.cosmic.input = mkOption {
    default = { };
    type = submodule {
      options = {

        defaultKeybindings = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = "Whether to enable the default COSMIC keybindings.";
        };

        binds = lib.mkOption {
          default = { };
          description = ''
            A set of keybindings and actions for COSMIC DE.
          '';
          type = types.attrs;
        };

        keybindings = lib.mkOption {
          default = [ ];
          type = listOf (submodule {
            options = {
              modifiers = mkOption {
                type = listOf actions.Modifier;
                default = [ "Super" ];
              };
              key = mkOption {
                type = nullOr types.str;
                default = null;
              };
              action = mkOption { type = actions.ActionsNameType; };
              value = mkOption {
                default = null;
                type = types.nullOr
                  (types.oneOf [ types.str types.int types.package ]);
              };
            };
          });
          description = ''
            A set of keybindings and actions for the COSMIC DE.
            The list of actions and possible values can be found presently at: https://github.com/pop-os/cosmic-settings-daemon/blob/master/config/src/shortcuts/action.rs
          '';
          example = lib.literalExpression ''
            [
              # Key + mod + Spawn action
              {
                modifiers = [ "Super" ];
                key = "g";
                action = "Disable";
              }
              {
                modifiers = [ "Super" "Shift" ];
                key = "g";
                action = "ToggleWindowFloating";
              }
              {
                modifiers = [ "Super" ];
                key = "Return";
                action = "Spawn";
                value = pkgs.kitty;
              }
              {
                modifiers = [ "Super" ];
                key = "1";
                action = "Workspace";
                value = 1;
              }
            ]
          '';
        };

      };
    };
  };

  config = {
    lib.cosmic = actions;
    programs.cosmic.settings = {
      "com.system76.CosmicSettings.Shortcuts".options =
        (if cfg.keybindings == [ ] && cfg.binds == { } then
          { }
        else {
          custom =
            mapBindings (cfg.keybindings ++ (actions.mapBinds cfg.binds));
        }) // (if !cfg.defaultKeybindings then { defaults = "{}"; } else { });
    };
  };

}
