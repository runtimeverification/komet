{
  description = "komet - K tooling for the Soroban platform";

  inputs = {
    rv-nix-tools.url = "github:runtimeverification/rv-nix-tools/854d4f05ea78547d46e807b414faad64cea10ae4";
    nixpkgs.follows = "rv-nix-tools/nixpkgs";
  
    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.128";
    wasm-semantics.inputs.nixpkgs.follows = "nixpkgs";

    k-framework.follows = "wasm-semantics/k-framework";

    flake-utils.follows = "k-framework/flake-utils";

    poetry2nix.follows = "k-framework/poetry2nix";

    rust-overlay.url = "github:oxalica/rust-overlay";

    stellar-cli-flake.url = "github:stellar/stellar-cli";
    stellar-cli-flake.inputs = {
      flake-utils.follows = "flake-utils";
      nixpkgs.follows = "nixpkgs";
      rust-overlay.follows = "rust-overlay";
    };
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-nix-tools, wasm-semantics
    , rust-overlay, stellar-cli-flake, ... }@inputs: flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        # stellar-cli flake does not build on NixOS machines due to openssl issues during `cargo build`
        # putting `pkg-config` in `nativeBuildInputs` will run the `pkg-config` setuphook, which will look for derivations in `buildInputs`
        # with a `pkgconfig` directory such as the `openssl` derivation
        # this will then setup the `PKG_CONFIG_PATH` env variable properly
        stellar-cli-overlay = final: prev: {
          stellar-cli = stellar-cli-flake.packages.${system}.default.overrideAttrs (finalAttrs: previousAttrs: {
            nativeBuildInputs = (previousAttrs.nativeBuildInputs or [ ]) ++ (with final; [
              pkg-config
            ]);
            buildInputs = (previousAttrs.buildInputs or [ ]) ++ (with final; [
              openssl
            ]);
          });
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            stellar-cli-overlay
            (import rust-overlay)
          ];
        };

        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };

        komet-pyk = poetry2nix.mkPoetryApplication {
          python = pkgs.python310;
          projectDir = ./.;
          src = rv-nix-tools.lib.mkSubdirectoryAppSrc {
            inherit pkgs;
            src = ./.;
            subdirectories = [ "pykwasm" ];
            cleaner = poetry2nix.cleanPythonSources;
          };
          overrides = poetry2nix.overrides.withDefaults
            (finalPython: prevPython: {
              kframework = k-framework.packages.${system}.pyk-python310;
              pykwasm = wasm-semantics.packages.${system}.kwasm-pyk;
            });
          groups = [ ];
          checkGroups = [ ];
        };

        mkKomet = {komet-rust ? null, komet-stellar ? null}@args: pkgs.stdenv.mkDerivation {
          pname = "komet";
          version = self.rev or "dirty";
          src = pkgs.lib.cleanSource (pkgs.nix-gitignore.gitignoreSourcePure [
            "/.github"
            "flake.nix"
            "flake.lock"
            ./.gitignore
          ] ./.);

          buildInputs = with pkgs; [
            k-framework.packages.${system}.pyk-python310
            k-framework.packages.${system}.k
            komet-pyk
          ];

          dontUseCmakeConfigure = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          enableParallelBuilding = true;

          buildPhase = ''
            export XDG_CACHE_HOME=$(pwd)
            ${
              pkgs.lib.optionalString
              (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin)
              "APPLE_SILICON=true"
            } K_OPTS="-Xmx8G -Xss512m" kdist -v build soroban-semantics.* -j$NIX_BUILD_CORES
          '';

          installPhase = ''
            mkdir -p $out
            cp -r ./kdist-*/* $out/

            makeWrapper ${komet-pyk}/bin/komet $out/bin/komet --prefix PATH : ${
              pkgs.lib.makeBinPath (
                [
                  k-framework.packages.${system}.k
                ] ++ pkgs.lib.optionals (komet-rust != null) [
                  komet-rust
                ] ++ pkgs.lib.optionals (komet-stellar != null) [
                  komet-stellar
                ]
              )
            } --set KDIST_DIR $out
          '';

          passthru = if komet-rust == null && komet-stellar == null then {
            rust-stellar = pkgs.callPackage mkKomet (args // {
              komet-rust = rustWithWasmTarget;
              komet-stellar = pkgs.stellar-cli;
            });
          } else { };
        };
        komet = pkgs.callPackage mkKomet { };

        rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32v1-none" ];
        };
      in {
        packages = rec {
          inherit komet komet-pyk;
          default = komet;
        };

        devShell = pkgs.mkShell {
          buildInputs = [ pkgs.stellar-cli komet rustWithWasmTarget ];

          shellHook = ''
            ${pkgs.lib.strings.optionalString
            (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin)
            "export APPLE_SILICON=true"}
          '';
        };

      }) // {
        overlays.default = final: prev: {
          inherit (self.packages.${final.system}) komet komet-pyk;
        };
      };
}
