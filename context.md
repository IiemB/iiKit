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
├── Tweak.x           # Index overview (all active modules live in Tweaks/*.x)
├── Tweaks/           # Modular Logos (.x) feature files auto-compiled by Makefile
│   ├── HomeScreenLabels.x
│   ├── HomeScreenTodayView.x
│   ├── LockScreen.x
│   ├── Transparency.x
│   ├── DoubleTapSleep.x
│   ├── PhoneKeypad.x
│   ├── AppSwitcher.x
│   └── OLEDKeyboard.x
├── packages/         # Output directory for built .deb packages
├── context.md        # Project architecture, target environment, and feature inventory
└── agents.md         # Instructions and conventions for AI coding agents
```

## Implemented Features
1. **Home Screen Clean Labels & Dots (`Tweaks/HomeScreenLabels.x`)**:
   - Hides all Home Screen and Dock app icon labels (`SBIconView`).
   - Hides all closed and open folder title labels (`SBIconView`, `SBFolderTitleTextField`).
   - Removes all icon label accessory dots, including:
     - **TestFlight / Beta** indicator dot (`SBApplication`, `SBApplicationIcon`, `SBIconView`).
     - **Recently Updated** blue dot and cloud/offload accessories (`SBIconLabelImageParametersBuilder`, `SBIconLabelImageParameters`).
2. **Lock Screen Clean Controls & Swipe Lock (`Tweaks/LockScreen.x`)**:
   - Removes the Lock Screen **Flashlight** and **Camera** quick action buttons (`CSQuickActionsViewController`, `SBDashBoardQuickActionsViewController`, `CSQuickActionsView`, `CSQuickActionControlView`).
   - Disables **Today View** (swipe right on Lock Screen) and **Camera** (swipe left on Lock Screen) (`CSCoverSheetViewController`, `SBDashBoardPolicyBasedBehaviorProvider`, `SBMainDisplayPolicyAggregator`, `SBDashBoardViewController`).
   - Disables Lock Screen camera pre-warming (`SBCameraPrewarmManager`) when touching the right edge.
   - Disables the iOS 16+ **touch-and-hold Lock Screen wallpaper/poster switcher** (`-[CSCoverSheetViewController _setupPosterSwitcherGestureRecognizer]` & `-[CSCoverSheetViewController _handlePosterSwitcherActivation:]`).
3. **Transparent Dock & Global Home Bar (`Tweaks/Transparency.x`)**:
   - **Transparent Dock**: Hides the Home Screen and Floating Dock background blur/platter (`SBDockView`, `SBFloatingDockPlatterView`).
   - **Transparent Home Bar Across All Apps**: Hides the bottom Home Indicator pill (`MTLumaDodgePillView`) across `SpringBoard` and all `UIKit` apps while preserving all swipe gestures.
4. **Double-Tap to Sleep (`Tweaks/DoubleTapSleep.x`)**:
   - Double-tap empty space on the **Home Screen** (`SBIconListView`) or **Lock Screen** (`CSCoverSheetView` / `CSMainPageView`) to immediately lock/sleep the device (`_simulateLockButtonPress` / `SBLockScreenManager`).
   - Automatically ignores double-taps on icons, folders, widgets, notifications, media controls, and buttons.
5. **Silent Phone Keypad (`Tweaks/PhoneKeypad.x`)**:
   - Disables DTMF keypad button tones when dialing in the **Phone** app (`com.apple.mobilephone` / `com.apple.InCallService`) via `PHAbstractDialerViewController`, `DialerController`, `TPDialerSoundController`, `TPPhonePad`, and `TPDialerNumberPad`.
6. **App Switcher Swipe Down to Close All Apps (`Tweaks/AppSwitcher.x`)**:
   - Swiping/pulling down on any app card in the App Switcher (`SBFluidSwitcherItemContainer`) closes all open apps (`SBMainSwitcherViewController` / `SBMainSwitcherControllerCoordinator` / `SBFluidSwitcherViewController`) and triggers haptic feedback (`UIImpactFeedbackGenerator` + `UINotificationFeedbackGenerator`).
7. **OLED Black Keyboard (`Tweaks/OLEDKeyboard.x`)**:
   - Forces dark keyboard rendering (`-[UIKBRenderConfig setLightKeyboard:NO]`) and pure `#000000` OLED black backgrounds on `UIKeyboard` and `UIKeyboardDockView` across all apps (based on `Easy-Z/BARK`).
8. **Disabled Home Screen Today View (`Tweaks/HomeScreenTodayView.x`)**:
   - Removes the Home Screen **Today View** (the leftmost widget page reached by swiping right) (`SBRootFolderController`, `SBRootFolderView`).
   - Handles both the single leading custom view (iOS 15–17) and the indexed leading custom view list introduced in iOS 18 (`leadingCustomViewControllers`).
   - Disables the leading-edge Home Screen overlay/sidebar Today View on iPad and newer iOS versions (`SBHomeScreenOverlayController`).

## Build Output
Running `make package FINALPACKAGE=1` produces two `.deb` archives in `packages/`:
- `com.iiemb.aiotweaks_<version>_iphoneos-arm64.deb` (Rootless `/var/jb`)
- `com.iiemb.aiotweaks_<version>_iphoneos-arm64e.deb` (Roothide relative `/` with `@loader_path/.jbroot` `LC_RPATH`)
