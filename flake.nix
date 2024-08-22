{
  description = "komet - K tooling for the Soroban platform";

  inputs = {
    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.98";
    k-framework.url = "github:runtimeverification/k/v7.1.103";
    pyk.url = "github:runtimeverification/k/v7.1.103?dir=pyk";
    nixpkgs.follows = "k-framework/nixpkgs";
    flake-utils.follows = "k-framework/flake-utils";
    rv-utils.url = "github:runtimeverification/rv-nix-tools";
    nixpkgs-pyk.follows = "pyk/nixpkgs";
    poetry2nix.follows = "pyk/poetry2nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-utils, pyk
    , nixpkgs-pyk, poetry2nix, wasm-semantics, rust-overlay }@inputs:
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

          nixpkgs-pyk = import inputs.nixpkgs-pyk {
            system = prev.system;
            overlays = [ pyk.overlay ];
          };

          python310-pyk = nixpkgs-pyk.python310;

          poetry2nix =
            inputs.poetry2nix.lib.mkPoetry2Nix { pkgs = nixpkgs-pyk; };
        in rec {
          komet = prev.stdenv.mkDerivation {
            pname = "komet";
            inherit src version;

            buildInputs = with final; [
              nixpkgs-pyk.pyk-python310
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

              makeWrapper ${komet-pyk}/bin/ksoroban $out/bin/ksoroban --prefix PATH : ${
                prev.lib.makeBinPath [ k-framework.packages.${prev.system}.k ]
              } --set KDIST_DIR $out
            '';
          };

          komet-pyk = poetry2nix.mkPoetryApplication {
            python = nixpkgs-pyk.python310;
            projectDir = ./.;
            src = rv-utils.lib.mkSubdirectoryAppSrc {
              pkgs = import nixpkgs { system = prev.system; };
              inherit src;
              subdirectories = [ "pykwasm" ];
              cleaner = poetry2nix.cleanPythonSources;
            };
            overrides = poetry2nix.overrides.withDefaults
              (finalPython: prevPython: {
                cmd2 = prevPython.cmd2.overridePythonAttrs (old: {
                  propagatedBuildInputs = prev.lib.filter
                    (x: !(prev.lib.strings.hasInfix "exceptiongroup" x.name))
                    old.propagatedBuildInputs ++ [ finalPython.exceptiongroup ];
                });
                pytest = prevPython.pytest.overridePythonAttrs (old: {
                  propagatedBuildInputs = prev.lib.filter
                    (x: !(prev.lib.strings.hasInfix "attrs" x.name))
                    old.propagatedBuildInputs ++ [ finalPython.attrs ];
                });
                kframework = nixpkgs-pyk.pyk-python310.overridePythonAttrs
                  (old: {
                    propagatedBuildInputs = prev.lib.filter (x:
                      !(prev.lib.strings.hasInfix "hypothesis" x.name)
                      && !(prev.lib.strings.hasInfix "pytest" x.name)
                      && !(prev.lib.strings.hasInfix "cmd2" x.name))
                      old.propagatedBuildInputs ++ [
                        finalPython.hypothesis
                        finalPython.pytest
                        finalPython.cmd2
                      ];
                  });
                pykwasm =
                  wasm-semantics.packages.${prev.system}.kwasm-pyk.overridePythonAttrs
                  (old: {
                    propagatedBuildInputs = prev.lib.filter
                      (x: !(prev.lib.strings.hasInfix "kframework" x.name))
                      old.propagatedBuildInputs ++ [ finalPython.kframework ];
                  });
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
