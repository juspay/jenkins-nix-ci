#!/usr/bin/env groovy

def call() {
    sh label: "Building all Flake outputs",
       script: "jenkins-nix-ci-nixBuildAll"
}
