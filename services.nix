{ pkgs, lib, ... }: 

let
  processComposeConfig = cfg: pkgs.writeText "process-compose-config" ''
    ${(lib.generators.toJSON {} ({ version = "0.5"; } // cfg))}
  '';
in {

  mkProcessComposeWrappers = args: if (args.services or null) == null then [] else [
    (pkgs.writeScriptBin "process-compose" ''
      if [ -z "$PC_PORT_NUM" ]; then
        export PC_PORT_NUM=${toString (args.services.port or 9777)}
      fi
      export PC_CONFIG_FILES=${processComposeConfig args.services}

      exec ${pkgs.process-compose}/bin/process-compose "$@"
    '')
    (pkgs.writeScriptBin "pc" "process-compose \"$@\"")
  ];
}