
# nammayatri Jenkins CI

## Deploying

```sh
nix run . -- -s --remote-build
```

(The `deploy` command is also available in the devshell)

## Local build

```sh
nix build .#nixosConfigurations.jenkins-nix-ci.config.system.build.toplevel
```