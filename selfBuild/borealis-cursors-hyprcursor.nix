{
  runCommand,
  hyprcursor,
  xcur2png,
  borealis-cursors,
}:

let
  themeName = "Borealis-cursors";
in
runCommand "borealis-cursors-hyprcursor-${borealis-cursors.version}"
  {
    nativeBuildInputs = [
      hyprcursor
      xcur2png
    ];

    meta = borealis-cursors.meta or { };
  }
  ''
    hyprcursor-util --extract ${borealis-cursors}/share/icons/${themeName} --output .

    substituteInPlace extracted_${themeName}/manifest.hl \
      --replace-fail "name = Extracted Theme" "name = ${themeName}"

    hyprcursor-util --create extracted_${themeName} --output .

    install -d $out/share/icons/${themeName}
    cp -r --no-preserve=mode ${borealis-cursors}/share/icons/${themeName}/. $out/share/icons/${themeName}/
    cp -r --no-preserve=mode theme_${themeName}/. $out/share/icons/${themeName}/
  ''
