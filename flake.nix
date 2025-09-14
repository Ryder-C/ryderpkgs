{
  description = "Ryder's collection of Nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      src = pkgs.fetchFromGitHub {
        owner = "JustTemmie";
        repo = "steam-presence";
        rev = "v1.12.2";
        hash = "sha256-6w8ZsLc0+p0EByNhbs10+5AWvOiEmIE1eyxoN4VHYhQ=";
      };

      steam-presence-pkg = pkgs.callPackage ./pkgs/steam-presence {
        inherit src;
      };
    in {
      # Expose all your packages
      packages = {
        steam-presence = steam-presence-pkg;
      };

      # You can also expose home-manager modules in the same way
      homeManagerModules = {
        steam-presence = import ./hm-modules/steam-presence.nix;
      };
    });
}
