# Include the patch registry as well as patch contents, so changing platform
# selection also requires publishing fresh source snapshots.
builtins.hashString "sha256" (
  builtins.toJSON (
    map (name: {
      inherit name;
      content = builtins.readFile (../patches + "/${name}");
    }) (builtins.attrNames (builtins.readDir ../patches))
  )
)
