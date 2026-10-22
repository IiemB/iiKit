#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "../Tweaks/AIOTweaksPrefs.h"

// ============================================================================
// AIOTweaksPrefsListController — Settings page for AIOTweaks
// ============================================================================

@interface AIOTweaksPrefsListController : PSListController
@end

@implementation AIOTweaksPrefsListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AIOTweaks";
}

- (PSSpecifier *)aioGroupWithTitle:(NSString *)title footer:(NSString *)footer {
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

- (PSSpecifier *)aioSwitchWithTitle:(NSString *)title key:(NSString *)key {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title
                                                            target:self
                                                               set:@selector(setPreferenceValue:specifier:)
                                                               get:@selector(readPreferenceValue:)
                                                            detail:nil
                                                              cell:PSSwitchCell
                                                              edit:nil];
    [specifier setProperty:key forKey:@"key"];
    [specifier setProperty:AIOTweaksPrefsDomain forKey:@"defaults"];
    [specifier setProperty:@YES forKey:@"default"];
    return specifier;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];

        [specifiers addObject:[self aioGroupWithTitle:@"Home Screen" footer:nil]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Hide Icon Labels & Dots" key:AIOTweaksPrefHomeScreenLabels]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Disable Today View Page" key:AIOTweaksPrefHomeScreenTodayView]];

        [specifiers addObject:[self aioGroupWithTitle:@"Lock Screen" footer:nil]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Remove Flashlight & Camera Buttons" key:AIOTweaksPrefLockScreenQuickActions]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Disable Today View & Camera Swipes" key:AIOTweaksPrefLockScreenPageSwipes]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Disable Wallpaper Switcher" key:AIOTweaksPrefLockScreenPosterSwitcher]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Disable Camera Prewarm" key:AIOTweaksPrefLockScreenCameraPrewarm]];

        [specifiers addObject:[self aioGroupWithTitle:@"Appearance" footer:nil]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Transparent Dock" key:AIOTweaksPrefTransparentDock]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Transparent Home Bar" key:AIOTweaksPrefTransparentHomeBar]];
        [specifiers addObject:[self aioSwitchWithTitle:@"OLED Black Keyboard" key:AIOTweaksPrefOLEDKeyboard]];

        [specifiers addObject:[self aioGroupWithTitle:@"Gestures" footer:nil]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Double-Tap to Sleep" key:AIOTweaksPrefDoubleTapSleep]];
        [specifiers addObject:[self aioSwitchWithTitle:@"App Switcher: Swipe Down to Close All" key:AIOTweaksPrefAppSwitcherCloseAll]];

        [specifiers addObject:[self aioGroupWithTitle:@"Phone" footer:nil]];
        [specifiers addObject:[self aioSwitchWithTitle:@"Silent Phone Keypad" key:AIOTweaksPrefSilentPhoneKeypad]];

        [specifiers addObject:[self aioGroupWithTitle:@"Control Center"
                                               footer:@"The \"Open URL\" 1x1 tile opens this URL. Bare hosts such as example.com open over HTTPS. URL changes apply immediately; no respring needed. Leave empty to open this page instead."]];

        PSSpecifier *urlCell = [PSSpecifier preferenceSpecifierNamed:@"Tile URL"
                                                              target:self
                                                                 set:@selector(setPreferenceValue:specifier:)
                                                                 get:@selector(readPreferenceValue:)
                                                              detail:nil
                                                                cell:PSEditTextCell
                                                                edit:nil];
        [urlCell setProperty:AIOTweaksPrefURLLauncher forKey:@"key"];
        [urlCell setProperty:AIOTweaksPrefsDomain forKey:@"defaults"];
        [urlCell setProperty:@"" forKey:@"default"];
        [urlCell setProperty:@"https://example.com" forKey:@"placeholder"];
        [urlCell setProperty:@(UIKeyboardTypeURL) forKey:@"keyboard"];
        [urlCell setProperty:@NO forKey:@"autoCaps"];
        [urlCell setProperty:@NO forKey:@"autoCorrection"];
        [specifiers addObject:urlCell];

        [specifiers addObject:[self aioGroupWithTitle:@"Apply"
                                               footer:@"Changes take effect after a respring. App-level changes (Home Bar, keyboard, keypad) need the app to be relaunched."]];

        PSSpecifier *respring = [PSSpecifier preferenceSpecifierNamed:@"Respring Now"
                                                               target:self
                                                                  set:nil
                                                                  get:nil
                                                               detail:nil
                                                                 cell:PSButtonCell
                                                                 edit:nil];
        respring.buttonAction = @selector(aioRespring);
        [respring setProperty:@YES forKey:@"enabled"];
        [specifiers addObject:respring];

        _specifiers = specifiers;
    }
    return _specifiers;
}

- (void)aioRespring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
                                                                  message:@"Apply AIOTweaks settings?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFSTR("com.iiemb.aiotweaks/respring"), NULL, NULL, true);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
