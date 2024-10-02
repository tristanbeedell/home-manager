{
  config = {
    programs.cosmic = { enable = false; };

    nmt.script = ''
      assertPathNotExists home-files/.config/cosmic
    '';
  };
}
