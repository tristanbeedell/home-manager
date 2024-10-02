{ lib, config, ... }:
let
  inherit (builtins) typeOf;

  inherit (lib) mkOption types concatStrings;
  inherit (types) listOf submodule nullOr either oneOf;

  ron = import ./ron.nix { inherit lib; };
  inherit (ron) struct toQuotedString assoc serialise;
  cfg = config.programs.cosmic.input;

  # define the key for a keybind
  defineBinding = binding:
    struct {
      inherit (binding) modifiers;
      key = if isNull binding.key then null else toQuotedString binding.key;
    };

  # map keybinding from list of attrset to hashmap of (mod,key): action
  _mapBindings = bindings:
    map (inner: {
      "${defineBinding inner}" = maybeToString (checkAction inner.action);
    }) bindings;
  mapBindings = bindings: assoc (_mapBindings bindings);

  # check a keybinding's action
  # escape with quotes if it's a Spawn action
  checkAction = a:
    if typeOf a == "set" && a.type == "Spawn" then {
      inherit (a) type;
      value = toQuotedString a.value;
    } else
      a;

  maybeToString = s:
    if typeOf s == "set" then
      concatStrings [ s.type "(" (serialise s.value) ")" ]
    else
      s;

  enumOf = type:
    submodule {
      options = {
        type = mkOption { type = types.str; };
        value = mkOption { inherit type; };
      };
    };

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
                type = listOf types.str;
                default = [ ];
              };
              key = mkOption {
                type = nullOr types.str;
                default = null;
              };
              action = mkOption {
                type =
                  oneOf [ types.str (enumOf (either types.str types.int)) ];
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
