{
  description = "extra outputs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mini-dev-shell = {
      url = "github:n-hass/mini-dev-shell";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mini-dev-shell,
    }:
    mini-dev-shell.mkMiniDevShell (
      system: pkgs:
      let
        lib = pkgs.lib;
        baseDevShell = {
          packages = with pkgs; [
            jdk21
            gradle

            rustc
            cargo
            cargo-nextest
          ];

          env = {
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
            NATS_TMO_SECONDS = 10;
          };
        };
      in
      (
        baseDevShell
        // {
          packages =
            with pkgs;
            baseDevShell.packages
            ++ [
              rustfmt
              rust-analyzer
              clippy

              natscli
              nats-server
              tmux
            ];

          returnToUserShell = true;

          extraFlakeOutputs = {
            devShells = {
              check = pkgs.mkMiniDevShell (
                baseDevShell
                // {
                  packages =
                    with pkgs;
                    baseDevShell.packages
                    ++ [
                      sccache
                    ];

                  env =
                    baseDevShell.env
                    // {
                      SCCACHE_DIR = "/tmp/sccache-build-cache";
                      RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
                    }
                    // lib.optionalAttrs pkgs.stdenv.isLinux {
                      PKG_CONFIG_PATH = "${pkgs.libudev-zero}/lib/pkgconfig";
                    };

                  shellHook = ''
                    mkdir -p /tmp/sccache-build-cache
                    gradle clean check --parallel
                    RT=$?
                    sccache -s
                    exit $RT
                  '';
                }
              );
            };

            apps.nats-server = {
              type = "app";
              program = "${pkgs.writeShellScript "nats-dev-server" ''
                # Check if tmux session already exists
                if tmux has-session -t nats-server 2>/dev/null; then
                  # Optionally attach to the tmux session
                  read -p "Attach to NATS server tmux session? (y/n): " choice
                  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                    tmux attach-session -t nats-server
                  fi
                  exit 0
                elif lsof -i -P -n | grep -q -e "nats-serv .*:4222"; then
                  # Orphaned server, kill it
                  nats-server -sl quit
                fi

                STATUS_FILE="$(mktemp /tmp/nats-server-status.XXXXXX)"

                if tmux new-session -d -s nats-server "nats-server"; then
                  echo "NATS server started successfully"
                fi
              ''}";
            };
          };
        }
      )
    );
}
