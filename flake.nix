{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devkitNix.url = "github:bandithedoge/devkitNix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devkitNix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [devkitNix.overlays.default];
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = [pkgs.devkitNix.devkitARM pkgs.zig pkgs.glibc];
        shellHook = ''
          ${pkgs.devkitNix.devkitARM.shellHook}
        '';
      };
      packages.default = pkgs.stdenv.mkDerivation {
        name = "rocket-slime-rom-dumper";
        src = ./.;
        nativeBuildInputs = [pkgs.zig pkgs.devkitNix.devkitARM pkgs.glibc ];
        preBuild = pkgs.devkitNix.devkitARM.shellHook;


        configurePhase = ''
          export ZIG_GLOBAL_CACHE_DIR=$out/.zig-cache;
          export DEVKITPRO=${pkgs.devkitNix.devkitARM}/opt/devkitpro;
          mkdir -p $ZIG_GLOBAL_CACHE_DIR;
        '';
        buildPhase = "zig build";
        installPhase = ''
          mkdir -p $out/bin
          cp zig-out/bin/main $out/bin/rocket-slime-rom-dumper
          '';
      };
    });
}
