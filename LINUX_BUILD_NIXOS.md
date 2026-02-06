Note: This document, the `shell.nix`, and `fluffychat.sh` were created by copilot, tasked to create a nix shell that could build this app based on the existing github actions.

# Building Fluffychat on NixOS

This document describes how to build the Fluffychat Flutter Linux application on NixOS and documents a build issue specific to the `handy_window` plugin.

## Quick Start

### Building

```bash
nix-shell shell.nix
flutter pub get
flutter build linux --release
```

### Running

Use the provided launcher script:
```bash
./fluffychat.sh
```

Or manually:
```bash
LD_LIBRARY_PATH=./build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH ./build/linux/x64/release/bundle/fluffychat
```

## Dependencies

The `shell.nix` file provides all necessary dependencies extracted from the GitHub Actions CI configuration. Key dependencies include:

- **Flutter/Dart**: Core framework
- **Rust nightly**: Required for cryptographic libraries (vodozemac)
- **Build tools**: cmake, ninja, pkg-config, clang
- **GTK ecosystem**: gtk3, libhandy, pango, fribidi, sysprof
- **System libraries**: util-linux, openssl, webkitgtk_4_1

## Runtime Library Loading

When running the built binary, it needs to find the bundled shared libraries (`.so` files). This is handled in two ways:

1. **Within nix-shell with `flutter run`**: The `shell.nix` automatically sets `LD_LIBRARY_PATH` to include `build/linux/x64/release/bundle/lib` when the build directory exists.

2. **Outside nix-shell**: Use the `fluffychat.sh` launcher script which sets the same library path:
```bash
./fluffychat.sh
```

If you run the binary directly without setting `LD_LIBRARY_PATH`, you'll get:
```
ERROR: Failed to load dynamic library 'libvodozemac_bindings_dart.so': cannot open shared object file
```

### Note on `flutter run` debug mode

**`flutter run -d linux` (debug mode) does not work on NixOS.** This is due to Flutter's debug engine having hardcoded ELF path references that don't resolve correctly in NixOS's immutable filesystem store.

**Workaround:** Use release mode builds:
```bash
nix-shell shell.nix
flutter build linux --release
./fluffychat.sh
```

The release build works perfectly. The only downside is longer build times compared to debug mode on other systems.

## The handy_window CMakeLists Issue

### Problem

The `handy_window` plugin embeds a copy of libhandy and includes bidirectional text support via `fribidi.h`. However, the embedded CMakeLists.txt only declares a dependency on `gtk+-3.0` and does not explicitly link against `fribidi` or `pango`.

This causes a compilation error:
```
/path/to/handy-bidi.c:29:10: fatal error: 'fribidi.h' file not found
```

### Root Cause

While `gtk+-3.0` transitively depends on `pango`, which in turn depends on `fribidi`, the pkg-config configuration files and include paths are not automatically propagated to the embedded libhandy library being compiled.

The issue occurs at:
```
linux/flutter/ephemeral/.plugin_symlinks/handy_window/linux/libhandy/CMakeLists.txt
```

### Solution

The `shell.nix` includes an automated patch that adds explicit `fribidi` and `pango` dependencies to the handy_window CMakeLists.txt:

**Before:**
```cmake
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
target_link_libraries(handy PRIVATE PkgConfig::GTK)
```

**After:**
```cmake
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(PANGO REQUIRED IMPORTED_TARGET pango)
pkg_check_modules(FRIBIDI REQUIRED IMPORTED_TARGET fribidi)
target_link_libraries(handy PRIVATE PkgConfig::GTK PkgConfig::PANGO PkgConfig::FRIBIDI)
```

This ensures that:
1. The fribidi headers are found during compilation
2. The pango and fribidi libraries are linked correctly
3. All transitive dependencies are resolved

### Automatic Patching

The `shell.nix` shellHook automatically applies this patch when you enter the nix-shell. The patch:
- Only applies if the handy_window plugin symlinks exist
- Checks if already applied to avoid duplicate patches
- Prints a confirmation message when applied

## Cross-Distribution Notes

This issue may affect other distributions as well if:
- pkg-config paths are not properly configured
- Development headers for fribidi are not installed
- CMake cannot find transitive dependencies

The fix should be portable across distributions that use pkg-config.

## Contributing Upstream

This issue should ideally be fixed upstream in the handy_window plugin. Consider opening a PR to add explicit fribidi and pango dependencies to the embedded libhandy CMakeLists.txt.

## Related Files

- `shell.nix` - NixOS development environment with automated patching
- `linux/CMakeLists.txt` - Root CMake configuration
- `linux/flutter/generated_plugins.cmake` - Generated plugin list
- `.github/workflows/release.yaml` - GitHub Actions build configuration (reference for dependencies)

## Troubleshooting

### `flutter run` fails with "FlutterEngineCreateAOTData" error

This is a known issue on NixOS. The Flutter debug engine has hardcoded ELF path references that don't work in NixOS's immutable filesystem. 

**Solution:** Use `flutter build linux --release` instead and run the compiled binary with `./fluffychat.sh`. Release builds work perfectly on NixOS.

### Build still fails with fribidi errors

Ensure you've exited any previous nix-shell sessions and re-entered with `nix-shell shell.nix`. The patch runs on shell entry.

### Plugin symlinks not found

Run `flutter pub get` first to generate the plugin symlinks before running `flutter build linux`.

### pkg-config warnings about sysprof-capture-4

This is a harmless warning from glib's optional sysprof dependency. The build proceeds successfully despite these warnings.
