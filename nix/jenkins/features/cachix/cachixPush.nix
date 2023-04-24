{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-cachixPush";
  runtimeInputs = [ 
    pkgs.jq 
    pkgs.cachix
    pkgs.devour-flake
  ];
  # https://docs.cachix.org/pushing
  text = ''
    set -euo pipefail

    CACHE="$1"

    set -x
    devour-flake . | cachix push "''${CACHE}" 
  '';
}
