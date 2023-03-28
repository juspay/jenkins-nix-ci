# jenkins-nix-ci

NixOS module to run Jenkins optimized specifically for running projects using Nix.

## Example

See `./example/nammayatri`.

## Plugins

To update the plugins, run `nix-prefetch-jenkins-plugins > nix/jenkins/plugins.nix`

## Secrets

We use sops-nix to manage secrets. Convert your SSH key (ed25519) to age, which sops uses. On macOS & 1Password, it would look like this:

```sh
nix run nixpkgs#ssh-to-age  <<< "$(op read 'op://Personal/id_ed25519/public key')"
nix run nixpkgs#ssh-to-age -- --private-key -i <(op read 'op://Personal/id_ed25519/actual private') > ~/.config/sops/age/keys.txt
# ^ $HOME/Library/Application\ Support/sops/age/keys.txt actually
```

You also want to get the host key (`ssh-keyscan localhost | ssh-to-age`).

Put both these public age keys in `.sops.yaml`.

## Progress

- [x] Initial Jenkins config
    - jenkinsPlugins2nix
    - Configuration as code
    - Ngrok
- [x] Associated Groovy libraries (served from the nix store)
    - cachix push
    - docker push
- [x] NixOS module: https://github.com/juspay/jenkins-nix-ci/issues/3
    - casc creds
    - features system
- [ ] Separate build slave for Linux
- [ ] Separate build slave for macOS (nix-darwin)
