{
  description = "StayFree desktop (screen-time tracker / website blocker) packaged for Nix — upstream ships no Nix build";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Upstream builds an x86_64 AppImage only; there is nothing to package
      # for aarch64, so the flake does not pretend to offer it.
      systems = [ "x86_64-linux" ];
      # StayFree is proprietary freeware, so package.nix marks it unfree.
      # legacyPackages would therefore refuse to build it here; a consumer that
      # uses overlays.default supplies its own (unfree-allowing) pkgs instead.
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );
    in
    {
      overlays.default = _final: prev: {
        stayfree = prev.callPackage ./package.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        stayfree = pkgs.callPackage ./package.nix { };
        default = stayfree;
      });

      checks = forAllSystems (pkgs: { inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) stayfree; });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
