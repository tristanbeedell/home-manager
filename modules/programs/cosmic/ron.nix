{ lib }:
let
  inherit (lib)
    filterAttrs concatStrings concatStringsSep mapAttrsToList concatLists
    foldlAttrs concatMapAttrs mapAttrs' nameValuePair boolToString maintainers
    mkOption types;
  inherit (builtins) typeOf toString stringLength;
in rec {
  # list -> array
  array = a: "[${concatStringsSep "," (map serialise a)}]";
  # attrset -> hashmap
  _assoc = a: mapAttrsToList (name: val: "${name}: ${val},") a;
  assoc = a: ''
    {
        ${concatStringsSep "\n    " (concatLists (map _assoc a))}
    }
  '';

  stringArray = a: array (map toQuotedString a);

  tuple = a: "(${concatStringsSep "," (map serialise a)})";
  enum = s:
    if isNull s.value then
      s.name
    else
      concatStrings [ s.name "(" (serialise s.value) ")" ];

  option = value:
    if isNull value then
      "None"
    else
      enum {
        name = "Some";
        inherit value;
      };

  # attrset -> struct
  _struct_kv = k: v:
    if v == null then "" else (concatStringsSep ": " [ k (serialise v) ]);
  _struct_concat = s:
    foldlAttrs (acc: k: v:
      if stringLength acc > 0 then
        concatStringsSep ", " [ acc (_struct_kv k v) ]
      else
        _struct_kv k v) "" s;
  _struct_filt = s: _struct_concat (filterAttrs (k: v: v != null) s);
  struct = s: "(${_struct_filt s})";
  toQuotedString = s: ''"${toString s}"'';
  path = p: ''Path("${p}")'';

  # make an attrset for struct serialisation
  serialisers = {
    int = toString;
    float = toString;
    bool = boolToString;
    # can't assume quoted string, sometimes it's a Rust enum
    string = toString;
    path = path;
    null = _: "None";
    set = struct;
    list = array;
  };

  serialise = v: serialisers.${typeOf v} v;
}
