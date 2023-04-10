{ pkgs, lib, flake-outputs, ... }:

pkgs.writeShellApplication {
  name = "jenkins-nix-ci-nixBuildAll";
  runtimeInputs = [ flake-outputs ];
  text = ''
    set -euo pipefail

    set -x
    for DRV in $(${lib.getExe flake-outputs})
    do
      nix build .#"$DRV"
    done
  '';
}
