#!/usr/bin/env groovy

def call() {
    def s = sh script: "flake-outputs --json", returnStdout: true
    def outs = readJSON text: s
    echo "Flake outputs to build:\n${s}"
    outs.each{out ->
      // stage ("Nix Build: ${outs[i]}") {
        sh label: "Nix Build: ${out}",
           script: "nix build .#${out}"
      // }
    }
}
