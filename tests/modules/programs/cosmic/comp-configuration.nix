{ pkgs, config, ... }: {
  programs.cosmic = {
    enable = true;
    comp = {
      settings = {
        active_hint = true;
        autotile = true;
        input_touchpad = { acceleration = { profile = "Adaptive"; }; };
      };
      extraConfig = { some-setting = "Something"; };
    };
  };

  nmt.script = let
    # cosmic settings are split between lots of files, this wrapper helps with the tests.
    assertFileContent = filename: content: ''
      assertFileContent $config/${filename} ${pkgs.writeText filename content}
    '';
  in ''
    config=home-files/.config/cosmic/com.system76.CosmicComp/v1

    assertDirectoryExists $config
    ${assertFileContent "some-setting" "Something"}

    ${assertFileContent "active_hint" "true"}
    ${assertFileContent "autotile" "true"}
    ${assertFileContent "input_devices" "()"}
    assertFileExists $config/input_default
    assertFileExists $config/input_touchpad
    assertFileContent "$config/input_touchpad" ${./input-touchpad.ron}
    ${assertFileContent "workspaces"
    "(workspace_layout: Vertical, workspace_mode: OutputBound)"}
  '';
}
