{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-cachixPush";
  runtimeInputs = [ 
    pkgs.jq 
    pkgs.cachix
    pkgs.devour-flake-cat
  ];
  # https://docs.cachix.org/pushing
  text = ''
    set -euo pipefail

    CACHE="$1"

    set -x
    devour-flake-cat . | cachix push "''${CACHE}" 
  '';
}
