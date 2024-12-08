# Purpose

- Provide an opinionated way to define devShells for a project
- To cut down on the boilerplate needed to do the above

# Usage
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