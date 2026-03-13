{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter
    
    # Rust toolchain (needed for encryption/cryptographic dependencies)
    rustup
    
    # Build tools
    cmake
    ninja
    pkg-config
    clang
    
    # GTK 3 and related development files
    gtk3
    libhandy
    pango
    util-linux
    xz
    jsoncpp
    libsecret
    openssl
    webkitgtk_4_1
    sysprof
    libsysprof-capture
    pcre2
    libselinux
    libsepol
    libgcrypt
    libthai
    libdatrie
    libxdmcp
    libgpg-error
    libdeflate
    lerc
    libwebp
    libxkbcommon
    libepoxy
    libxtst
    sqlite
    fribidi
    glib
    
    # Git (for Flutter to clone dependencies)
    git
    
    # Other utilities
    curl
    wget
    jq
    
    # Development tools
    gcc
    gnumake
  ];
  
  shellHook = ''
    # Set up Rust environment for nightly toolchain
    export RUSTUP_HOME="''${PWD}/.rustup"
    export CARGO_HOME="''${PWD}/.cargo"
    
    # Set up pkg-config path for all dependencies
    export PKG_CONFIG_PATH="${pkgs.gtk3.dev}/lib/pkgconfig:${pkgs.libhandy.dev}/lib/pkgconfig:${pkgs.pango.dev}/lib/pkgconfig:${pkgs.sysprof}/lib/pkgconfig:${pkgs.fribidi}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    # Set CMAKE_PREFIX_PATH to help cmake find packages
    export CMAKE_PREFIX_PATH="${pkgs.gtk3.dev}:${pkgs.libhandy.dev}:${pkgs.pango.dev}:${pkgs.fribidi}:$CMAKE_PREFIX_PATH"
    
    # Set up LD_LIBRARY_PATH to include built libraries for flutter run
    # Support both debug and release builds
    if [ -d "build/linux/x64/debug/bundle/lib" ]; then
      export LD_LIBRARY_PATH="''${PWD}/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
    fi
    if [ -d "build/linux/x64/release/bundle/lib" ]; then
      export LD_LIBRARY_PATH="''${PWD}/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"
    fi
    
    # Ensure the nightly rust-src component is available
    rustup toolchain install nightly
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
    
    # Patch handy_window CMakeLists to include fribidi and pango dependencies
    patch_handy_window_cmake() {
      local cmake_file="linux/flutter/ephemeral/.plugin_symlinks/handy_window/linux/libhandy/CMakeLists.txt"
      if [ -f "$cmake_file" ]; then
        # Check if patch is already applied
        if ! grep -q "pkg_check_modules(FRIBIDI" "$cmake_file"; then
          # Apply the patch
          sed -i 's/pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)$/pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)\npkg_check_modules(PANGO REQUIRED IMPORTED_TARGET pango)\npkg_check_modules(FRIBIDI REQUIRED IMPORTED_TARGET fribidi)/' "$cmake_file"
          sed -i 's/target_link_libraries(handy PRIVATE PkgConfig::GTK)$/target_link_libraries(handy PRIVATE PkgConfig::GTK PkgConfig::PANGO PkgConfig::FRIBIDI)/' "$cmake_file"
          echo "✓ Patched handy_window CMakeLists.txt"
        fi
      fi
    }
    
    # Run the patch if dependencies are present
    if [ -d "linux/flutter/ephemeral/.plugin_symlinks" ]; then
      patch_handy_window_cmake
    else
      echo "ℹ Plugin symlinks not found. Run 'flutter pub get' first to generate them."
    fi
    
    echo "Flutter Linux dev environment loaded"
    echo "Run 'flutter pub get' and then 'flutter build linux' to build"
  '';
}


