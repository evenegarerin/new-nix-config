{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "vtop";
  version = "0.6.1"; # check the latest tag

  src = fetchFromGitHub {
    owner = "MrRio";
    repo = "vtop";
    rev = "v${version}";
    hash = lib.fakeHash; # build once, copy the real hash from the error
  };

  npmDepsHash = lib.fakeHash; # same trick
  dontNpmBuild = true; # plain JS, no build step

  meta.mainProgram = "vtop";
}
