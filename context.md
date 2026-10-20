# AIOTweaks — Project Context (`context.md`)

## Overview
**AIOTweaks** (`com.iiemb.aiotweaks`) is a personal All-In-One iOS jailbreak tweak project targeting modern **Rootless** (`iphoneos-arm64`) and **Roothide / Dopamine-roothide** (`iphoneos-arm64e`) jailbreaks on iOS 15.0+.

## Target Environment
- **Supported Jailbreaks**:
  - **Rootless** (`iphoneos-arm64`): Dopamine, palera1n rootless (`/var/jb` prefix).
  - **Roothide** (`iphoneos-arm64e`): Dopamine-roothide (`.jbroot` relative staging with `@loader_path/.jbroot/...` rpaths).
  - *Note*: Legacy rootful (`iphoneos-arm`) is intentionally excluded.
- **Architectures**: `arm64` and `arm64e` (PAC-enabled devices).
- **Minimum iOS Deployment Target**: iOS `15.0` (compiled against latest Xcode `iPhoneOS.sdk`).
- **Hooking Library**: `CydiaSubstrate` / `ElleKit` (`mobilesubstrate`).

## Repository Structure
```text
~/PROJECTS/AIOTweaks/
├── Makefile          # Theos build configuration (rootless + automatic roothide packaging)
├── control           # Debian package metadata (com.iiemb.aiotweaks)
├── AIOTweaks.plist   # MobileSubstrate/ElleKit injection filter
├── Tweak.x           # Core Logos entry point & shared hooks
├── Tweaks/           # (Optional) Modular Logos (.x/.xm) files auto-compiled by Makefile
├── packages/         # Output directory for built .deb packages
├── context.md        # Project architecture, target environment, and feature inventory
└── agents.md         # Instructions and conventions for AI coding agents
```

## Implemented Features
1. **Home Screen Clean Labels & Dots (`Tweak.x`)**:
   - Hides all Home Screen and Dock app icon labels (`SBIconView`).
   - Hides all closed and open folder title labels (`SBIconView`, `SBFolderTitleTextField`).
   - Removes all icon label accessory dots, including:
     - **TestFlight / Beta** indicator dot (`SBApplication`, `SBApplicationIcon`, `SBIconView`).
     - **Recently Updated** blue dot and cloud/offload accessories (`SBIconLabelImageParametersBuilder`, `SBIconLabelImageParameters`).
2. **Lock Screen Clean Controls & Swipe Lock (`Tweaks/LockScreen.x`)**:
   - Removes the Lock Screen **Flashlight** and **Camera** quick action buttons (`CSQuickActionsViewController`, `SBDashBoardQuickActionsViewController`, `CSQuickActionsView`, `CSQuickActionControlView`).
   - Disables **Today View** (swipe right on Lock Screen) and **Camera** (swipe left on Lock Screen) (`CSCoverSheetViewController`, `SBDashBoardPolicyBasedBehaviorProvider`, `SBMainDisplayPolicyAggregator`, `SBDashBoardViewController`).
   - Disables Lock Screen camera pre-warming (`SBCameraPrewarmManager`) when touching the right edge.
3. **Transparent Dock, Folders (Open/Closed), and Global Home Bar (`Tweaks/Transparency.x`)**:
   - **Transparent Dock**: Hides the Home Screen and Floating Dock background blur/platter (`SBDockView`, `SBFloatingDockPlatterView`).
   - **Transparent Folders (Closed & Open)**: Hides the closed folder icon background platter (`SBFolderIconImageView`) and the open folder inner square platter (`SBFolderBackgroundView`, `SBFloatyFolderView`), while preserving the outer Home Screen wallpaper blur when a folder is opened.
   - **Transparent Home Bar Across All Apps**: Hides the bottom Home Indicator pill (`MTLumaDodgePillView`, `SBFHomeGrabberView`, `SBHomeGrabberView`) across `SpringBoard` and all `UIKit` apps while preserving all swipe gestures.

## Build Output
Running `make package FINALPACKAGE=1` produces two `.deb` archives in `packages/`:
- `com.iiemb.aiotweaks_<version>_iphoneos-arm64.deb` (Rootless `/var/jb`)
- `com.iiemb.aiotweaks_<version>_iphoneos-arm64e.deb` (Roothide relative `/` with `@loader_path/.jbroot` `LC_RPATH`)
