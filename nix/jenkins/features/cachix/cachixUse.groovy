#!/usr/bin/env groovy

def call(String cacheName) {
    sh label: "Configuring to use cache ${cacheName}.cachix.org",
       script: "cachix use ${cacheName}"
}