#!/usr/bin/env groovy

def call(Map args = [:]) {
    system = args["system"] ?: null
    systemStr = (system == null) ? "default" : system
    stage ("Nix Build All (${systemStr})") {
      nixArgs = (system == null) ? "" : "--option system ${system}"
      flakeOutputs = sh script: "nix-build-all ${nixArgs}",
         returnStdout: true
      echo flakeOutputs
      env.FLAKE_OUTPUTS = flakeOutputs.trim()
    }
}
