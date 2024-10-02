{ lib }:
let
  inherit (lib) types;
  ron = import ./ron.nix { inherit lib; };
in rec {

  Modifier = types.enum [ "Super" "Ctrl" "Alt" "Shift" ];

  System = types.enum [
    "AppLibrary"
    "BrightnessDown"
    "BrightnessUp"
    "HomeFolder"
    "KeyboardBrightnessDown"
    "KeyboardBrightnessUp"
    "Launcher"
    "LockScreen"
    "Mute"
    "MuteMic"
    "PlayPause"
    "PlayNext"
    "PlayPrev"
    "Screenshot"
    "Terminal"
    "VolumeLower"
    "VolumeRaise"
    "WebBrowser"
    "WindowSwitcher"
    "WorkspaceOverview"
  ];

  Direction = types.enum [ "Left" "Right" "Up" "Down" ];
  FocusDirection = types.enum [ "Left" "Right" "Up" "Down" "In" "Out" ];
  ResizeDirection = types.enum [ "Inwards" "Outwards" ];
  Orientation = types.enum [ "Horizontal" "Vertical" ];
  u8 = types.coercedTo types.str lib.strings.toInt types.ints.u8;
  none = types.mkOptionType {
    name = "null";
    check = isNull;
  };

  Actions = {
    Close = none;
    Debug = none;
    Disable = none;
    LastWorkspace = none;
    Maximize = none;
    MigrateWorkspaceToNextOutput = none;
    MigrateWorkspaceToPreviousOutput = none;
    Minimize = none;
    MoveToLastWorkspace = none;
    MoveToNextOutput = none;
    MoveToNextWorkspace = none;
    MoveToPreviousOutput = none;
    MoveToPreviousWorkspace = none;
    NextOutput = none;
    NextWorkspace = none;
    PreviousOutput = none;
    PreviousWorkspace = none;
    SendToLastWorkspace = none;
    SendToNextOutput = none;
    SendToNextWorkspace = none;
    SendToPreviousOutput = none;
    SendToPreviousWorkspace = none;
    SwapWindow = none;
    Terminate = none;
    ToggleOrientation = none;
    ToggleStacking = none;
    ToggleSticky = none;
    ToggleTiling = none;
    ToggleWindowFloating = none;
    Focus = FocusDirection;
    MigrateWorkspaceToOutput = Direction;
    Move = Direction: Direction;
    MoveToOutput = Direction;
    MoveToWorkspace = u8;
    Orientation = Orientation;
    Resizing = ResizeDirection;
    SendToOutput = Direction;
    SendToWorkspace = u8;
    SwitchOutput = Direction;
    System = System;
    Spawn = types.either types.nonEmptyStr types.package;
    Workspace = u8;
  };

  /* All actions but Spawn take an explicit enum value.
     For this exception we coerce to quoted string.
  */
  coerce = a:
    if a.type == "Spawn" then
      let
        cmd =
          if types.package.check a.value then lib.getExe a.value else a.value;
      in {
        inherit (a) type;
        value = ron.toQuotedString cmd;
      }
    else
      a;

  ActionsNameType = types.enum (builtins.attrNames Actions);

  assertValidActionName = a:
    lib.assertMsg (Actions ? ${a.type})
    "Invalid Cosmic keybind action: `${a.type}`. Valid values: `${ActionsNameType.description}`";

  assertValidActionValue = a:
    let type = Actions.${a.type};
    in lib.assertMsg (type.check a.value)
    "Cosmic action `${a.type}` expects value: `${type.description}`";

  check = ma:
    let
      a = if (builtins.typeOf ma == "set") then
        ma
      else {
        type = ma;
        value = null;
      };
    in assertValidActionName a && assertValidActionValue a;

}
