{
  lib,
  stdenvNoCC,
  python3,
  glib,
  gtk4,
  gtk4-layer-shell,
  gsettings-desktop-schemas,
  gobject-introspection,
  wrapGAppsHook4,
  showmethekey,
}:

let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "visual-keys";
  version = "0.1.0";

  src = ./visual-keys/visual-keys.py;

  dontUnpack = true;
  strictDeps = true;

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];

  buildInputs = [
    python
    glib
    gtk4
    gtk4-layer-shell
    gsettings-desktop-schemas
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/visual-keys

    substituteInPlace $out/bin/visual-keys \
      --replace-fail '#!/usr/bin/env python' '#!${python.interpreter}' \
      --replace-fail '["showmethekey-cli"]' '["${lib.getExe' showmethekey "showmethekey-cli"}"]'

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set LD_PRELOAD "${gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
    )
  '';

  meta = {
    description = "On-screen display of the keys currently held down";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "visual-keys";
  };
}
