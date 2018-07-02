{ pkgs
}:

with pkgs;

rec {

  datadog = callPackage ./pkgs/misc/datadog.nix {};

  sbtBuild = args: import ./development/scala/sbt-build.nix (
    { inherit stdenv;
    } // args);

  cleanScalaSourceFilter = (import ./development/scala/sources.nix (
    { inherit stdenv;
  })).cleanScalaSourceFilter;

}

