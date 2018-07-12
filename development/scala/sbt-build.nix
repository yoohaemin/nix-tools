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
  sbtBootDir = "${tmpDir}/boot";
  sbtIvyHome = "${tmpDir}/.ivy";

  coursierCache = "${tmpDir}/.coursier-cache";

  sbtFlags = "-Dsbt.boot.directory=${sbtBootDir} -Dsbt.ivy.home=${sbtIvyHome} " +
    (if stdenv.lib.inNixShell
    then "-Dsbt.global.base=./.sbt -Dsbt.global.staging=./.staging"
    else "-Dsbt.global.base=$(realpath ./.sbt) -Dsbt.global.staging=$(realpath ./.staging)");

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
    cleanupPhase
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

    export SBT_OPTS="${sbtFlags} ${extraSbtFlags}"

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

  cleanupPhase = ''
    rm -f ${sbtBootDir}/sbt.boot.lock
    chmod -fR o+w ${sbtBootDir}
  '';

} // args
)

