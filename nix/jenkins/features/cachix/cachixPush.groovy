#!/usr/bin/env groovy

def call(String cacheName) {
    withCredentials([string(credentialsId: 'cachix-auth-token', variable: 'CACHIX_AUTH_TOKEN')]) {
        sh label: "Pushing to ${cacheName}.cachix.org",
           script: "cachix push ${cacheName} ${env.FLAKE_OUTPUTS}"
    }
}
