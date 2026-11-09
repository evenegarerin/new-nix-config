{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "vimnm";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "MatchaTi";
    repo = "vimnm";
    rev = "v${version}";
    hash = "sha256-3AnXfaflcWHo+yuzZEDGUxzpblZmORAbxxMxBKYkXy8=";
  };

  vendorHash = "sha256-SMhllO87YlmySHroKfPq1pHb67CwHaZ3XMp3t983etc=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Vim-motion TUI for managing Wi-Fi via NetworkManager";
    homepage = "https://github.com/MatchaTi/vimnm";
    license = lib.licenses.mit;
    mainProgram = "vimnm";
  };
}
