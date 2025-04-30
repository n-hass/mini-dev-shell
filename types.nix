{ lib, ... }:

let
  primitive = with lib.types; nullOr (oneOf [ bool int str path ]);
  primitiveAttrs = with lib.types; attrsOf (either primitive (listOf primitive));
  primitiveList = with lib.types; listOf primitive;
in {
  miniShellType = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        A set of packages to be included in the shell.
      '';
    };
    
    buildInputs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        A set of build inputs to be included in the shell.
      '';
    };

    nativeBuildInputs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        A set of native build inputs to be included in the shell.
      '';
    };

    inputsFrom = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        A set of inputs to be included in the shell.
      '';
    };

    returnToUserShell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to return to the user's shell in the resulting environment.
        Good for daily use.
      '';
    };

    shellHook = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        A shell hook to be executed before entering the resulting shell.
      '';
    };

    env = lib.mkOption {
      type = primitiveAttrs;
      default = { };
      description = ''
        A set of environment variables to be set in the shell.
      '';
    };

    keepEnv = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        A set of environment variables to be kept in the resulting shell (not unset'd).
      '';
    };

    extraUnsetEnv = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        A set of environment variables to be unset in the resulting shell.
      '';
    };

    services = {
      port = lib.mkOption {
        type = lib.types.int;
        default = 9777;
        description = ''
          The port to use for the process-compose server.
        '';
      };
      processes = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = ''
          A set of process-compose services to be included in the shell.
        '';
      };
    };
  };

  miniShellOptsType = {
    processCompose = {
      _package = lib.mkOption {
        type = with lib.types; package;
        internal = true;
        default = null;
        description = ''
          The process-compose package used to run services. This must be a derivation.
        '';
      };
      overridePackage = lib.mkOption {
        type = with lib.types; nullOr package;
        default = null;
        description = ''
          The process-compose package overridden by a user.
          If you want to use the default, set this to null.
        '';
      };
    };
    pkgs = lib.mkOption {
      type = with lib.types; nullOr attrs;
      default = null;
      description = ''
        The configured pkgs set to use. This must contain pkgs.mkMinimalShell.
      '';
    };
    mkShell = lib.mkOption {
      type = with lib.types; anything;
      default = null;
      description = ''
        The mkShell function used internally. 
        This is exposed for access and is configured internally by the flakeModule.
      '';
    };
  };
}