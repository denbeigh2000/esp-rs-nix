# esp-rs-nix

This packages the pre-built rust targets from
[`esp-rs/rust-build`](https://github.com/esp-rs/rust-build) with Nix, in a
format compatible with the [`fenix`](https://github.com/nix-community/fenix)
toolchain packaging system.

It can be used in a flake like this:

```nix
{
    inputs = {
        ...
        esp-rs-nix.url = "github:denbeigh2000/esp-rs-nix";
        ...
    };

    outputs = { nixpkgs, esp-rs-nix, ... }: {
        ...
        # `toolchain` can be used as a shell package
        toolchain = import esp-rs-nix { inherit system; }."rust-esp-v1.82.0.3";
        ...
        shell = {
            packages = [ toolchain ];
        };

    };
}
```
<!--
Untested, but maybe projects can be built with crane/naersk?
-->

## Thanks

Thanks to [`fenix`](https://github.com/nix-community/fenix) for the tooling and
[@ar3s3ru](https://github.com/ar3s3ru) for [sharing detailed prior art](https://github.com/nix-community/fenix/issues/58#issuecomment-2156056797)
