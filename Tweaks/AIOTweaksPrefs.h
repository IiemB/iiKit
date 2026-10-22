#import <Foundation/Foundation.h>

// ============================================================================
// AIOTweaksPrefs.h — shared preference keys and accessor
// Preferences are stored in the com.iiemb.aiotweaks domain so the tweak and
// the Settings bundle share them on both rootless and roothide jailbreaks.
// ============================================================================

#define AIOTweaksPrefsDomain @"com.iiemb.aiotweaks"

#define AIOTweaksPrefHomeScreenLabels         @"HomeScreenLabels"
#define AIOTweaksPrefHomeScreenTodayView      @"HomeScreenTodayView"
#define AIOTweaksPrefLockScreenQuickActions   @"LockScreenQuickActions"
#define AIOTweaksPrefLockScreenPageSwipes     @"LockScreenPageSwipes"
#define AIOTweaksPrefLockScreenPosterSwitcher @"LockScreenPosterSwitcher"
#define AIOTweaksPrefLockScreenCameraPrewarm  @"LockScreenCameraPrewarm"
#define AIOTweaksPrefTransparentDock          @"TransparentDock"
#define AIOTweaksPrefTransparentHomeBar       @"TransparentHomeBar"
#define AIOTweaksPrefDoubleTapSleep           @"DoubleTapSleep"
#define AIOTweaksPrefAppSwitcherCloseAll      @"AppSwitcherCloseAll"
#define AIOTweaksPrefOLEDKeyboard             @"OLEDKeyboard"
#define AIOTweaksPrefSilentPhoneKeypad        @"SilentPhoneKeypad"
#define AIOTweaksPrefURLLauncher              @"URLLauncher"

// Missing keys default to YES so existing installs keep the current behavior.
static inline BOOL AIOTweaksPrefEnabled(NSString *key) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:AIOTweaksPrefsDomain];
    id value = [defaults objectForKey:key];
    return value ? [value boolValue] : YES;
}
