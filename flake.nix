{
  description = "komet - K tooling for the Soroban platform";

  inputs = {
    rv-nix-tools.url = "github:runtimeverification/rv-nix-tools/854d4f05ea78547d46e807b414faad64cea10ae4";
    nixpkgs.follows = "rv-nix-tools/nixpkgs";
  
    flake-utils.url = "github:numtide/flake-utils";

    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.146";
    wasm-semantics.inputs.nixpkgs.follows = "nixpkgs";
    k-framework.follows = "wasm-semantics/k-framework";

    uv2nix.url = "github:pyproject-nix/uv2nix/be511633027f67beee87ab499f7b16d0a2f7eceb";
    # uv2nix requires a newer version of nixpkgs
    # therefore, we pin uv2nix specifically to a newer version of nixpkgs
    # until we replaced our stale version of nixpkgs with an upstream one as well
    # but also uv2nix requires us to call it with `callPackage`, so we add stuff
    # from the newer nixpkgs to our stale nixpkgs via an overlay
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    # uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs/dbfc0483b5952c6b86e36f8b3afeb9dde30ea4b5";
    pyproject-build-systems = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.uv2nix.follows = "uv2nix";
      inputs.pyproject-nix.follows = "uv2nix/pyproject-nix";
    };
    pyproject-nix.follows = "uv2nix/pyproject-nix";

    rust-overlay.url = "github:oxalica/rust-overlay";

    stellar-cli-flake.url = "github:stellar/stellar-cli";
    stellar-cli-flake.inputs = {
      flake-utils.follows = "flake-utils";
      nixpkgs.follows = "nixpkgs";
      rust-overlay.follows = "rust-overlay";
    };
  };

  outputs = { self, rv-nix-tools, nixpkgs, flake-utils, pyproject-nix, pyproject-build-systems, uv2nix
            , k-framework, wasm-semantics, rust-overlay, stellar-cli-flake, nixpkgs-unstable }: 
  let
    pythonVer = "310";
  in flake-utils.lib.eachSystem [
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-linux"
    "aarch64-darwin"
  ] (system:
    let
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
      };
      # for uv2nix, remove this once we updated to a newer version of nixpkgs
      staleNixpkgsOverlay = final: prev: {
        inherit (pkgs-unstable) replaceVars;
      };
      # due to the nixpkgs that we use in this flake being outdated, uv is also heavily outdated
      # we can instead use the binary release of uv provided by uv2nix for now
      uvOverlay = final: prev: {
        uv = uv2nix.packages.${final.system}.uv-bin;
      };
      # create custom overlay for k, because the overlay in k-framework currently also includes a lot of other stuff instead of only k
      kOverlay = final: prev: {
        k = k-framework.packages.${final.system}.k;
      };
      
      kometOverlay = final: prev:
      let
        komet-pyk = final.callPackage ./nix/komet-pyk {
          inherit pyproject-nix pyproject-build-systems uv2nix;
          python = final."python${pythonVer}";
        };
        komet = final.callPackage ./nix/komet {
          inherit komet-pyk;
          rev = self.rev or null;
        };
      in {
        inherit komet;
      };

      # stellar-cli flake does not build on NixOS machines due to openssl issues during `cargo build`
      # putting `pkg-config` in `nativeBuildInputs` will run the `pkg-config` setuphook, which will look for derivations in `buildInputs`
      # with a `pkgconfig` directory such as the `openssl` derivation
      # this will then setup the `PKG_CONFIG_PATH` env variable properly
      stellar-cli-overlay = final: prev: {
        stellar-cli = stellar-cli-flake.packages.${system}.default.overrideAttrs (finalAttrs: previousAttrs:
        let
          nativeBuildInputs' = (previousAttrs.nativeBuildInputs or [ ]) ++ (with final; [
            pkg-config
          ]);
        in {
          # remove `auditable` since it expects rust 2024, but cannot find it
          # this is usually disabled by passing `auditable = false;` to `buildRustPackage`
          # however, nixpkgs does not let us properly override this post-mortem, so we have to remove the auditable package
          #  that inevitably got add in `stellar-cli` flake
          nativeBuildInputs = builtins.filter (pkg: !final.lib.strings.hasPrefix "auditable-" pkg.name) nativeBuildInputs';
          buildInputs = (previousAttrs.buildInputs or [ ]) ++ (with final; [
            openssl
          ]) ++ final.lib.optionals final.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.AppKit
          ];
        });
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          staleNixpkgsOverlay
          uvOverlay
          kOverlay
          kometOverlay
          stellar-cli-overlay
          (import rust-overlay)
        ];
      };

      python = pkgs."python${pythonVer}";

      rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
        targets = [ "wasm32v1-none" ];
      };

    in {
      packages = rec {
        inherit (pkgs) komet;
        default = komet;
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          k
          python
          uv
          which
        ];
        env = {
          # prevent uv from managing Python downloads and force use of specific 
          UV_PYTHON_DOWNLOADS = "never";
          UV_PYTHON = python.interpreter;
        };
        shellHook = ''
          unset PYTHONPATH
        '' + pkgs.lib.strings.optionalString (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin) ''
          export APPLE_SILICON=true
        '';
      };
    }) // {
      overlays.default = final: prev: {
        inherit (self.packages.${final.system}) komet;
      };
    };
}
