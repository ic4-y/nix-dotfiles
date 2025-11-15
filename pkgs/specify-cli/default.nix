{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonApplication rec {
  pname = "specify-cli";
  version = "0.0.20";

  src = fetchFromGitHub {
    owner = "github";
    repo = "spec-kit";
    rev = "v0.0.20";
    # Hash from 'nix build' error: got: sha256-tkCqPh4+m1gUztRbwjJMAVSDmgd6LYtg2V9TSJ6pmeg=
    hash = "sha256-tkCqPh4+m1gUztRbwjJMAVSDmgd6LYtg2V9TSJ6pmeg=";
  };

  pyproject = true;

  nativeBuildInputs = with python3.pkgs; [
    hatchling
  ];

  propagatedBuildInputs = with python3.pkgs; [
    typer
    rich
    httpx
    platformdirs
    readchar
    truststore
  ];

  doCheck = false;

  meta = with lib; {
    description = "Specify CLI, part of GitHub Spec Kit. A tool to bootstrap projects for Spec-Driven Development (SDD).";
    homepage = "https://github.com/github/spec-kit";
    license = licenses.mit;
    mainProgram = "specify";
    platforms = platforms.linux ++ platforms.darwin;
  };
}