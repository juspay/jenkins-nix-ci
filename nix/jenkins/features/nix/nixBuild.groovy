#!/usr/bin/env groovy

def call(String package) {
    sh script: "nix build -L --no-link --no-update-lock-file .#${package}"
}
