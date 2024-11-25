{
  description = "Packaging esp-rs/rust-build with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fenix, ... }:
    let

    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        triple = {
          aarch64-darwin = "aarch64-apple-darwin";
          x86_64-darwin = "x86_64-apple-darwin";
          x86_64-linux = "x86_64-unknown-linux-gnu";
          aarch64-linux = "aarch64-unknown-linux-gnu";
        }.${system};

        # NOTE: we need to ensure this is from a matching rust version
        mkToolchain = pkgs.callPackage "${fenix}/lib/mk-toolchain.nix" { };

        rustVersions =
          let
            inherit (pkgs.lib)
              filterAttrs hasSuffix mapAttrs';

            isDataFile = name: f:
              hasSuffix ".json" name && f == "regular";

            processFile =
              (name: _:
                let
                  inherit (builtins) fromJSON readFile;
                  inherit (pkgs.lib) nameValuePair removeSuffix;
                  version = removeSuffix ".json" name;

                  data = builtins.fromJSON (readFile ./data/${name});
                  toolchain = (mkToolchain "-esp" data.${triple}.latest);
                in
                nameValuePair
                  "rust-esp-${version}"
                  toolchain.toolchain
              );

            dataVersionFiles =
              (filterAttrs
                isDataFile
                (builtins.readDir "${./data}"));
          in
          mapAttrs' processFile dataVersionFiles;
      in
      {
        packages = rustVersions;
      });
}

