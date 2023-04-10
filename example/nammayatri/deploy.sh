#!/usr/bin/env sh

set -x
nix flake lock --update-input jenkins-nix-ci
deploy -s --remote-build
