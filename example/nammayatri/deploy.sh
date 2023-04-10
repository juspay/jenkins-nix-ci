#!/usr/bin/env sh

set -x
nix flake lock --update-input jenkins-nix-ci
# TODO: This should use --remote-build on darwin
deploy -s
