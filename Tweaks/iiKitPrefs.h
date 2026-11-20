#import <Foundation/Foundation.h>

// ============================================================================
// iiKitPrefs.h — shared preference keys and accessor
// Preferences are stored in the com.iiemb.iikit domain so the tweak and
// the Settings bundle share them on both rootless and roothide jailbreaks.
// Settings saved by the old AIOTweaks package (com.iiemb.aiotweaks) are still
// honored until they are copied into the new domain.
// ============================================================================

#define iiKitPrefsDomain       @"com.iiemb.iikit"
#define iiKitLegacyPrefsDomain @"com.iiemb.aiotweaks"

#define iiKitPrefHomeScreenLabels         @"HomeScreenLabels"
#define iiKitPrefHomeScreenTodayView      @"HomeScreenTodayView"
#define iiKitPrefLockScreenQuickActions   @"LockScreenQuickActions"
#define iiKitPrefLockScreenPageSwipes     @"LockScreenPageSwipes"
#define iiKitPrefLockScreenPosterSwitcher @"LockScreenPosterSwitcher"
#define iiKitPrefLockScreenCameraPrewarm  @"LockScreenCameraPrewarm"
#define iiKitPrefTransparentDock          @"TransparentDock"
#define iiKitPrefTransparentHomeBar       @"TransparentHomeBar"
#define iiKitPrefDoubleTapSleep           @"DoubleTapSleep"
#define iiKitPrefAppSwitcherCloseAll      @"AppSwitcherCloseAll"
#define iiKitPrefOLEDKeyboard             @"OLEDKeyboard"
#define iiKitPrefSilentPhoneKeypad        @"SilentPhoneKeypad"
#define iiKitPrefURLLauncher              @"URLLauncher"

// Reads a key from the iiKit domain, falling back to the legacy AIOTweaks domain.
static inline id iiKitPrefObject(NSString *key) {
    id value = [[[NSUserDefaults alloc] initWithSuiteName:iiKitPrefsDomain] objectForKey:key];
    if (value) return value;
    return [[[NSUserDefaults alloc] initWithSuiteName:iiKitLegacyPrefsDomain] objectForKey:key];
}

// Missing keys default to YES so existing installs keep the current behavior.
static inline BOOL iiKitPrefEnabled(NSString *key) {
    id value = iiKitPrefObject(key);
    return value ? [value boolValue] : YES;
}

// Copies AIOTweaks settings into the iiKit domain without overwriting newer values.
static inline void iiKitMigrateLegacyPrefs(void) {
    NSDictionary *legacy = [[[NSUserDefaults alloc] initWithSuiteName:iiKitLegacyPrefsDomain] dictionaryRepresentation];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:iiKitPrefsDomain];
    NSArray<NSString *> *keys = @[
        iiKitPrefHomeScreenLabels, iiKitPrefHomeScreenTodayView,
        iiKitPrefLockScreenQuickActions, iiKitPrefLockScreenPageSwipes,
        iiKitPrefLockScreenPosterSwitcher, iiKitPrefLockScreenCameraPrewarm,
        iiKitPrefTransparentDock, iiKitPrefTransparentHomeBar,
        iiKitPrefDoubleTapSleep, iiKitPrefAppSwitcherCloseAll,
        iiKitPrefOLEDKeyboard, iiKitPrefSilentPhoneKeypad, iiKitPrefURLLauncher,
    ];
    for (NSString *key in keys) {
        id value = legacy[key];
        if (value && ![defaults objectForKey:key]) [defaults setObject:value forKey:key];
    }
}
