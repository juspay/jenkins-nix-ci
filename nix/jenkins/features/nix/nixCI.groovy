#!/usr/bin/env groovy

def call(Map args = [:]) {
    system = args["system"]
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
