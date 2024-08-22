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
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-utils, pyk
    , nixpkgs-pyk, poetry2nix, wasm-semantics }@inputs:
    let
      overlay = (final: prev:
        let
          src = prev.lib.cleanSource (prev.nix-gitignore.gitignoreSourcePure [
            "/.github"
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
        in {
          komet = prev.stdenv.mkDerivation {
            pname = "komet";
            src = ./.;
            inherit version;

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
            '';
          };

          komet-pyk = poetry2nix.mkPoetryApplication {
            python = nixpkgs-pyk.python310;
            projectDir = ./.;
            src = rv-utils.lib.mkSubdirectoryAppSrc {
              pkgs = import nixpkgs { system = prev.system; };
              src = ./.;
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
          overlays = [ overlay ];
        };
      in {
        packages = rec {
          inherit (pkgs) komet komet-pyk;
          default = pkgs.komet;
        };
      }) // {
        overlays.default = overlay;
      };
}
