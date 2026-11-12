pragma Singleton
import QtQuick
import Quickshell

// Nerd Font glyphs by name (look them up on nerdfonts.com/cheat-sheet).
// Written as code points so the source stays readable.
Singleton {
    readonly property string bell:          String.fromCodePoint(0xF009A) // nf-md-bell
    readonly property string bellOff:       String.fromCodePoint(0xF009B) // nf-md-bell_off
    readonly property string bluetooth:     String.fromCodePoint(0xF00AF) // nf-md-bluetooth
    readonly property string bluetoothOff:  String.fromCodePoint(0xF00B2) // nf-md-bluetooth_off
    readonly property string night:         String.fromCodePoint(0xF0594) // nf-md-weather_night
    readonly property string wallpaper:     String.fromCodePoint(0xF0E09) // nf-md-image_area
    readonly property string power:         String.fromCodePoint(0xF0425) // nf-md-power
    readonly property string brightness:    String.fromCodePoint(0xF00DF) // nf-md-brightness_6
    readonly property string volume:        String.fromCodePoint(0xF057E) // nf-md-volume_high
    readonly property string volumeOff:     String.fromCodePoint(0xF075F) // nf-md-volume_off
    readonly property string previous:      String.fromCodePoint(0xF04AE) // nf-md-skip_previous
    readonly property string next:          String.fromCodePoint(0xF04AD) // nf-md-skip_next
    readonly property string play:          String.fromCodePoint(0xF040A) // nf-md-play
    readonly property string pause:         String.fromCodePoint(0xF03E4) // nf-md-pause
    readonly property string music:         String.fromCodePoint(0xF075A) // nf-md-music_note
    readonly property string close:         String.fromCodePoint(0xF0156) // nf-md-close
    readonly property string bellCheck:     String.fromCodePoint(0xF11E5) // nf-md-bell_check_outline
    readonly property string lock:          String.fromCodePoint(0xF033E) // nf-md-lock
    readonly property string reboot:        String.fromCodePoint(0xF0709) // nf-md-restart
    readonly property string themeToggle:   String.fromCodePoint(0xF0508) // nf-md-theme_light_dark
    readonly property string clipboard:     String.fromCodePoint(0xF0147) // nf-md-clipboard_text
    readonly property string search:        String.fromCodePoint(0xF0349) // nf-md-magnify
    readonly property string command:       String.fromCodePoint(0xF0142) // nf-md-chevron_right
    readonly property string app:           String.fromCodePoint(0xF08C6) // nf-md-application
    readonly property string pin:           String.fromCodePoint(0xF0403) // nf-md-pin
    readonly property string image:         String.fromCodePoint(0xF02E9) // nf-md-image

    // ---- bar (same glyphs Waybar used) ----
    readonly property string nix:           String.fromCodePoint(0xF1105) // nf-md-nix
    readonly property string wsEmpty:       String.fromCodePoint(0xF10C)  // nf-fa-circle_o
    readonly property string wsActive:      String.fromCodePoint(0xF111)  // nf-fa-circle
    readonly property string chevronLeft:   String.fromCodePoint(0xF0141) // nf-md-chevron_left
    readonly property string chevronRight:  String.fromCodePoint(0xF0142) // nf-md-chevron_right
    readonly property string check:         String.fromCodePoint(0xF012C) // nf-md-check
    readonly property string ethernet:      String.fromCodePoint(0xF0200) // nf-md-ethernet
    readonly property string wifiOff:       String.fromCodePoint(0xF092E) // nf-md-wifi_strength_off_outline
    // nf-md-wifi_strength_1 .. wifi_strength_4
    readonly property var wifi: [0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => String.fromCodePoint(c))
    readonly property string memory:        String.fromCodePoint(0xF035B) // nf-md-memory
    readonly property string cpu:           String.fromCodePoint(0xF0EE0) // nf-md-cpu_64_bit
    readonly property string charging:      String.fromCodePoint(0xF0084) // nf-md-battery_charging
    // nf-md-battery_outline, battery_10 .. battery_90, battery
    readonly property var battery: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E,
                                    0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079].map(c => String.fromCodePoint(c))
    readonly property string bellBadge:     String.fromCodePoint(0xF116B) // nf-md-bell_badge
}
