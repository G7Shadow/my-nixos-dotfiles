{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.18.32";
  src =
    if stdenv.hostPlatform.system == "x86_64-linux"
    then
      fetchurl {
        url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
        sha256 = "sha256-MEbgQE/cYPuAMH56R4JLoHR3NkF4pNCbqoVISW3W1Ds=";
      }
    else throw "opencode: unsupported system ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version src;

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "The open source coding agent";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}