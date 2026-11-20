#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "../Tweaks/iiKitPrefs.h"

// ============================================================================
// iiKitPrefsListController — Settings page for iiKit
// ============================================================================

@interface iiKitPrefsListController : PSListController
@end

@implementation iiKitPrefsListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"iiKit";
}

- (PSSpecifier *)iikGroupWithTitle:(NSString *)title footer:(NSString *)footer {
    PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:title
                                                       target:self
                                                          set:nil
                                                          get:nil
                                                       detail:nil
                                                         cell:PSGroupCell
                                                         edit:nil];
    if (footer.length > 0) {
        [group setProperty:footer forKey:@"footerText"];
    }
    return group;
}

- (PSSpecifier *)iikSwitchWithTitle:(NSString *)title key:(NSString *)key {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title
                                                            target:self
                                                               set:@selector(setPreferenceValue:specifier:)
                                                               get:@selector(readPreferenceValue:)
                                                            detail:nil
                                                              cell:PSSwitchCell
                                                              edit:nil];
    [specifier setProperty:key forKey:@"key"];
    [specifier setProperty:iiKitPrefsDomain forKey:@"defaults"];
    [specifier setProperty:@YES forKey:@"default"];
    return specifier;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        iiKitMigrateLegacyPrefs();
        NSMutableArray *specifiers = [NSMutableArray array];

        [specifiers addObject:[self iikGroupWithTitle:@"Home Screen" footer:nil]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Hide Icon Labels & Dots" key:iiKitPrefHomeScreenLabels]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Disable Today View Page" key:iiKitPrefHomeScreenTodayView]];

        [specifiers addObject:[self iikGroupWithTitle:@"Lock Screen" footer:nil]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Remove Flashlight & Camera Buttons" key:iiKitPrefLockScreenQuickActions]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Disable Today View & Camera Swipes" key:iiKitPrefLockScreenPageSwipes]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Disable Wallpaper Switcher" key:iiKitPrefLockScreenPosterSwitcher]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Disable Camera Prewarm" key:iiKitPrefLockScreenCameraPrewarm]];

        [specifiers addObject:[self iikGroupWithTitle:@"Appearance" footer:nil]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Transparent Dock" key:iiKitPrefTransparentDock]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Transparent Home Bar" key:iiKitPrefTransparentHomeBar]];
        [specifiers addObject:[self iikSwitchWithTitle:@"OLED Black Keyboard" key:iiKitPrefOLEDKeyboard]];

        [specifiers addObject:[self iikGroupWithTitle:@"Gestures" footer:nil]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Double-Tap to Sleep" key:iiKitPrefDoubleTapSleep]];
        [specifiers addObject:[self iikSwitchWithTitle:@"App Switcher: Swipe Down to Close All" key:iiKitPrefAppSwitcherCloseAll]];

        [specifiers addObject:[self iikGroupWithTitle:@"Phone" footer:nil]];
        [specifiers addObject:[self iikSwitchWithTitle:@"Silent Phone Keypad" key:iiKitPrefSilentPhoneKeypad]];

        [specifiers addObject:[self iikGroupWithTitle:@"Control Center"
                                               footer:@"The \"Open URL\" 1x1 tile opens this URL. Bare hosts such as example.com open over HTTPS. URL changes apply immediately; no respring needed. Leave empty to open this page instead."]];

        PSSpecifier *urlCell = [PSSpecifier preferenceSpecifierNamed:@"Tile URL"
                                                              target:self
                                                                 set:@selector(setPreferenceValue:specifier:)
                                                                 get:@selector(readPreferenceValue:)
                                                              detail:nil
                                                                cell:PSEditTextCell
                                                                edit:nil];
        [urlCell setProperty:iiKitPrefURLLauncher forKey:@"key"];
        [urlCell setProperty:iiKitPrefsDomain forKey:@"defaults"];
        [urlCell setProperty:@"" forKey:@"default"];
        [urlCell setProperty:@"https://example.com" forKey:@"placeholder"];
        [urlCell setProperty:@(UIKeyboardTypeURL) forKey:@"keyboard"];
        [urlCell setProperty:@NO forKey:@"autoCaps"];
        [urlCell setProperty:@NO forKey:@"autoCorrection"];
        [specifiers addObject:urlCell];

        [specifiers addObject:[self iikGroupWithTitle:@"Apply"
                                               footer:@"Changes take effect after a respring. App-level changes (Home Bar, keyboard, keypad) need the app to be relaunched."]];

        PSSpecifier *respring = [PSSpecifier preferenceSpecifierNamed:@"Respring Now"
                                                               target:self
                                                                  set:nil
                                                                  get:nil
                                                               detail:nil
                                                                 cell:PSButtonCell
                                                                 edit:nil];
        respring.buttonAction = @selector(iikRespring);
        [respring setProperty:@YES forKey:@"enabled"];
        [specifiers addObject:respring];

        _specifiers = specifiers;
    }
    return _specifiers;
}

- (void)iikRespring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
                                                                  message:@"Apply iiKit settings?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFSTR("com.iiemb.iikit/respring"), NULL, NULL, true);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
