# AI Agent Guidelines (`agents.md`)

This document defines the workflow, build rules, and coding conventions for AI agents working on **AIOTweaks**.

## 1. Build & Packaging Rules
- **Rootless & Roothide Only**:
  - Never configure or build for legacy rootful (`iphoneos-arm`).
  - Always keep `THEOS_PACKAGE_SCHEME = rootless` and `ARCHS = arm64 arm64e` in `Makefile`.
  - The `after-package` rule in `Makefile` automatically generates the `iphoneos-arm64e` (roothide) `.deb` alongside Theos's `iphoneos-arm64` (rootless) `.deb`.
- **Building Packages**:
  ```bash
  make clean package FINALPACKAGE=1
  ```
- **Verification**:
  - After adding or modifying hooks, always run a clean build (`make clean package FINALPACKAGE=1`) and verify both `.deb` packages are emitted in `packages/`:
    - `com.iiemb.aiotweaks_<version>_iphoneos-arm64.deb`
    - `com.iiemb.aiotweaks_<version>_iphoneos-arm64e.deb`

## 2. Code Organization & Modularity
- **Entry Point (`Tweak.x`) & Modular Files (`Tweaks/*.x`)**:
  - Small or SpringBoard-specific hooks can live directly in `Tweak.x` or be split into feature-specific `.x` files inside `Tweaks/` (e.g., `Tweaks/NoIconLabels.x`, `Tweaks/StatusBar.x`).
  - The `Makefile` automatically compiles `Tweak.x` and any `Tweaks/*.x` or `Tweaks/*.xm` files.
- **Process Filtering (`AIOTweaks.plist` & `%ctor`)**:
  - If a new feature hooks a process other than `SpringBoard` (e.g., `UIKit` across apps, `Preferences`, or specific third-party bundle IDs):
    1. Update `AIOTweaks.plist` if additional bundle/class filters are needed.
    2. Use Logos `%group` blocks (e.g., `%group SpringBoardHooks`, `%group AppHooks`) and selectively initialize them inside `%ctor` by checking `[[NSBundle mainBundle].bundleIdentifier ...]` or process name so SpringBoard hooks never execute inside unrelated apps or daemons.

## 3. Roothide & Rootless Path Compatibility
- **Avoid Hardcoded `/var/jb` Paths**:
  - Because this tweak runs on both Dopamine Rootless (`/var/jb`) and Dopamine-roothide (`.jbroot-*`), never hardcode `/var/jb/...` in Objective-C/C code.
  - When referencing tweak resources or preferences on disk, use `rootless.h` / `roothide` path resolution helpers (`jbroot(...)`) or store preferences via `NSUserDefaults` (`initWithSuiteName:`).

## 4. Documentation Maintenance
- Whenever a new feature or hook is added to `AIOTweaks`:
  1. Document the feature and hooked classes in `context.md` under **Implemented Features**.
  2. Bump `Version` in `control` if requested by the user.
