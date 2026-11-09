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
    hash = "sha256-pl3vepIJli5uleXb9hZx5EwK5WjcKVmwCdvw6+7mx9A=";
  };

  postPatch = ''
    cp --no-preserve=mode ${./vtop/package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-EaaBAGfATMprjYx+TFJtElZJ4qj8iqTbUy7VVVmlwbg=";
  dontBuild = true; # plain JS, no build step

  meta.mainProgram = "vtop";
}
