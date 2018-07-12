{ stdenv
, name
, src ? ./.
, tmpDir ? "$TMPDIR"
, doTest ? true
, doTestCompile ? true
, doIntegrationTest ? false
, doIntegrationTestCompile ? false
, doScaladoc ? false
, extraSbtFlags ? ""
, extraSbtPlugins ? ""
, extraSbtSettings ? ""
, ...
} @ args:

let
  tempDir = if stdenv.lib.inNixShell
    then tmpDir
    else "$TMPDIR";

  sbtBootDir = "${tempDir}/boot";
  sbtIvyHome = "${tempDir}/.ivy";

  coursierCache = "${tempDir}/.coursier-cache";

  sbtFlags = "-Dsbt.boot.directory=${sbtBootDir} -Dsbt.ivy.home=${sbtIvyHome} " +
    (if stdenv.lib.inNixShell
    then "-Dsbt.global.base=./.sbt -Dsbt.global.staging=./.staging "
    else "-Dsbt.global.base=$(realpath ./.sbt) -Dsbt.global.staging=$(realpath ./.staging) ") + extraSbtFlags;

in

stdenv.mkDerivation ( rec {
  inherit name src;

  SBT_OPTS = sbtFlags;

  phases = ''
    setupPhase
    unpackPhase
    patchPhase
    sbtCompile
    ${if doTestCompile then "sbtTestCompile" else ""}
    ${if doTest then "sbtTest" else ""}
    ${if doIntegrationTestCompile then "sbtIntegrationTestCompile" else ""}
    ${if doIntegrationTest then "sbtIntegrationTest" else ""}
    ${if doScaladoc then "sbtScaladoc" else ""}
    sbtStage
    finalPhase
  '';

  setupPhase = ''
    runHook preSetupPhase

    mkdir -p $out/nix-support
    export LANG="en_US.UTF-8"

    mkdir -p ${sbtBootDir}
    mkdir -p ${sbtIvyHome}

    mkdir -p ${coursierCache}
    export COURSIER_CACHE=${coursierCache}

    rm -f ${sbtBootDir}/sbt.boot.lock

    mkdir -p ./.sbt
    cat > ./.sbt/build.sbt <<EOF
    ${extraSbtSettings}
    EOF

    mkdir -p ./.sbt/plugins
    cat > ./.sbt/plugins/plugins.sbt <<EOF
    ${extraSbtPlugins}
    EOF

    export SBT_OPTS="${sbtFlags}"

    runHook postSetupPhase
  '';

  sbtCompile = ''
    sbt compile
  '';

  sbtTestCompile = ''
    sbt test:compile
  '';

  sbtTest = ''
    sbt test:test
  '';

  sbtIntegrationTestCompile = ''
    sbt it:compile
  '';

  sbtIntegrationTest = ''
    sbt it:test
  '';

  sbtScaladoc = ''
    sbt doc
  '';

  sbtStage = ''
    sbt stage
  '';

  finalPhase = ''
    if [ -d target/universal/stage ] ; then
      cp -ra target/universal/stage/* $out
    fi
  '';


} // args
)

