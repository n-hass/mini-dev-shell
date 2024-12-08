# Purpose

- Provide an opinionated way to define devShells for a project
- To cut down on the boilerplate needed to do the above

# Usage
You should always override the `nixpkgs` input to what *your* project is using. IE:

```nix
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mini-dev-shell = {
      url = "github:n-hass/mini-dev-shell";
      inputs.nixpkgs.follows = "nixpkgs"; # set the 'follows' 
    };
  };
```

Use `mini-dev-shell.mkMiniDevShell` in the top level flake output as:

```nix
mini-dev-shell.mkMiniDevShell (system: pkgs: {
  packages = with pkgs [
    ...
  ];
})
```

this will generate a devShell for each system.

Specify `extraFlakeOutputs` to add extra things to the flake output, like apps. 
Note that the attributes you provide are recursiveUpdated inside a `flake-utils.lib.eachDefaultSystem` with the automatically generated `devShell.default` output.

# Features

- Injectable `pkgs`
  - `pkgs` is provided in the mkMiniDevShell function, but it supports being overwritten. The modified `pkgs` will be used as the `pkgs.mkMinimalShell` (so you must also provide this!)
- Available as an overlay
  - If you you just want the features of mkMiniDevShell without it generating your whole flake, you can add the `mini-dev-shell.overlay` output to your `nixpkgs` import overlay list.
- Available as a lib fuction
  - Same deal as above - if you're too restricted, you can use `mini-dev-shell.lib.mkCustomShell` and pass `mkShell: args: pkgs:`.