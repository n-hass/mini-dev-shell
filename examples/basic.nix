{
  description = "my development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mini-dev-shell = {
      url = "github:n-hass/mini-dev-shell";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  outputs =
    { self, mini-dev-shell }:
    mini-dev-shell.mkMiniDevShell (
      system: pkgs: {
        packages = with pkgs; [
          nodejs_20
          yarn
          python3
        ];

        env = {
          PYTHON = "${pkgs.python3}";
        };

        returnToUserShell = true;

        extraFlakeOutputs = {
          apps = {
            testApp = {
              type = "app";
              program = "${pkgs.writeScript "testApp" ''
                #!/bin/sh
                echo "Hello, world!"
              ''}";
            };
          };
        };
      }
    );
}
