{ lib, config, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
  ron = import ./ron.nix { inherit lib; };

  mkEnableRonOption = name:
    mkOption {
      default = null;
      example = true;
      description = "Whether to enable ${name}. null = Cosmic's Default";
      type = ron.types.option types.bool;
    };

  AccelConfig = {
    profile = mkOption {
      type = ron.types.option (types.enum [ "Flat" "Adaptive" ]);
      default = null;
      description = ''
        Mouse acceleration profile.

        - Flat = No acceleration
        - Adaptive = Acceleration
      '';
    };
    speed = mkOption {
      type = types.float;
      default = 0.0;
      description = ''
        Mouse speed. more negative = slower, more positive = faster.

        You probably want to keep it between -1.0 and 1.0
      '';
    };
  };

  ScrollConfig = {
    method = mkOption {
      description = ''
        This applies to touchpads. For mice, use `null`.
      '';
      type = ron.types.option
        (types.enum [ "NoScroll" "TwoFinger" "Edge" "OnButtonDown" ]);
      default = null;
    };
    natural_scroll =
      mkEnableRonOption "Natural Scrolling (Reverse scroll direction)";
    scroll_button = mkOption {
      description = ''
        I have no idea what this option does.
      '';
      type = ron.types.option types.ints.u32;
      default = null;
    };
    scroll_factor = mkOption {
      type = ron.types.option types.float;
      default = 1.0;
      description = ''
        Scrolling Speed.

        - 0.0 = don't scroll at all
        - 1.0 = default speed
        - 32.0 = the max speed in cosmic settings
      '';
    };
  };

  TapConfig = {
    enabled = mkEnableOption "Tap to click" // { default = true; };
    button_map = mkOption {
      default = "LeftRightMiddle";
      type =
        ron.types.option (types.enum [ "LeftRightMiddle" "LeftMiddleRight" ]);
      description = ''
        - LeftRightMiddle: Default (matching click_method)
        - LeftMiddleRight: Swaps middle and secondary click when tapping touchpad with multiple fingers.
      '';
    };
    drag = mkEnableOption "dragging" // { default = true; };
    drag_lock = mkEnableOption "drag lock";
  };

  # https://github.com/pop-os/cosmic-comp/blob/b8c429facbacbcd0cdda94f717c29b58d9f65414/cosmic-comp-config/src/input.rs#L11
  InputConfig = types.submodule {
    options = {
      state = mkOption {
        type = types.enum [ "Enabled" "Disabled" "DisabledOnExternalMouse" ];
        default = "Enabled";
        description = ''
          Whether to enable this device
        '';
      };
      acceleration = AccelConfig;
      calibration = mkOption {
        type = ron.types.option (types.listOf types.float) # [f32; 6]
        ;
        default = null;
        description = ''
          A calibration matrix.

          TODO: I haven't found documentation on how this setting works.
        '';
      };
      click_method = mkOption {
        type = ron.types.option (types.enum [ "ButtonAreas" "Clickfinger" ]);
        default = null;
        description = ''
          - Clickfinger = Secondary click with two fingers and middle-click with three fingers.
          - ButtonAreas = Secondary click in bottom right corner and middle-click with bottom center.
        '';
      };
      disable_while_typing = mkEnableRonOption "disable while typing";
      left_handed = mkEnableRonOption
        "left handed mode. Switches left and right click buttons.";
      middle_button_emulation = mkEnableRonOption "middle button emulation";
      rotation_angle = mkOption {
        type = ron.types.option types.ints.u32;
        default = null;
        description = ''
          Rotation of input in degrees
        '';
      };
      scroll_config = ScrollConfig;
      tap_config = TapConfig;
      map_to_output = mkOption {
        type = ron.types.option types.str;
        default = null;
        description = ''
          TODO: I haven't found documentation on how this setting works.
        '';
      };
    };
  };

  WorkspaceConfig = {
    workspace_mode = mkOption {
      default = "OutputBound";
      description = ''
        - OutputBound: Workspaces are per monitor.
        - Global: Workspaces span monitors.
      '';
      type = types.enum [ "OutputBound" "Global" ];
    };
    workspace_layout = mkOption {
      default = "Vertical";
      description = ''
        The direction in which Workspaces flow.
      '';
      type = types.enum [ "Vertical" "Horizontal" ];
    };
  };

in {
  # https://github.com/pop-os/cosmic-comp/blob/b8c429facbacbcd0cdda94f717c29b58d9f65414/cosmic-comp-config/src/lib.rs#L12
  options.programs.cosmic.comp = {
    settings = {
      workspaces = WorkspaceConfig;
      input_default = mkOption {
        description = ''
          Default configuration for pointer devices.
        '';
        type = types.nullOr InputConfig;
        default = null;
      };
      input_touchpad = mkOption {
        type = types.nullOr InputConfig;
        default = null;
        description = ''
          Default configuration for touchpad devices.
        '';
      };
      input_devices = mkOption {
        default = { };
        type = types.attrsOf InputConfig;
        description = ''
          Configuration for other pointer devices.
        '';
      };
      autotile = mkEnableOption "Autotiling";
      autotile_behavior = mkOption {
        type = types.enum [ "Global" "PerWorkspace" ];
        description = ''
          Determines the behavior of the autotile variable
          If set to Global, autotile applies to all windows in all workspaces
          If set to PerWorkspace, autotile only applies to new windows, and new workspaces
        '';
        default = "Global";
      };
      active_hint = mkEnableOption "Active hint";
      focus_follows_cursor = mkEnableOption
        "changing keyboard focus to windows when the cursor passes into them";
      cursor_follows_focus = mkEnableOption
        "warping the cursor to the focused window when focus changes due to keyboard input";
      focus_follows_cursor_delay = mkOption {
        default = 250;
        description = ''
          The delay in milliseconds before focus follows mouse (if enabled)
        '';
        type = types.int;
      };
      descale_xwayland = mkEnableOption "Let X11 applications scale themselves";
    };
    extraConfig = mkOption {
      type = with types; attrsOf anything;
      description = ''
        Extra Cosmic Comp configuration options.
      '';
      default = { };
    };
  };

  config = let
    cfg = config.programs.cosmic.comp;
    mapConfig = cfg: (mapSettings cfg.settings) // cfg.extraConfig;
    mapSettings = cfg:
      cfg // {
        input_default = mapInputCfg cfg.input_default;
        input_touchpad = mapInputCfg cfg.input_touchpad;
        input_devices =
          builtins.mapAttrs (name: value: mapInputCfg value) cfg.input_devices;
      };
    # can't use coercedTo on submodules for rust Option types, so do it here.
    mapInputCfg = cfg:
      if isNull cfg then
        null
      else
        cfg // {
          acceleration = ron.option cfg.acceleration;
          scroll_config = ron.option cfg.scroll_config;
          tap_config = ron.option cfg.tap_config;
        };
  in {
    programs.cosmic.settings = {
      "com.system76.CosmicComp".options = mapConfig cfg;
    };
  };
}
