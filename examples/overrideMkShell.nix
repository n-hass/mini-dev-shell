{
  description = "my development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mini-dev-shell = {
      url = "github:n-hass/mini-dev-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, mini-dev-shell, nixpkgs }:
    mini-dev-shell.mkMiniDevShell (system: pkgs: {
      
      ### 
      pkgs = import nixpkgs { inherit system; } // {
        # mkMiniDevShell calls pkgs.mkMinimalShell from github:/n-hass/mkminimalshell
        # override it here if you prefer to use another shell make derivation (like the default pkgs.mkShell)
        mkMinimalShell = pkgs.mkShell;
      };
      ###

      packages = with pkgs; [
        nodejs_20
        yarn
        python3
      ];
    });
}