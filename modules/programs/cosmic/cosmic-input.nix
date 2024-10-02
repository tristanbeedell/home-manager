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
    map (inner: {
      "${defineBinding inner}" = actionToString {
        inherit (inner) value;
        type = inner.action;
      };
    }) bindings;
  mapBindings = bindings: assoc (_mapBindings bindings);

  actionToString = action:
    assert actions.check action;
    ron.enum (actions.coerce action);

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
          example = types.literalExpression ''
            [
              # Key + mod + Spawn action
              {
                key = "Return";
                modifiers = ["Super"];
                action = {
                  type = "Spawn";
                  value = "kitty";
                };
              }
              # Only mod - activates if no key is pressed with the modifier
              {
                modifiers = ["Super"];
                action = {
                  type = "Spawn";
                  value = "wofi";
                }
              }
              # Key only and plain action
              {
                key = "g";
                action = "ToggleWindowFloating";
              }
            ]
          '';
        };

      };
    };
  };

  config = {
    programs.cosmic.settings = {
      "com.system76.CosmicSettings.Shortcuts".options =
        (if cfg.keybindings != [ ] then {
          custom = mapBindings cfg.keybindings;
        } else
          { })
        // (if !cfg.defaultKeybindings then { defaults = "{}"; } else { });
    };
  };

}
