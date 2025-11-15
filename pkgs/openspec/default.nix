{ lib
, fetchFromGitHub
, nodejs_22
, pnpm
, stdenv
, makeWrapper
}:

# OpenSpec CLI packaged using pnpm for proper lockfile support
# - Pins GitHub source at v0.15.0
# - Uses pnpm.fetchDeps for reproducible dependencies from pnpm-lock.yaml
# - Exposes `openspec` binary
stdenv.mkDerivation (finalAttrs: rec {
  pname = "openspec";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Wb0m2ZRmOXNj6DOK9cyGYzFLNTQjLO+czDxzIHfADnY=";
  };

  # Use pnpm to fetch dependencies from pnpm-lock.yaml
  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-H/1GbLCiSRgZvz5k+I64tatGuhixyUDqs8gjOsnKBz4=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    nodejs_22
    pnpm.configHook
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    # Install dependencies using pnpm
    pnpm install --frozen-lockfile

    # Build the project
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/openspec"
    cp -r dist node_modules "$out/lib/openspec"
    cp package.json "$out/lib/openspec"
    
    # Use makeWrapper to create the binary wrapper
    makeWrapper "${lib.getExe nodejs_22}" "$out/bin/openspec" \
      --add-flags "$out/lib/openspec/dist/cli/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI-native system for spec-driven development";
    homepage = "https://github.com/Fission-AI/OpenSpec";
    license = licenses.mit;
    mainProgram = "openspec";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
