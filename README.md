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
- [ ] Separate build slave for Linux
- [ ] Separate build slave for macOS (nix-darwin)