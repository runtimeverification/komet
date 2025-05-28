{
  description = "komet - K tooling for the Soroban platform";

  inputs = {
    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.128";
    k-framework.follows = "wasm-semantics/k-framework";
    nixpkgs.follows = "k-framework/nixpkgs";
    flake-utils.follows = "k-framework/flake-utils";
    rv-utils.follows = "k-framework/rv-utils";
    poetry2nix.follows = "k-framework/poetry2nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-utils, wasm-semantics
    , rust-overlay, ... }@inputs: flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };

        komet-pyk = poetry2nix.mkPoetryApplication {
          python = pkgs.python310;
          projectDir = ./.;
          src = rv-utils.lib.mkSubdirectoryAppSrc {
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

        komet = pkgs.stdenv.mkDerivation {
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
              pkgs.lib.makeBinPath [ k-framework.packages.${system}.k ]
            } --set KDIST_DIR $out
          '';
        };

        rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32v1-none" ];
        };

        rustPlatformWasm = pkgs.makeRustPlatform {
          cargo = rustWithWasmTarget;
          rustc = rustWithWasmTarget;
        };

        version = "21.4.0";
        stellar-src = pkgs.fetchFromGitHub {
          owner = "stellar";
          repo = "stellar-cli";
          rev = "v${version}";
          hash = "sha256-yPg0Tsnb7H7S1MbVvfWrAmTWehWqwJYSqYLqLWVNq0Y=";
        };

        stellar-cli = rustPlatformWasm.buildRustPackage rec {
          pname = "stellar-cli";
          inherit version;
          src = stellar-src;

          nativeBuildInputs = [ pkgs.pkg-config ]
            ++ (if pkgs.stdenv.isDarwin then
              [ pkgs.darwin.apple_sdk.frameworks.SystemConfiguration ]
            else
              [ ]);

          buildInputs = [ pkgs.openssl pkgs.openssl.dev ];

          OPENSSL_NO_VENDOR = 1;
          GIT_REVISION = "v${version}";

          doCheck = false;

          cargoLock = {
            lockFile = "${stellar-src}/Cargo.lock";
            outputHashes = {
              "testcontainers-0.15.0" =
                "sha256-v9HJ0cgDgTCRwB6lPm425EmVq3L9oNI8NVCzv4T2HOQ=";
            };
          };

        };

      in {
        packages = rec {
          inherit komet komet-pyk;
          default = komet;
        };

        devShell = pkgs.mkShell {
          buildInputs = [ stellar-cli komet rustWithWasmTarget ];

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
