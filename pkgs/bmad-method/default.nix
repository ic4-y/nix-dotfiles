{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_22
}:

# BMAD CLI packaged like other Node-based CLIs in nixpkgs:
# - Uses buildNpmPackage
# - Pins GitHub source at v6.0.0-alpha.7
# - Uses npmDepsHash for reproducible dependencies
# - Exposes `bmad` and `bmad-method` binaries
buildNpmPackage rec {
  pname = "bmad-method";
  version = "6.0.0-alpha.7";

  src = fetchFromGitHub {
    owner = "bmad-code-org";
    repo = "BMAD-METHOD";
    rev = "v${version}";
    # NOTE: this is the source hash; already provided earlier.
    hash = "sha256-INca6adWNZpk/M20hqgTDhTmmCKm4I80WfJWvG2r4JA=";
  };

  nodejs = nodejs_22;

  # IMPORTANT:
  # Run the following once (outside Nix sandbox) to compute this:
  #   nix run nixpkgs#nix-prefetch-git -- \
  #     https://github.com/bmad-code-org/BMAD-METHOD v6.0.0-alpha.7
  # then:
  #   (cd BMAD-METHOD && npm ci && nix hash path ./node_modules)
  # and paste resulting sha256 here.
  #
  # For now this is a placeholder that MUST be updated, otherwise buildNpmPackage will fail.
  npmDepsHash = "sha256-2osPZxMDZ3vsG1+yZFPcHttyLuS+NnNnBQ6kWMJmm0o=";

  npmBuildScript = null;
  npmInstallFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  # BMAD is a CLI; no additional build step, just install and wire bins.
  installPhase = ''
        runHook preInstall

        mkdir -p "$out/lib/node_modules/${pname}" "$out/bin"

        # buildNpmPackage has already produced node_modules in $PWD.
        # Install package.json, JS sources, and node_modules into the module root.
        cp -R . "$out/lib/node_modules/${pname}"

        # Ensure the npm "bin" entries are exposed:
        #   "bmad": "tools/bmad-npx-wrapper.js"
        #   "bmad-method": "tools/bmad-npx-wrapper.js"
        cat > "$out/bin/bmad" <<EOF
    #!${nodejs_22}/bin/node
    require(require('path').join(__dirname, '..', 'lib', 'node_modules', '${pname}', 'tools', 'bmad-npx-wrapper.js'));
    EOF

        cat > "$out/bin/bmad-method" <<EOF
    #!${nodejs_22}/bin/node
    require(require('path').join(__dirname, '..', 'lib', 'node_modules', '${pname}', 'tools', 'bmad-npx-wrapper.js'));
    EOF

        chmod +x "$out/bin/bmad" "$out/bin/bmad-method"

        runHook postInstall
  '';

  meta = with lib; {
    description = "Breakthrough Method of Agile AI-driven Development (BMAD) CLI";
    homepage = "https://github.com/bmad-code-org/BMAD-METHOD";
    license = licenses.mit;
    mainProgram = "bmad";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
