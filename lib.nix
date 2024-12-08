{ ... }:

{
  mkCustomShell =
    mkShell: args: pkgs:
    let
      lib = pkgs.lib;
      shellHookOption = args.returnToUserShell or false;
      returnToUserShellHook =
        let
          execUserShell = ''
            TARGET_SHELL=$(${pkgs.coreutils}/bin/pinky -l $USER | ${pkgs.gawk}/bin/awk '/Shell:/ {print $NF}')
            exec $TARGET_SHELL
          '';
        in
        {
          "" = "";
          "0" = "";
          "1" = ''
            if [ "$DIRENV_IN_ENVRC" = "1" ]; then
              # do nothing, direnv will load a new shell
              :
            elif [ -n "$IN_NIX_SHELL" ]; then
              ${execUserShell}
            else
              echo "Unknown environment loader - use direnv or 'nix develop'"
            fi
          '';
          "force" = execUserShell;
        }
        .${toString shellHookOption};

      generatedArgs = {
        extraUnsetEnv = [
          "returnToUserShell"
        ];

        shellHook = ''
          ${args.shellHook or ""}
          ${returnToUserShellHook}
        '';
      };
    in
    mkShell (lib.recursiveUpdate args generatedArgs);
}
