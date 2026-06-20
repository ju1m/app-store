{
  config,
  lib,
  pkgs,
  ...
}:

let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages.overrideScope (
    _: prev: {
      ssl = prev.ssl.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "savonet";
          repo = "ocaml-ssl";
          rev = "a3ec4b6d6883a6a73e59f6756eceb1b7cbf45183";
          hash = "sha256-zXk5cV6lz5q6XX/CVk8ymt/o+J8DCgAqWMULJLPzenk=";
        };
      };

      tls = prev.tls.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "anmonteiro";
          repo = "ocaml-tls";
          rev = "7756b79fd7ecd74bb516a01e054f08ddf031ebf1";
          hash = "sha256-nKAqSI4JHfgAxd+UQrtW/FZIPI7XC0YOycG/j1AZoxU=";
        };
      };
    }
  );
in
{
  pkgs.quic = {
    version = "0-unstable-2026-03-16";
    description = "Implement QUIC/QUIC-TLS/QPACK and HTTP/3 in OCAML.";
    homePage = "https://github.com/anmonteiro/ocaml-quic";
    license = lib.licenses.bsd3;

    source = {
      git = "github:anmonteiro/ocaml-quic/baaa52e72346027332882aa3a5d5affe04e24abc";
      hash = "sha256-7Fn379yEDdGVrg+5QMe7QMqGpq2986r/fs+8SepIYp4=";
    };

    build.ocamlBuilder = {
      enable = true;

      scope = _: ocamlPackages;

      packages = {
        build = [ pkgs.pkg-config ];

        run = [
          ocamlPackages.dune-configurator
          pkgs.openssl
        ];

        dependencies = with ocamlPackages; [
          digestif
          faraday
          hex
          kdf
          mirage-crypto
          psq
          ssl
          tls
          x509
        ];
      };
    };
    phases = {
      check.enable = false;
    };
  };

  pkgs.qpack = {
    description = "QPACK header compression for HTTP/3 in OCaml.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        angstrom
        faraday
        psq
      ];
    };

    phases = {
      check.enable = false;
    };
  };

  pkgs.h3 = {
    description = "HTTP/3 implementation in OCaml.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        angstrom
        faraday
        httpaf

        pkgs.qpack
        pkgs.quic
      ];
    };

    phases = {
      check.enable = true;
    };
  };

  pkgs.quic-lwt = {
    description = "Lwt runtime for the OCaml QUIC implementation.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        hex
        lwt
        gluten

        pkgs.quic
      ];
    };
  };

  pkgs.quic-eio = {
    description = "Eio runtime for the OCaml QUIC implementation.";
    inherit (config.pkgs.quic)
      source
      version
      homePage
      license
      ;

    build.ocamlBuilder = {
      enable = true;
      packages.dependencies = with ocamlPackages; [
        eio
        eio_posix
        gluten-eio
        hex

        pkgs.quic
      ];
    };
  };
}
