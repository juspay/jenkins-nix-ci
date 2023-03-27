{ pkgs, config, ... }:

{
  environment.systemPackages = [ pkgs.ngrok ];

  system.activationScripts = {
    ngrokStartup =
      let
        tmux = "${pkgs.tmux}/bin/tmux";
        ngrokTokenFile = config.sops.secrets."ngrok-tokens/shivaraj".path;
      in
      {
        text = ''
          # Check if the session exists based on exit code
          ${tmux} has-session -t ngrok 2>/dev/null
          # create a new session if the exit code is non-zero
          if [ $? != 0 ]; then
            ${tmux} new -d -s ngrok
            export NGROKTOKEN=`cat ${ngrokTokenFile}`
            ${tmux} send-keys -t ngrok "${pkgs.ngrok}/bin/ngrok authtoken ''${NGROKTOKEN}" Enter
            ${tmux} send-keys -t ngrok "${pkgs.ngrok}/bin/ngrok tcp 22" Enter
          fi
        '';
        deps = [ ];
      };
  };
}
