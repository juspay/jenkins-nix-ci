#!/usr/bin/env groovy

def call() {
    stage ("Nix Build All") {
      sh '''
        # Make sure that flake.lock is sync
        nix flake lock --no-update-lock-file

        # Do a full nix build (all outputs)
        # This uses https://github.com/srid/devour-flake
        devour-flake .
        '''
    }
}
