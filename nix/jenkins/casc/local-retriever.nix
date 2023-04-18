{ pkgs, ... }:

let
  # Jenkins doesn't support a local retriever; so we simulate one by
  # piggybacking on its git scm retriever.
  #
  # `localPath` is local path, typically a nix store path. Internally, a new
  # store path is created as a copy of it but with a git index, so Jenkins' git
  # scm retriever can access it.
  localRetriever = name: localPath:
    let
      pathInGit = path: pkgs.runCommand name
        {
          buildInputs = [ pkgs.git ];
        }
        ''
          mkdir -p $out
          cp -r ${path}/* $out
          cd $out
          git init
          git add .
          git config user.email "nobody@localhost"
          git config user.name "nix"
          git commit -m "Added by pkgs.runCommand (for localRetriever)"
        '';
    in
    {
      legacySCM.scm.git.userRemoteConfigs = [{
        url = builtins.toString (pathInGit localPath);
      }];
    };
in
localRetriever
