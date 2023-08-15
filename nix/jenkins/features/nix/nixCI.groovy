#!/usr/bin/env groovy

def call(Map args = [:]) {
    // Function args are deprecated
    system = args["system"] ?: env.NIX_SYSTEM
    stage ("""NixCI (${system ?: "default"})""") {
      nixArgs = [
        system ? "--system ${system}" : "",
      ]
      flakeOutputs = sh script: """nixci ${nixArgs.join(" ")}""",
         returnStdout: true
      echo flakeOutputs
      env.FLAKE_OUTPUTS = flakeOutputs.trim().replaceAll("\n", " ")
    }
}
