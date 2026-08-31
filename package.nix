{
  lib,
  appimageTools,
  fetchurl,
}:
let
  # Bumped by .github/workflows/update.yml, never by hand — the workflow reads
  # the newest tag from stayfree-app/desktop-releases and rewrites all three
  # fields together. Keeping them in JSON rather than in this file is what
  # lets a shell script edit them without parsing Nix.
  src = builtins.fromJSON (builtins.readFile ./src.json);

  pname = "stayfree";
  inherit (src) version;

  appimage = fetchurl {
    inherit (src) url hash;
    name = "${pname}-${version}.AppImage";
  };

  # Only used to lift the .desktop file and the icon out of the image; the
  # runnable copy is the wrapped AppImage below.
  contents = appimageTools.extract {
    inherit pname version;
    src = appimage;
  };
in
appimageTools.wrapType2 {
  inherit pname version;
  src = appimage;

  extraInstallCommands = ''
    install -Dm444 ${contents}/stayfree-desktop.desktop \
      $out/share/applications/stayfree.desktop
    install -Dm444 ${contents}/usr/share/icons/hicolor/512x512/apps/stayfree-desktop.png \
      $out/share/icons/hicolor/512x512/apps/stayfree-desktop.png

    # The image's own entry runs `AppRun`, which only exists inside the
    # mounted AppImage. --no-sandbox is upstream's own flag and is kept: the
    # wrapper's FHS environment has no setuid chrome-sandbox helper, so
    # Electron refuses to start without it.
    substituteInPlace $out/share/applications/stayfree.desktop \
      --replace-fail 'Exec=AppRun' "Exec=$out/bin/${pname}"
  '';

  meta = {
    description = "Screen-time tracker and website blocker (desktop client)";
    homepage = "https://stayfreeapps.com/";
    downloadPage = "https://github.com/stayfree-app/desktop-releases/releases";
    # Upstream ships binaries only; no licence text accompanies the release.
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
