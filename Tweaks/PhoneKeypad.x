#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AIOTweaksPrefs.h"

// ============================================================================
// PhoneKeypad.x — AIOTweaks
// Disables DTMF / keypad dialer button tones in the Phone app (MobilePhone)
// ============================================================================

%group MobilePhoneKeypadSilent

// Main Phone app Dialer controller (iOS 15–17+)
%hook PHAbstractDialerViewController

- (void)phonePad:(id)pad playSoundForKey:(int)key {
    // Suppress local DTMF keypad tone playback
}

- (void)phonePad:(id)pad keyDown:(char)key {
    // Allow normal digit entry without local tone if handled separately
    %orig;
}

%end

%hook DialerController

- (void)phonePad:(id)pad playSoundForKey:(int)key {
    // Suppress local DTMF keypad tone playback
}

- (void)_playSoundForKey:(unsigned int)key {
    // Suppress local DTMF keypad tone playback
}

- (BOOL)shouldPlaySoundForKey:(unsigned int)key {
    return NO;
}

%end

// TelephonyUI keypad class used by MobilePhone & InCallService
%hook TPPhonePad

- (void)_playSoundForKey:(unsigned long long)key {
    // Do not play keypad sound
}

- (void)_stopSoundForKey:(unsigned long long)key {
    // No sound playing
}

%end

%hook TPDialerNumberPad

- (void)_playSoundForKey:(unsigned int)key {
    // Do not play keypad sound
}

- (void)playSoundForKey:(unsigned int)key {
    // Do not play keypad sound
}

%end

// TPDialerSoundController manages AudioServices DTMF tones for Phone keypad
%hook TPDialerSoundController

- (void)playSoundForDialerCharacter:(unsigned int)chr {
    // Do not play DTMF sound
}

- (void)stopSoundForDialerCharacter:(unsigned int)chr {
    // Nothing to stop
}

%end

%end // group MobilePhoneKeypadSilent

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (([bundleID isEqualToString:@"com.apple.mobilephone"] ||
             [bundleID isEqualToString:@"com.apple.InCallService"]) &&
            AIOTweaksPrefEnabled(AIOTweaksPrefSilentPhoneKeypad)) {
            %init(MobilePhoneKeypadSilent);
        }
    }
}
