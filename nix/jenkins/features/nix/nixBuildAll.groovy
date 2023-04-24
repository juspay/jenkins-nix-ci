#!/usr/bin/env groovy

def call() {
    def s = sh script: "flake-outputs --json", returnStdout: true
    def outs = readJSON text: s
    echo "Flake outputs to build:\n${s}"

    // TODO: Implement parallelization.
    //
    // Multiple invocations can slow things down, if the flake.nix evaluation is
    // slow. Ideally, we should be running the build of each package in parallel.
    outs.each{out ->
      stage ("Nix Build: ${out}") {
        sh script: "nix build -L --no-link --no-update-lock-file --print-out-paths .#${out}"
      }
    }
}
