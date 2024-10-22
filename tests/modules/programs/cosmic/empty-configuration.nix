{
  /* this is to ensure we aren't creating defaults where the user hasn't
     specified anything.
  */
  programs.cosmic = {
    enabled = true;
    comp = {
      settings = {
        workspaces = { };
        input_default = { };
      };
      extraConfig = { };
    };
    input = { };
    background = {
      displays = { };
      extraConfig = { };
    };
    panels = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/cosmic
  '';
}
