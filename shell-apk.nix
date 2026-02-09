{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter
    
    # Java (required for Android build - version 17 recommended)
    jdk17
    
    # Rust toolchain (needed for encryption/cryptographic dependencies)
    rustup
    
    # Android development tools
    android-tools
    
    # Build tools
    cmake
    ninja
    pkg-config
    clang
    
    # System libraries needed by Android NDK toolchain
    zlib
    
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
    # Set up Rust environment
    export RUSTUP_HOME="''${PWD}/.rustup"
    export CARGO_HOME="''${PWD}/.cargo"
    
    # Set up LD_LIBRARY_PATH for Android NDK toolchain dependencies
    export LD_LIBRARY_PATH="${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
    
    # Configure Flutter to use the system (writable) Android SDK
    if [ -w "$HOME/Android/Sdk" ]; then
      flutter config --android-sdk "$HOME/Android/Sdk" &> /dev/null
    else
      # Fallback: use a local build directory
      mkdir -p "''${PWD}/.android-sdk"
      flutter config --android-sdk "''${PWD}/.android-sdk" &> /dev/null
    fi
  
    
    # Ensure the nightly rust-src component is available
    rustup toolchain install nightly
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
    
    echo "Flutter Android APK dev environment loaded"
    echo "Run 'flutter pub get' and then 'flutter build apk --no-tree-shake-icons' to build"
  '';
}
