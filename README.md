# jenkins-nix-ci

WIP: NixOS configuration to run Jenkins and Nix-based build agents via nix-darwin and NixOS 

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

## TODO

- [x] Initial Jenkins config
    - Configuration as code
    - Ngrok
- [ ] Expose a managed library for reuse in `Jenkinsfile`, for  cachix use/push, docker push, etc.
- NixOS module: https://github.com/juspay/jenkins-nix-ci/issues/3
- [ ] Separate build slave for Linux
- [ ] Separate build slave for macOS (nix-darwin)