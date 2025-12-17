{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
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
    webkitgtk_6_0
    libsoup_3
    gobject-introspection

    # Rust toolchain
    (rust-bin.selectLatestNightlyWith (t:
      t.default.override {
        extensions = [ "rustfmt" "clippy" "rust-src" ];
      }
    ))

    # Golang toolchain
    gotools
    go-tools
    gopls
    delve  # debugger
    buf

    # Node.js
    nodejs_20
    bun

    # Python
    python3

    # CLI development tools
    meld       # Diff / merge
    wget
    alejandra  # Nix file formatting
    cachix     # Nix caching
    inotify-tools  # File watching
    process-compose # Run multiple processes at once

    # Specialized tools
    arduino
    typst
    kubectl
    k9s
    aiken
  ];
}
