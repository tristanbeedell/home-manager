{ lib, ... }:
let
  inherit (lib) types;
  ron = import ./ron.nix { inherit lib; };
  inherit (builtins) mapAttrs attrValues concatLists;
in rec {

  Modifiers = [ "Super" "Ctrl" "Alt" "Shift" ];
  Modifier = types.enum Modifiers;

  mal = f: a: concatLists (attrValues (mapAttrs f a));

  /* *
     Map bindings attrset to list

     {
       Super.Shift.q = ...;
       Super.Alt.x = ...;
     }
     ->
     [
       {modifiers = ["Super" "Shift"]; key = "q"; action = ...;}
       {modifiers = ["Super" "Alt"]; key = "x"; ... }
     ]
  */
  mapBinds = binds: _mapBinds [ ] [ ] binds;

  /* *
     acc: accumulator of all action binds
     mods: accumulator of modifier keys down one chain to an action
  */
  _mapBinds = acc: mods: value: mal (_mapMods acc mods) value;

  _mapMods = acc: mods: key: value:
    assert lib.typeOf key == "string";
    assert lib.typeOf value == "set";
    acc ++ (if Modifier.check key then
      _mapBinds acc (mods ++ [ key ]) value
    else
      [ (_mapBind mods key value) ]);

  _mapBind = modifiers: key: action: action // { inherit key modifiers; };

  ActionsValueType =
    types.nullOr (types.oneOf [ types.str types.int types.package ]);

  System.type = types.enum [
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

  Actions = mapAttrs (mkAction) ActionTypes;

  mkAction = name: type:
    type // {
      _type = "action";
      coerce = type.coerce or lib.id;
      action = name;
      __functor = self: value:
        let
          action = {
            action = name;
            inherit value;
          };
        in self // builtins.seq (assertValidActionValue action) action;
    };

  toString = action: ron.enum (toEnum (coerce action));

  toEnum = { action, value, ... }: {
    inherit value;
    name = action;
  };

  Direction.type = types.enum [ "Left" "Right" "Up" "Down" ];
  FocusDirection.type = types.enum [ "Left" "Right" "Up" "Down" "In" "Out" ];
  ResizeDirection.type = types.enum [ "Inwards" "Outwards" ];
  Orientation.type = types.enum [ "Horizontal" "Vertical" ];
  u8.type = types.coercedTo types.str lib.strings.toInt types.ints.u8;
  none.type = types.mkOptionType {
    name = "null";
    check = isNull;
  };

  ActionTypes = {
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
    Move = Direction;
    MoveToOutput = Direction;
    MoveToWorkspace = u8;
    Orientation = Orientation;
    Resizing = ResizeDirection;
    SendToOutput = Direction;
    SendToWorkspace = u8;
    SwitchOutput = Direction;
    System = System;
    Workspace = u8;
    Spawn = {
      type = types.either types.nonEmptyStr types.package;
      coerce = value:
        ron.toQuotedString
        (if types.package.check value then lib.getExe value else value);
    };
  };

  coerce = a:
    let
      datatype = lib.typeOf a;
      action = if datatype == "set" then
        if !a ? action then throw "COSMIC Action missing 'action'" else a.action
      else if datatype == "string" then
        a
      else
        throw "Cannot coerce ${datatype} to COSMIC Action";
      fullaction = {
        inherit action;
        value = a.value or null;
      };
    in assert assertValidAction fullaction; {
      inherit action;
      value = Actions.${action}.coerce fullaction.value;
    };

  action = n: {
    action = n;
    value = null;
  };

  ActionsNameType = types.enum (builtins.attrNames Actions);

  assertValidAction = a:
    assertValidActionName a.action && assertValidActionValue a;

  assertValidActionName = action:
    lib.assertMsg (ActionsNameType.check action)
    "Invalid Cosmic keybind action: `${action}`. Valid values: `${ActionsNameType.description}`";

  assertValidActionValue = a:
    let type = Actions.${a.action}.type;
    in lib.assertMsg (type.check a.value)
    "Cosmic action `${a.action}` expects value: `${type.description}`";

}
