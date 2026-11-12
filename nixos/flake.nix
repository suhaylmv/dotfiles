{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zen-browser, spicetify-nix, ... }: {
    nixosConfigurations.excalibur = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit zen-browser spicetify-nix; };
      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        ./configuration.nix
        ./hardware-configuration.nix
        ./modules/spicetify.nix
      ];
    };
  };
}
