{ ... }:

# Functions for working with configuration-as-code-plugin syntax.
# https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#additional-variable-substitution
{
  # This is useful when reading secrets decrypted by sops-nix.
  # Never use builtins.readFile, https://github.com/ryantm/agenix#builtinsreadfile-anti-pattern
  readFile = path:
    "$" + "{readFile:" + path + "}";
  # Parse the string secret as JSON, then extract the value for the specified <key>.
  # https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc#json
  json = key: x:
    "$" + "{json:" + key + ":" + x + "}";
}
