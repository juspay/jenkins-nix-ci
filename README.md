# jenkins-nix-ci

**WIP**: NixOS configuration to run Jenkins and Nix-based build agents via nix-darwin and NixOS 

**NOTE**: This repo will not be re-usable until https://github.com/juspay/jenkins-nix-ci/issues/3

## Local development

To build the configuration locally,

```sh
nix build .#nixosConfigurations.jenkins-nix-ci.config.system.build.toplevel
```
## Deployment

```sh
nix run
```

If you are deploying from macOS, run instead:

```sh
nix run . -- -s --remote-build
```

(The `deploy` command is also available in the devshell)

## Tasks

- [x] Initial Jenkins config
    - jenkinsPlugins2nix
    - Configuration as code
    - Ngrok
- [x] Associated Groovy libraries
    - cachix push
    - docker push
- NixOS module: https://github.com/juspay/jenkins-nix-ci/issues/3
- [ ] Separate build slave for Linux
- [ ] Separate build slave for macOS (nix-darwin)