#!/usr/bin/env sh

set -x
nix flake lock --update-input jenkins-nix-ci
deploy --remote-build -s "$@"
