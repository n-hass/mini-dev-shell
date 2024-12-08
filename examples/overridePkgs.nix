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
      # declaring pkgs here overrides the nixpkgs version used in the flake
      pkgs = import nixpkgs { inherit system; };
      ###

      packages = with pkgs; [
        nodejs_20
        yarn
        python3
      ];
      
      returnToUserShell = true;
    });
}