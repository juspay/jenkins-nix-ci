{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "nix-build-all";
  runtimeInputs = [
    pkgs.nix
    pkgs.devour-flake
  ];
  text = ''
    set -x

    # Make sure that flake.lock is sync
    nix flake lock --no-update-lock-file

    # Do a full nix build (all outputs)
    # This uses https://github.com/srid/devour-flake
    devour-flake "$@"
  '';
}
