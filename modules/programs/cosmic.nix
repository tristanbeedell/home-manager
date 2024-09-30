{ pkgs, lib, config, ... }:
let
  inherit (lib)
    filterAttrs concatStrings concatStringsSep mapAttrsToList concatLists
    foldlAttrs concatMapAttrs mapAttrs' nameValuePair boolToString maintainers
    mkOption types;
  inherit (types)
    listOf submodule nullOr either oneOf literalExpression attrsOf anything;
  inherit (builtins) typeOf toString stringLength;

  # build up serialisation machinery from here for various types

  # list -> array
  array = a: "[${concatStringsSep "," (map serialise a)}]";
  # attrset -> hashmap
  _assoc = a: mapAttrsToList (name: val: "${name}: ${val},") a;
  assoc = a: ''
    {
        ${concatStringsSep "\n    " (concatLists (map _assoc a))}
    }
  '';
  # attrset -> struct
  _struct_kv = k: v:
    if v == null then "" else (concatStringsSep ": " [ k (serialise v) ]);
  _struct_concat = s:
    foldlAttrs (acc: k: v:
      if stringLength acc > 0 then
        concatStringsSep ", " [ acc (_struct_kv k v) ]
      else
        _struct_kv k v) "" s;
  _struct_filt = s: _struct_concat (filterAttrs (k: v: v != null) s);
  struct = s: "(${_struct_filt s})";
  toQuotedString = s: ''"${toString s}"'';
  path = p: ''Path("${p}")'';

  # make an attrset for struct serialisation
  _serialisers = {
    int = toString;
    float = toString;
    bool = boolToString;
    # can't assume quoted string, sometimes it's a Rust enum
    string = toString;
    path = path;
    null = toString;
    set = struct;
    list = array;
  };

  serialise = v: _serialisers.${typeOf v} v;

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

  mapCosmicSettings = application: options:
    mapAttrs' (k: v:
      nameValuePair "cosmic/${application}/v${options.version}/${k}" {
        enable = true;
        text = serialise v;
      }) options.options;

  scalingToString = { mode, color }:
    if mode == "Fit" then
      "Fit((${concatStringsSep "," (map toString color)}))"
    else
      mode;

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

  enumOf = type:
    submodule {
      options = {
        type = mkOption { type = types.str; };
        value = mkOption { inherit type; };
      };
    };

in {
  meta.maintainers = with maintainers; [ tristan ];
  options.programs.cosmic = {
    enable = lib.mkEnableOption "COSMIC DE";

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
            type = oneOf [
              (types.enum types.str)
              (enumOf (either types.str types.int))
            ];
          };
        };
      });
      description = ''
        A set of keybindings and actions for the COSMIC DE.
        The list of actions and possible values can be found presently at: https://github.com/pop-os/cosmic-settings-daemon/blob/master/config/src/shortcuts/action.rs
      '';
      example = literalExpression ''
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
    xdg.configFile = {
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
        text = mapBindings cfg.keybindings;
        enable = cfg.keybindings != [ ];
      };
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults" = {
        text = "{}";
        enable = !cfg.defaultKeybindings;
      };
    } // (if (cfg.background.displays != { }) then
      (mapBackgrounds cfg.background.displays)
    else
      { }) // concatMapAttrs
      (application: options: mapCosmicSettings application options)
      cfg.settings;
  };
}
