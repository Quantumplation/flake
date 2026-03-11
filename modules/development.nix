{ pkgs, lib, ... }: {
  # Docker
  virtualisation.docker.enable = true;
  users.users.pi.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
    # Compilers
    gcc
    clang
    llvmPackages.libclang
    llvmPackages.libcxxClang

    # Linker & build tools
    lld
    binutils
    cmake
    gnumake
    gnum4

    # System libraries
    glib
    openssl
    openssl.dev
    zlib
    zlib.dev
    pkg-config
    stdenv.cc.cc.lib
    webkitgtk_6_0
    libsoup_3
    gobject-introspection

    # Rust toolchain
    (rust-bin.selectLatestNightlyWith (t:
      t.default.override {
        extensions = [ "rustfmt" "clippy" "rust-src" ];
        targets = [ "wasm32-wasip2" "wasm32-unknown-unknown" ];
      }
    ))

    cargo-watch

    # Golang toolchain
    gotools
    go-tools
    gopls
    delve  # debugger
    buf

    # Node.js
    nodejs_22
    bun

    # Python
    python3

    # CLI development tools
    meld       # Diff / merge
    wget
    alejandra  # Nix file formatting
    cachix     # Nix caching
    inotify-tools  # File watching
    just           # Command runner
    process-compose # Run multiple processes at once
    xxd        # Hex dump utility

    # Lean 4
    lean4

    # Specialized tools
    arduino
    typst
    kubectl
    k9s
    aiken

    # Cloud / Infrastructure
    terraform
    google-cloud-sdk

    # Utilities
    ouch  # Compression/decompression
  ];
}
