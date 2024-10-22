{ pkgs, config, ... }: {
  programs.cosmic = {
    enable = true;
    comp = {
      active_hint = true;
      autotile = true;
      autotile_behavior = "PerWorkspace";
      input_touchpad = { acceleration = { profile = "Adaptive"; }; };
      xkb_config.layout = "gb";
    };
  };

  nmt.script = let
    # cosmic settings are split between lots of files, this wrapper helps with the tests.
    assertFileContent = filename: content: ''
      assertFileContent $config/${filename} ${pkgs.writeText filename content}
    '';
  in ''
    config=home-files/.config/cosmic/com.system76.CosmicComp/v1

    # TODO: this is for testing, pls remove
    d=$(_abs $config)
    echo $d/

    assertDirectoryExists $config
    ${assertFileContent "active_hint" "true"}
    ${assertFileContent "autotile" "true"}
    ${assertFileContent "autotile_behavior" "PerWorkspace"}
    ${assertFileContent "input_devices" "()"}
    assertFileExists $config/input_default
    assertFileExists $config/input_touchpad
    ${assertFileContent "input_touchpad"
    # eh, it's all put on one line, so I'm doing some janky string manip to make this easier
    (builtins.replaceStrings [ "\n" "    " ] [ "" "" ] ''
      (
          acceleration: Some((
              profile: Some(Adaptive),
               speed: 0.000000
          )),
           calibration: None,
           click_method: None,
           disable_while_typing: None,
           left_handed: None,
           map_to_output: None,
           middle_button_emulation: None,
           rotation_angle: None,
           scroll_config: Some((
              method: None,
               natural_scroll: None,
               scroll_button: None,
               scroll_factor: Some(1.000000)
          )),
           state: Enabled,
           tap_config: Some((
              button_map: Some(LeftRightMiddle),
               drag: true,
               drag_lock: false,
               enabled: true
          ))
      )
    '')}
    ${assertFileContent "workspaces"
    "(workspace_layout: Vertical, workspace_mode: OutputBound)"}
    ${assertFileContent "xkb_config" ''
      (layout: "gb", model: "", options: None, repeat_delay: 600, repeat_rate: 25, rules: "", variant: "")''}
  '';
}
