# Prebuilt lazyjira release binary (same artifact as AUR lazyjira-bin).
# Bump: set `version`, then `hash` to the sha256 shown on the GitHub release asset
# (`nix hash convert --hash-algo sha256 --to sri <hex>`).
{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lazyjira";
  version = "2.19.2";

  src = fetchurl {
    url = "https://github.com/textfuel/lazyjira/releases/download/v${finalAttrs.version}/lazyjira_linux_amd64.tar.gz";
    hash = "sha256-UDtOJvRpeW2hH62++Xmgsu3g17rWPDvDTtbeeza3IUw=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 lazyjira $out/bin/lazyjira
    install -Dm644 LICENSE $out/share/licenses/lazyjira/LICENSE
    runHook postInstall
  '';

  meta = {
    description = "Terminal UI for Jira";
    homepage = "https://github.com/textfuel/lazyjira";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lazyjira";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
