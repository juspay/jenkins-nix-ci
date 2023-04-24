{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-cachixPush";
  runtimeInputs = [ 
    pkgs.jq 
    pkgs.cachix
  ];
  # https://docs.cachix.org/pushing
  text = ''
    set -euo pipefail

    CACHE="$1"

    set -x
    nix build github:srid/devour-flake/v1 \
      -L --no-link --print-out-paths \
      --override-input flake . \
      | xargs cat | cachix push "''${CACHE}" 
  '';
}
