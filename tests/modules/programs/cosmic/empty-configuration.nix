{ pkgs, ... }:

{
  config = {
    programs.cosmic = {
      enable = true;
      defaultKeybindings = false;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom
      assertFileExists home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults
    '';
  };
}
