{
  description = "GNOME development shell for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    mkDevShell = system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        # shellHook = "exec /run/current-system/sw/bin/zsh";
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          cargo
          clippy
          gtk4
          rustc
          rustfmt
        ] ++ (with python313Packages; [
          darkdetect
          pycairo
          pygobject3
        ]);
      };
    };
  in {
    devShells = nixpkgs.lib.genAttrs supportedSystems (system: mkDevShell system);
  };
}
