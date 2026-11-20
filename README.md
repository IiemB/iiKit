# iiKit

A set of small tweaks for jailbroken iPhones and iPads that clean up and improve iOS, all in one package. You can turn each feature on or off in **Settings → iiKit**.

Supports **rootless** and **roothide** jailbreaks (Dopamine, Dopamine-roothide, palera1n rootless) on **iOS 15 and later**.

## Features

### Home Screen
- **Hide icon labels and dots.** Removes app and folder names, the TestFlight/beta dot, the "recently updated" dot, and the cloud badge on offloaded apps.
- **Disable the Today View page.** Removes the widget page to the left of your first Home Screen page.

### Lock Screen
- **Remove the Flashlight and Camera buttons.**
- **Disable the Today View and Camera swipes.**
- **Disable the wallpaper switcher.** Pressing and holding the Lock Screen no longer opens wallpaper editing.
- **Disable camera prewarm.** Stops the camera from getting ready when you touch the right edge of the screen.

### Appearance
- **Transparent Dock.** Removes the Dock background.
- **Transparent Home Bar.** Hides the home indicator bar on the Home Screen, Lock Screen, App Switcher and in all apps. Swipe gestures still work.
- **OLED black keyboard.** Makes the keyboard pure black in every app.

### Gestures
- **Double-tap to sleep.** Double-tap an empty part of the Home Screen or Lock Screen to lock your device. Taps on icons, widgets, notifications and controls are ignored.
- **Swipe down to close all apps.** In the App Switcher, pull any app card down to close every open app, with haptic feedback.

### Phone
- **Silent keypad.** Turns off the tones the Phone app plays when you tap the keypad.

### Control Center
- **Open URL tile.** A 1×1 Control Center tile that opens any URL you set in Settings → iiKit. It accepts websites and app links like `prefs:`, `shortcuts://` and `mailto:`. If you haven't set a URL, the tile opens the iiKit settings page.

## Requirements

- A rootless or roothide jailbreak on iOS 15 or later
- [ElleKit](https://github.com/evelyneee/ellekit) or another `mobilesubstrate` provider
- PreferenceLoader
- [CCSupport](https://github.com/opa334/CCSupport), for the Control Center tile

Your package manager installs these for you.

## Installation

Add the **IiemB Repo** to Sileo or Zebra and install **iiKit**:

```
https://iiemb.github.io/repo/
```

Or download the `.deb` that matches your jailbreak:

| Jailbreak | Package |
| --- | --- |
| Rootless (Dopamine, palera1n rootless) | `com.iiemb.iikit_<version>_iphoneos-arm64.deb` |
| Roothide (Dopamine-roothide) | `com.iiemb.iikit_<version>_iphoneos-arm64e.deb` |

Rootful jailbreaks are not supported.

## Usage

1. Open **Settings → iiKit**.
2. Turn features on or off. All features are on by default.
3. Tap **Respring Now** to apply your changes. The Control Center URL takes effect right away, without a respring.

To add the Open URL tile, go to **Settings → Control Center** and add **Open URL**.

## Upgrading from AIOTweaks

iiKit used to be called **AIOTweaks**. Installing iiKit removes AIOTweaks automatically and keeps your settings. If you used the Open URL tile, add it again in Control Center settings.

## Building from source

You need [Theos](https://theos.dev) and Xcode.

```bash
git clone https://github.com/IiemB/iiKit.git
cd iiKit
make clean package FINALPACKAGE=1
```

The build puts both the rootless and the roothide `.deb` in `packages/`.

### Publishing to the IiemB Repo

```bash
make publish
```

This builds both packages, copies them and the `depiction/` files (description, changelog, compatibility) into your tweak repo, removes older iiKit packages there, and checks the repo builds. Set the tweak repo's location first:

```bash
cp .env.example .env   # then set TWEAK_REPO (and THEOS if it isn't ~/theos)
```

To go live, run `./build.sh` in the profile project, then commit and push `iiemb.github.io/`.

## Credits

- The OLED keyboard is based on [BARK](https://github.com/Easy-Z/BARK) by Easy-Z.
- The Control Center tile uses [CCSupport](https://github.com/opa334/CCSupport) by opa334.
