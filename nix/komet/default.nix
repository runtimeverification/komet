{
  lib,
  stdenv,
  makeWrapper,
  callPackage,

  clang,
  cmake,
  git,
  k,
  boost,
  mpfr,
  openssl,
  gmp,
  secp256k1,
  which,
  rust-bin,

  komet-rust ? null,
  komet-pyk,
  rev ? null
} @ args:
let
  rustWithWasmTarget = rust-bin.stable.latest.default.override {
    targets = [ "wasm32-unknown-unknown" ];
  };
in
stdenv.mkDerivation {
  pname = "komet";
  version = if (rev != null) then rev else "dirty";

  outputs = [
    "bin"
    # contains kdist artifacts
    "out"
    # this empty `dev` output is required as we otherwise get cyclic dependencies between `bin` and `out`
    # this is due to a setup-hook creating references in a new directory `nix-support` in either `out` or `dev`
    "dev"
  ];

  buildInputs = [
    clang
    cmake
    git
    boost
    mpfr
    openssl
    gmp
    secp256k1
    komet-pyk
    k
  ];

  nativeBuildInputs = [ makeWrapper ];

  src = callPackage ../komet-source { };

  dontUseCmakeConfigure = true;

  enableParallelBuilding = true;

  buildPhase = ''
    XDG_CACHE_HOME=$(pwd) ${
      lib.optionalString
      (stdenv.isAarch64 && stdenv.isDarwin)
      "APPLE_SILICON=true"
    } komet-kdist -v build 'soroban-semantics.*'
  '';

  installPhase = ''
    mkdir -p $bin/bin
    mkdir -p $out/kdist

    cp -r ./kdist-*/* $out/kdist/

    makeWrapper ${komet-pyk}/bin/komet $bin/bin/komet --prefix PATH : ${
      lib.makeBinPath
      ([ which k ] ++ lib.optionals (komet-rust != null) [
        komet-rust
      ])
    } --set KDIST_DIR $out/kdist
  '';

  passthru = if komet-rust == null then {
    # list all supported solc versions here
    rust = callPackage ./default.nix (args // { komet-rust = rustWithWasmTarget; });
  } else { };
}