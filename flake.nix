{
  description = "Rayuela K8s — Kubernetes manifests and DB tooling for the Rayuela payroll system";

  # Modeled on ../rayuela/flake.nix. This project has no JVM build; the shell
  # exists primarily to provide harlequin (PostgreSQL TUI) and the kubectl /
  # kubeseal / kustomize / pass tooling used by scripts/ and justfile.

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    allSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forEachSystem = systems: f:
      nixpkgs.lib.genAttrs systems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
          inherit system;
        });
  in {
    # ─────────────────────────────────────────────────────────────────
    # Development Shell
    # ─────────────────────────────────────────────────────────────────
    devShells = forEachSystem allSystems ({pkgs, ...}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # ── Database TUI (the headline reason for this shell) ──────────
          # The nixpkgs `harlequin` package bundles the postgres adapter,
          # which is what scripts/db/ha.sh needs to talk to rayuela-db.
          harlequin

          # ── PostgreSQL client (psql, pg_dump, pg_restore) ──────────────
          # Matches the server version in base/database/statefulset.yaml.
          postgresql_17

          # ── Kubernetes & Sealed Secrets ────────────────────────────────
          kubectl
          kustomize
          kubeseal
          kubernetes-helm

          # ── Credentials (env-{dev,prod}.sh use `pass show ...`) ────────
          pass
          gnupg

          # ── Task runner ────────────────────────────────────────────────
          just

          # ── Shell utilities ────────────────────────────────────────────
          bashInteractive
          coreutils
          gnused
          gnugrep
          gawk
          findutils
          jq
          yq-go
          curl
          git
          ripgrep
          tree
          file
        ];

        shellHook = ''
          echo ""
          echo "  Rayuela K8s dev shell"
          echo "  ─────────────────────"
          echo "    harlequin   PostgreSQL TUI"
          echo "    psql        PostgreSQL client (postgresql_17)"
          echo "    kubectl     Kubernetes CLI"
          echo "    kubeseal    Sealed Secrets CLI"
          echo "    kustomize   Kustomize CLI"
          echo "    just        Task runner"
          echo ""
          echo "  Try:"
          echo "    just                # list recipes"
          echo "    just ha-dev         # launch harlequin against the dev DB"
          echo "    just ha-prod        # launch harlequin against the prod DB"
          echo ""
        '';
      };
    });
  };
}
