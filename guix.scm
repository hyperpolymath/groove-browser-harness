;; SPDX-License-Identifier: MPL-2.0
;; (PMPL-1.0-or-later preferred; MPL-2.0 required for browser extension stores)
;; Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
;;
;; Guix development environment for groove-browser-harness.
;; Usage: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (gnu packages node)
             (gnu packages web))

(package
  (name "groove-browser-harness")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (native-inputs
   (list node-lts
         web-ext))
  (synopsis "Groove protocol browser extension harness")
  (description
   "Browser extension harness for the Groove universal plug-and-play
protocol, providing Firefox extension tooling and type-safe
localhost bridge for Groove endpoints.")
  (license #f))
