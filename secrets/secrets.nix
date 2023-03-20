let
  keys = builtins.attrValues (import ./keys.nix);
in
# How I rekey on macOS:
  # agenix  -r -i =(op read 'op://Personal/id_rsa/private key')
{
  "ngrok-token.age".publicKeys = keys;
}
