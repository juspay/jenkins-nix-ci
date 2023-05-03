#!/usr/bin/env groovy

def call(Map args = [:]) {
    system = args["system"] ?: null
    systemStr = (system == null) ? "default" : system
    stage ("Nix Build All (${systemStr})") {
      nixArgs = (system == null) ? "" : "--option system ${system}"
      sh """
        # Make sure that flake.lock is sync
        nix flake lock --no-update-lock-file

        # Do a full nix build (all outputs)
        # This uses https://github.com/srid/devour-flake
        devour-flake . ${nixArgs}
        """
    }
}
