#!/usr/bin/env groovy

def call(Map args = [:]) {
    system = args["system"]
    flakeDir = args["flakeDir"] ?: "."
    overrideInputs = args["overrideInputs"] ?: [:]
    stage ("""Nix Build All (${system ?: "default"})""") {
      nixArgs = [
        system ? "--option system ${system}" : "",
        (overrideInputs.collect { k, v -> "--override-input flake/${k} ${v}"}.join(" "))
      ]
      flakeOutputs = sh script: """nix-build-all ${flakeDir} ${nixArgs.join(" ")}""",
         returnStdout: true
      echo flakeOutputs
      env.FLAKE_OUTPUTS = flakeOutputs.trim()
    }
}
