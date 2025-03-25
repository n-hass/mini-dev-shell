{ ... }:

let
  # source: https://github.com/NixOS/nixpkgs/blob/529d4344f514b70b9736f432e974c59ffad9557a/lib/systems/flake-systems.nix
  supportedSystems = [
    # Tier 1
    "x86_64-linux"
    # Tier 2
    "aarch64-linux"
    "x86_64-darwin"
    # Tier 3
    "armv6l-linux"
    "armv7l-linux"
    "i686-linux"
    # "mipsel-linux" is excluded because it is not bootstrapped

    # Other platforms with sufficient support in stdenv which is not formally
    # mandated by their platform tier.
    "aarch64-darwin"
    # "armv5tel-linux" is excluded because it is not bootstrapped
    "powerpc64le-linux"
    "riscv64-linux"
    "x86_64-freebsd"
  ];

  ### From flake-utils
  # Builds a map from <attr>=value to <attr>.<system>=value for each system.
  eachSystem = let 
    # Applies a merge operation accross systems.
    eachSystemOp =
      op: systems: f:
      builtins.foldl' (op f) { } (
        if
          !builtins ? currentSystem || builtins.elem builtins.currentSystem systems
        then
          systems
        else
          # Add the current system if the --impure flag is used.
          systems ++ [ builtins.currentSystem ]
      );
  in eachSystemOp (
    # Merge outputs for each system.
    f: attrs: system:
    let
      ret = f system;
    in
    builtins.foldl' (
      attrs: key:
      attrs
      // {
        ${key} = (attrs.${key} or { }) // {
          ${system} = ret.${key};
        };
      }
    ) attrs (builtins.attrNames ret)
  );
  ###
in {
  forAllSystems = eachSystem supportedSystems; 

  mkCustomShell =
    mkShell: args: pkgs:
    let
      lib = pkgs.lib;
      servicesLib = import ./services.nix { inherit pkgs lib; };
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
        services = null;
        buildInputs = servicesLib.mkProcessComposeWrappers args ++ (args.buildInputs or []); 
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
