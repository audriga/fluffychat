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
    
    # Generate a permanent signing key for release builds if not already configured
    setup_signing_key() {
      local android_dir="''${PWD}/android"
      local key_properties="$android_dir/key.properties"
      local keystore_path="$android_dir/key.jks"
      
      if [ ! -f "$keystore_path" ]; then
        echo "Generating permanent signing key for release builds..."
        mkdir -p "$android_dir"
        
        keytool -genkey -keyalg RSA -alias key -keysize 4096 \
          -dname "cn=FluffyChat Dev, ou=Development, o=FluffyChat, c=DE" \
          -keypass FLUFFYCHAT -storepass FLUFFYCHAT \
          -validity 10950 -keystore "$keystore_path" -storetype "pkcs12" 2>/dev/null
        
        # Create key.properties in both android/ and repo root for compatibility
        echo "storePassword=FLUFFYCHAT" > "$key_properties"
        echo "keyPassword=FLUFFYCHAT" >> "$key_properties"
        echo "keyAlias=key" >> "$key_properties"
        echo "storeFile=$keystore_path" >> "$key_properties"
        
        echo "storePassword=FLUFFYCHAT" > "''${PWD}/key.properties"
        echo "keyPassword=FLUFFYCHAT" >> "''${PWD}/key.properties"
        echo "keyAlias=key" >> "''${PWD}/key.properties"
        echo "storeFile=$keystore_path" >> "''${PWD}/key.properties"
        
        echo "✓ Signing key generated at $keystore_path"
      fi
    }
    
    setup_signing_key
    
    # Ensure the nightly rust-src component is available
    rustup toolchain install nightly
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
    
    echo "Flutter Android APK dev environment loaded"
    echo "Run 'flutter pub get' and then 'flutter build apk --no-tree-shake-icons' to build"
  '';
}
