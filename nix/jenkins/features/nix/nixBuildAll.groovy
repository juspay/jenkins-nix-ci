#!/usr/bin/env groovy

def call() {
    stage ("Nix Build All") {
      sh "devour-flake ."
    }
}
