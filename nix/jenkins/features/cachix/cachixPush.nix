{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-cachixPush";
  runtimeInputs = [ pkgs.cachix pkgs.jq ];
  # https://docs.cachix.org/pushing
  text = ''
    set -euo pipefail

    CACHE="$1"

    # Push the .#default package.
    # TODO: We want to push *all* packages.
    # cf. https://github.com/NixOS/nix/issues/7165
    set -x
    nix build --json \
      | jq -r '.[].outputs | to_entries[].value' \
      | cachix push "''${CACHE}"

    # Push devshell.
    # Clear all but $PATH, to prevent secrets leaking to shellHook.
    env -i PATH="$PATH" nix develop --profile dev-profile -c echo
    cachix push "''${CACHE}" dev-profile
    rm -f dev-profile*
  '';
}
