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
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-nix-tools, wasm-semantics
    , rust-overlay, ... }@inputs:
    let
      overlay = (final: prev:
        let
          src = prev.lib.cleanSource (prev.nix-gitignore.gitignoreSourcePure [
            "/.github"
            "flake.nix"
            "flake.lock"
            ./.gitignore
          ] ./.);

          version = self.rev or "dirty";
          poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { pkgs = prev; };
        in rec {
          komet = prev.stdenv.mkDerivation {
            pname = "komet";
            inherit src version;

            buildInputs = with final; [
              k-framework.packages.${system}.pyk-python310
              k-framework.packages.${system}.k
              komet-pyk
            ];

            dontUseCmakeConfigure = true;

            nativeBuildInputs = [ prev.makeWrapper ];

            enableParallelBuilding = true;

            buildPhase = ''
              export XDG_CACHE_HOME=$(pwd)
              ${
                prev.lib.optionalString
                (prev.stdenv.isAarch64 && prev.stdenv.isDarwin)
                "APPLE_SILICON=true"
              } K_OPTS="-Xmx8G -Xss512m" kdist -v build soroban-semantics.* -j$NIX_BUILD_CORES
            '';

            installPhase = ''
              mkdir -p $out
              cp -r ./kdist-*/* $out/

              makeWrapper ${komet-pyk}/bin/komet $out/bin/komet --prefix PATH : ${
                prev.lib.makeBinPath [ k-framework.packages.${prev.system}.k ]
              } --set KDIST_DIR $out
            '';
          };

          komet-pyk = poetry2nix.mkPoetryApplication {
            python = prev.python310;
            projectDir = ./.;
            src = rv-nix-tools.lib.mkSubdirectoryAppSrc {
              pkgs = import nixpkgs { system = prev.system; };
              src = ./.;
              subdirectories = [ "pykwasm" ];
              cleaner = poetry2nix.cleanPythonSources;
            };
            overrides = poetry2nix.overrides.withDefaults
              (finalPython: prevPython: {
                kframework = k-framework.packages.${prev.system}.pyk-python310;
                pykwasm = wasm-semantics.packages.${prev.system}.kwasm-pyk;
              });
            groups = [ ];
            checkGroups = [ ];
          };
        });
    in flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay (import rust-overlay) ];
        };

        rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
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
          inherit (pkgs) komet komet-pyk;
          default = pkgs.komet;
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ stellar-cli komet rustWithWasmTarget ];

          shellHook = ''
            ${pkgs.lib.strings.optionalString
            (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin)
            "export APPLE_SILICON=true"}
          '';
        };

      }) // {
        overlays.default = overlay;
      };
}
