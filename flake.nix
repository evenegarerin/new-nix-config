{
  description = "nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim/nixos-25.11";

    nur.url = "github:nix-community/NUR";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nur,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs;
        };

        modules = [
          ./configuration.nix
          nur.modules.nixos.default

          home-manager.nixosModules.home-manager
        ];
      };
    };
}
