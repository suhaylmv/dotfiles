// Bar, wallpaper, dashboard panel, notification popups, volume/brightness OSD,
// launcher, clipboard history, keybind cheat sheet.
//   qs ipc call panel toggle | open | close | toggleDnd
//   qs ipc call theme reload
//   qs ipc call osd brightness | volume
//   qs ipc call launcher toggle | power | close
//   qs ipc call wallpaper reload
//   qs ipc call clipboard toggle | close
//   qs ipc call keybinds toggle | close
import Quickshell

ShellRoot {
    Background {}
    Bar {}
    Panel {}
    Popups {}
    Osd {}
    LauncherWindow {}
    ClipboardWindow {}
    KeybindsWindow {}
}
