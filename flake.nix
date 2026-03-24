# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for browser extension stores)
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
#
# Nix flake development environment for groove-browser-harness.
# Usage: nix develop
{
  description = "Groove browser extension harness — Firefox extension tooling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js — web-ext requires Node runtime
            nodejs

            # web-ext — Firefox extension development CLI
            nodePackages.web-ext

            # Firefox — for extension testing
            firefox
          ];

          shellHook = ''
            echo "groove-browser-harness dev shell — web-ext + firefox"
          '';
        };
      });
}
