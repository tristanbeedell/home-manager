{ pkgs, ... }:

{
  config = {
    programs.cosmic = {
      enable = true;
      defaultKeybindings = false;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom
      assertPathNotExists home-files/.config/cosmic/com.system76.CosmicBackground/v1/backgrounds
      assertFileExists home-files/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults
    '';
  };
}
