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
    description = ''
      Cosmic Input options
    '';
    type = submodule {
      options = {

        enableDefaultKeybindings = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = "Whether to enable the default COSMIC keybindings.";
        };

        binds = lib.mkOption {
          default = { };
          description = ''
            A set of keybindings and actions for COSMIC DE.
            There are utility functions available in `config.lib.cosmic.Actions`
          '';
          example = lib.literalExpression ''
            let inherit (config.lib.cosmic) Actions;
            in {
              Super.h = Actions.Focus "Left";
              Super.Shift.h = Actions.Move "Left";
              Super.Space = Actions.ToggleTiling;
              Super.Shift.q.action = "Close";
              Super.a = Actions.Spawn (pkgs.writeShellScriptBin "my-script" "");
              Super."1" = Actions.Workspace 1;
              Super.Shift."1" = Actions.MoveToWorkspace "1";
              Super."o" = Actions.System "HomeFolder";
            }
          '';
          type = types.attrs;
        };
      };
    };
  };

  config = {
    lib.cosmic = actions;
    programs.cosmic.settings = {
      "com.system76.CosmicSettings.Shortcuts".options =
        (if cfg.binds == { } then
          { }
        else {
          custom = mapBindings (actions.mapBinds cfg.binds);
        }) // (if cfg.enableDefaultKeybindings then
          { }
        else {
          defaults = "{}";
        });
    };
  };

}
