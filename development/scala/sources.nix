{ stdenv }:

rec {

  cleanScalaSourceFilter = name: type: let baseName = baseNameOf (toString name); in !(
    # Filter out CVS directory
    (type == "directory" && (baseName == ".git" || baseName == ".svn")) ||
    # filter out nix-build result symlinks
    (type == "symlink" && stdenv.lib.hasPrefix "result" baseName) ||
    # Filter out sbt build artefacts 
    (type == "directory" && stdenv.lib.hasPrefix "target" baseName) ||
    # Filter out CI files, Readme, ...
    (type == "regular" && (baseName == "README.md")) ||
    (type == "regular" && (baseName == "Makefile")) ||
    (type == "regular" && (baseName == ".codacy.yaml" || baseName == ".gitignore" || baseName == ".travis.yml")) ||
    # Filter out editor backup / swap files.
    stdenv.lib.hasSuffix "~" baseName ||
    builtins.match "^\\.sw[a-z]$" baseName != null ||
    builtins.match "^\\..*\\.sw[a-z]$" baseName != null
  );

}

