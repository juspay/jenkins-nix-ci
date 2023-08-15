#!/usr/bin/env groovy

def call(String imagePackageName, String server) {
    system = env.NIX_SYSTEM
    nixArgs = system ? "--option system ${system}" : ""
    withCredentials(
        [
          string(credentialsId: 'docker-user', variable: 'DOCKER_USER'),
          string(credentialsId: 'docker-pass', variable: 'DOCKER_PASS')
        ]) {
        sh label: "Building and pushing .#${imagePackageName} => registry ${server}",
           script: """
            export DOCKER_SERVER=${server}
            jenkins-nix-ci-dockerPush ${imagePackageName} ${nixArgs}
            """
    }
}
