{ pkgs, ... }:

{
  config = {
    programs.cosmic = {
      enable = true;
      background = {
        displays = {
          HDMI-A-1 = {
            source = ./image;
            scaling.mode = "Fit";
            scaling.color = [ 0.2 0.5 0.7 ];
          };
          HDMI-A-2 = {
            source = "~/Wallpapers";
            scaling.mode = "Zoom";
          };
          DP-1 = { source = "~/Wallpapers"; };
        };
      };
    };

    nmt.script = ''

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicBackground/v1/output.HDMI-A-1 \
        ${
          pkgs.writeText "output.HDMI-A-1" ''
            (filter_by_theme: true, filter_method: Lanczos, output: "HDMI-A-1", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Fit((0.200000,0.500000,0.700000)), source: Path("/nix/store/m8bmcy17wj9flqb8rbjn84iwmpmkdgmc-image"))''
        }

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicBackground/v1/output.HDMI-A-2 \
        ${
          pkgs.writeText "output.HDMI-A-2" ''
            (filter_by_theme: true, filter_method: Lanczos, output: "HDMI-A-2", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Zoom, source: Path("~/Wallpapers"))''
        }

      assertFileContent \
        home-files/.config/cosmic/com.system76.CosmicBackground/v1/output.DP-1 \
        ${
          pkgs.writeText "output.DP-1" ''
            (filter_by_theme: true, filter_method: Lanczos, output: "DP-1", rotation_frequency: 300, sampling_method: Alphanumeric, scaling_mode: Zoom, source: Path("~/Wallpapers"))''
        }

      assertFileContent home-files/.config/cosmic/com.system76.CosmicBackground/v1/backgrounds \
        ${pkgs.writeText "backgrounds" ''["DP-1","HDMI-A-1","HDMI-A-2"]''}
    '';
  };
}
