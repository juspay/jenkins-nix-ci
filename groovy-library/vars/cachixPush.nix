{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-cachixPush";
  runtimeInputs = [ pkgs.cachix pkgs.jq ];
  # https://docs.cachix.org/pushing
  text = ''
    set -euo pipefail

    CACHE="$1"

    # Push all packages.
    set -x
    nix build --json \
      | jq -r '.[].outputs | to_entries[].value' \
      | cachix push "''${CACHE}"

    # Push devshell.
    # Clear all but $PATH, to prevent secrets leaking to shellHook.
    env -i PATH="$PATH" nix develop --profile dev-profile -c echo
    cachix push "''${CACHE}" dev-profile
    rm dev-profile
  '';
}
