{
  description = "External CLI tools for Doom Emacs — formatters, LSP servers, checkers. Installed into the Nix profile with `nix profile install .#default`, which symlinks the binaries into ~/.nix-profile/bin (on PATH). Doom finds them via `executable-find`. After install/upgrade, run `doom env` so GUI Emacs.app picks up the PATH, then restart Emacs.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin"; # Apple Silicon
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.buildEnv {
        name = "doom-tools";
        paths = with pkgs; [
          # ── Search / navigation (Doom core; replacing the Homebrew rg + fd) ──
          ripgrep # rg — projectile, +lookup, vertico search (also used at the shell)
          fd      # file finder — Doom nav; also the fzf backend

          # ── Formatters (:editor format / apheleia) ──
          clang-tools        # clang-format — :lang cc (also provides clangd for `cc +lsp` later)
          prettier           # json / javascript / web / yaml / markdown
          ruff               # python — `ruff format` + import sorting (replaces black + isort)
          shfmt              # sh
          stylua             # lua
          google-java-format # java
          # swift  → Xcode's bundled swift-format (not from nix)
          # clojure/ledger → no standalone formatter (clojure-lsp / cider / ledger-mode)

          # ── LSP servers ──
          typescript-language-server   # ts-ls — :lang javascript / web
          typescript                   # tsserver backend it drives
          pyright                      # :lang python +lsp +pyright
          bash-language-server         # :lang sh +lsp (integrates shellcheck)
          yaml-language-server         # :lang yaml +lsp
          vscode-langservers-extracted # json/html/css/eslint — :lang json/web +lsp
          clojure-lsp                  # :lang clojure +lsp (native binary, no JVM)
          jdt-language-server          # :lang java +lsp (see config.el note re lsp-java)
          lua-language-server          # :lang (lua +lsp)
          marksman                     # :lang (markdown +lsp)
          # clangd — already provided by clang-tools above (:lang cc +lsp)
          # sourcekit-lsp — Xcode toolchain, wired in config.el (:lang swift +lsp)
          # dart — Flutter SDK territory, not nix

          # ── Runtimes (global floor for scratch/exercise trees; projects that
          #    pin their own via devshell + direnv still win per-buffer) ──
          clojure # tools.deps CLI — clojure-lsp classpath lookup; ships its own JDK

          # ── Per-directory environments (zsh hook + Doom's envrc integration) ──
          direnv     # loads/unloads project env on cd; envrc.el shells out to it
          nix-direnv # fast cached `use flake` implementation for direnv
        ];
      };
    };
}
