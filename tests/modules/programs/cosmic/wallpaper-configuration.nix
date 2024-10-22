{ pkgs, config, ... }:

{
  config = {
    programs.cosmic = {
      enable = true;
      background = {
        displays = {
          HDMI-A-1 = {
            source = ./image.png;
            scaling.mode = "Fit";
            scaling.color = [ 0.2 0.5 0.7 ];
          };
          HDMI-A-2 = {
            source = "~/Wallpapers";
            scaling.mode = "Zoom";
          };
          DP-1 = { source = "~/Wallpapers"; };
        };
        extraConfig = { same-on-all = true; };
      };
    };

    nmt.script = let
      assertFileContent = filename: content: ''
        assertFileContent $config/${filename} ${pkgs.writeText filename content}
      '';
    in ''
      config=home-files/.config/cosmic/com.system76.CosmicBackground/v1

      assertDirectoryExists $config

      ${assertFileContent "same-on-all" "true"}

      ${assertFileContent "backgrounds" ''["DP-1","HDMI-A-1","HDMI-A-2"]''}

      ${assertFileContent "output.HDMI-A-1" ''
        (filter_by_theme: true, filter_method: Lanczos, output: "HDMI-A-1", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Fit((0.200000,0.500000,0.700000)), source: Path("/nix/store/6bm9z6c62phs2dmxisgh16y586dyhw0y-image.png"))''}

      ${assertFileContent "output.HDMI-A-2" ''
        (filter_by_theme: true, filter_method: Lanczos, output: "HDMI-A-2", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Zoom, source: Path("~/Wallpapers"))''}

      ${assertFileContent "output.DP-1" ''
        (filter_by_theme: true, filter_method: Lanczos, output: "DP-1", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Zoom, source: Path("~/Wallpapers"))''}

    '';
  };
}
