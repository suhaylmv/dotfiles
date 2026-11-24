-- Wiki: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1.33,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "10")
hl.env("HYPRCURSOR_SIZE", "20")

---------------------
---- PERMISSIONS ----
---------------------

hl.config({
    ecosystem = {
        no_update_news = true,
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Border colors follow the theme: theme/<mode>/hyprland.lua, reached through
-- the "current" link theme-switch repoints. Fallback if the file is missing.
local ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/theme/current/hyprland.lua")
if not ok then theme = { active_border = "rgb(0F1015)", inactive_border = "rgb(0F1015)" } end

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 7,
        float_gaps = 7,

        border_size = 2,
        col = {
            active_border   = theme.active_border,
            inactive_border = theme.inactive_border,
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 16,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

----------------------
---- ANIMATIONS ------
----------------------

hl.curve("pace",      { type = "bezier", points = { {0.46, 1},    {0.29, 0.99} } })
hl.curve("overshot",  { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.1}  } })
hl.curve("md3_decel", { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } })

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 6,  bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 6,  bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 6,  bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,  bezier = "md3_decel" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2,  bezier = "md3_decel", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1,  bezier = "md3_decel", style = "slide" })

-- Scratchpads: a plain fade, no slide. Speed is in 100ms units, so 200ms in
-- and 150ms out, on an ease-out curve (same feel as the Quickshell popups).
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2,   bezier = "md3_decel", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.5, bezier = "md3_decel", style = "fade" })

hl.animation({ leaf = "border",      enabled = true, speed = 12, bezier = "md3_decel" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 50, bezier = "md3_decel", style = "loop" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "smv, ru",
        kb_variant = "colemak",
        kb_model = "",
        kb_options = "grp:win_space_toggle",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },

        repeat_delay = 200,
        repeat_rate = 40,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "hid-1bcf:08a0-mouse",
    accel_profile = "flat",
})

hl.device({
    name = "logitech-g203-lightsync-gaming-mouse-keyboard",
    accel_profile = "flat",
})

-------------------
---- PROGRAMS -----
-------------------

local terminal    = "ghostty"
local fileManager = "nautilus"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("hyprsunset -i")          -- night light backend, starts neutral; Quickshell runs the schedule
    hl.exec_cmd("qs")                     -- Quickshell: bar, wallpaper, panel, notifications, launcher
    hl.exec_cmd("hypridle")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("tana")
    hl.exec_cmd("obsidian")
end)

-- Quickshell's popups (panel, launcher, clipboard, cheat sheet, OSD,
-- notifications) animate themselves (Pop.qml, Popups.qml); Hyprland's
-- layer fade on top would double the fade-in and drag out the close.
hl.layer_rule({
    name = "quickshell-popups-no-anim",
    match = { namespace = "^quickshell-(panel|launcher|clipboard|keybinds|osd|popups)$" },
    no_anim = true,
})

hl.window_rule({
    name = "tana-ws1",
    match = { class = "^(tana)$" },
    workspace = "1 silent",
})

hl.window_rule({
    name = "obsidian-ws2",
    match = { class = "^(obsidian)$" },
    workspace = "2 silent",
})
hl.window_rule({
    name = "nmtui-float",   -- opened by clicking the bar's network icon
    match = { class = "^(com\\.suhaylmv\\.nmtui)$" },
    float = true,
    center = true,
    size = { 900, 600 },
})
hl.window_rule({
    name = "wifi-float",    -- right-click on the bar's network icon (nmtui connect)
    match = { class = "^(com\\.suhaylmv\\.wifi)$" },
    float = true,
    center = true,
    size = { 640, 480 },
})
hl.window_rule({
    name = "bluetui-float", -- Bluetooth tile in the dashboard panel (right-click)
    match = { class = "^(com\\.suhaylmv\\.bluetui)$" },
    float = true,
    center = true,
    size = { 760, 520 },
})
hl.window_rule({
    name = "mpv-float",
    match = { class = "^(mpv)$" },
    float = true,
    center = true,
    size = {
        "max(window_w, 1200)",
        "window_h * max(window_w, 1200) / window_w",
    },
    keep_aspect_ratio = true,
})
hl.window_rule({
    name = "qbittorrent-dialogs-float",
    match = {
        class = "^(org\\.qbittorrent\\.qBittorrent)$",
        -- anything whose initial title doesn't contain "qBittorrent v" = every dialog, not the main window
        initial_title = "negative:.*qBittorrent v.*",
    },
    float = true,
    center = true,
})

--------------------
---- LID SWITCH ----
--------------------
-- The wiki warns against binding dpms directly; wrap it in a one-shot timer.

hl.bind("switch:on:Lid Switch", function()
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "off" }))
    end, { timeout = 500, type = "oneshot" })
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "on" }))
    end, { timeout = 500, type = "oneshot" })
end, { locked = true })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Descriptions feed the keybind cheat sheet (SUPER+?, Quickshell's
-- Keybinds.qml): "Section: what it does". Binds with the same description
-- show as one row (SUPER + h j k l). Binds without one aren't listed.

-- APPS
hl.bind("CTRL + SPACE", hl.dsp.exec_cmd("timeout 1 qs ipc call launcher toggle"), { description = "Apps: Launcher" })   -- Quickshell launcher
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(terminal), { description = "Apps: Terminal" })   -- SUPER+T is the terminal scratchpad
-- Dark / light theme has no bind: ">theme" in the launcher (or theme-switch)
hl.bind(mainMod .. " + asciitilde", hl.dsp.exec_cmd("timeout 1 qs ipc call launcher wallpaper"), { description = "Apps: Wallpaper" })   -- wallpaper carousel (the launcher's >wall)
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd("timeout 1 qs ipc call keybinds toggle"), { description = "Apps: Keybinds (this list)" })   -- SUPER+? : Quickshell cheat sheet
-- Power tiles: Lock / Reboot / Power off, Lock preselected (SUPER+M, Enter
-- locks). If Quickshell isn't running, lock directly; pidof stops a second
-- hyprlock from stacking.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("timeout 1 qs ipc call launcher power || pidof hyprlock || hyprlock"), { description = "Apps: Power menu" })

-- SCREENSHOTS: saved to ~/Pictures/Screenshots and copied to the clipboard.
-- --freeze pauses the screen while you select; Esc cancels.
local shots = "~/Pictures/Screenshots"
local shot_name = shots .. "/$(date +%Y-%m-%d_%H-%M-%S).png"
local function grab(target)
    return "mkdir -p " .. shots .. " && grimblast --freeze --notify copysave " .. target .. " " .. shot_name
end
hl.bind("Print",                         hl.dsp.exec_cmd(grab("area")), { description = "Screenshots: Region or window" })    -- drag a region or click a window
hl.bind(mainMod .. " + V",               hl.dsp.exec_cmd(grab("area")), { description = "Screenshots: Region or window" })    -- same, for keyboards without Print
hl.bind("SHIFT + Print",                 hl.dsp.exec_cmd(grab("output")), { description = "Screenshots: Whole screen" })  -- whole screen
hl.bind(mainMod .. " + SHIFT + V",       hl.dsp.exec_cmd(grab("output")), { description = "Screenshots: Whole screen" })  -- same, without Print
hl.bind(mainMod .. " + Print",           hl.dsp.exec_cmd(                  -- region, then annotate in satty
    "mkdir -p " .. shots .. " && grimblast --freeze save area - | satty --filename - " ..
    "--output-filename " .. shots .. "/%Y-%m-%d_%H-%M-%S-annotated.png " ..
    "--copy-command wl-copy --early-exit"), { description = "Screenshots: Region, then annotate" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Apps: Color picker" })   -- color picker: click a pixel, its hex goes to the clipboard

-- SPECIAL WORKSPACES
local special_apps = {
    ["special:term"]  = "ghostty",
    ["special:music"] = "g4music",
    ["special:files"] = "nautilus",
}

hl.on("workspace.created", function(ws)
    local app = special_apps[ws.name]
    if app and ws.is_empty then
        hl.exec_cmd(app, { workspace = ws.name .. " silent" })
    end
end)

-- term/music/files start their app when first opened; common and second start empty
hl.bind(mainMod .. " + T",   hl.dsp.workspace.toggle_special("term"),   { description = "Scratchpads: Terminal" })
hl.bind(mainMod .. " + TAB", hl.dsp.workspace.toggle_special("music"),  { description = "Scratchpads: Music" })
hl.bind(mainMod .. " + A",   hl.dsp.workspace.toggle_special("files"),  { description = "Scratchpads: Files" })
hl.bind(mainMod .. " + R",   hl.dsp.workspace.toggle_special("common"), { description = "Scratchpads: Common" })
hl.bind(mainMod .. " + S",   hl.dsp.workspace.toggle_special("second"), { description = "Scratchpads: Second" })
hl.bind(mainMod .. " + CTRL + T",  hl.dsp.window.move({ workspace = "special:term" }),   { description = "Scratchpads: Move window to Terminal" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:files" }),  { description = "Scratchpads: Move window to Files" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.move({ workspace = "special:common" }), { description = "Scratchpads: Move window to Common" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:second" }), { description = "Scratchpads: Move window to Second" })

-- WINDOWS
hl.bind(mainMod .. " + C", hl.dsp.focus({ workspace = "previous" }), { description = "Workspaces: Previous workspace" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Windows: Close" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Windows: Force kill" })   -- kills the process, for apps that ignore Close
hl.bind(mainMod .. " + D", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Toggle floating" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("timeout 1 qs ipc call panel toggle"), { description = "Apps: Dashboard" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("timeout 1 qs ipc call clipboard toggle"), { description = "Apps: Clipboard history" })   -- clipboard history
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("timeout 1 qs ipc call panel clearNotifs"), { description = "Apps: Clear notifications" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Windows: Fullscreen" })
hl.bind(mainMod .. " + W", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Windows: Maximize" })
hl.bind(mainMod .. " + P", hl.dsp.layout("togglesplit"), { description = "Windows: Toggle split direction" })

-- ordered (ipairs), so the keybind cheat sheet lists them as h j k l
local dirs = { { "h", "l" }, { "j", "d" }, { "k", "u" }, { "l", "r" } }

for _, d in ipairs(dirs) do
    hl.bind(mainMod .. " + " .. d[1], hl.dsp.focus({ direction = d[2] }), { description = "Windows: Move focus" })
    hl.bind(mainMod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }), { description = "Windows: Move window" })
end

hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true, description = "Windows: Resize" })
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true, description = "Windows: Resize" })
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true, description = "Windows: Resize" })
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true, description = "Windows: Resize" })

-- WORKSPACES
hl.bind(mainMod .. " + x", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next / previous workspace" })
hl.bind(mainMod .. " + z", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Next / previous workspace" })

hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "r-1" }), { description = "Workspaces: Move window to previous / next" })
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "r+1" }), { description = "Workspaces: Move window to previous / next" })

-- colemak row: 1 2 3 4 n e i o  ->  workspaces 1..8
local wsKeys = { "1", "2", "3", "4", "n", "e", "i", "o" }

for i, key in ipairs(wsKeys) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Workspaces: Go to workspace 1-8" })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Workspaces: Move window to workspace 1-8" })
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- MOUSE
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Windows: Drag to move" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Windows: Drag to resize" })

--------------------
---- MULTIMEDIA ----
--------------------

hl.bind(mainMod .. " + comma",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media: Previous track" })
hl.bind(mainMod .. " + period",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: Play / pause" })
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media: Next track" })

hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, description = "Media: Volume down" })
hl.bind(mainMod .. " + braceright",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, description = "Media: Volume up" })
hl.bind(mainMod .. " + apostrophe", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Media: Mute" })

-- Brightness has no change events: after brightnessctl, tell the OSD to show
-- the new level (timeout: the call can hang while Quickshell reloads)
local osd_brightness = "; timeout 1 qs ipc call osd brightness"
-- Floor for brightness down: 655 = 1% of max (65535), like the panel slider.
-- -n takes a raw value only ("-n5%" reads as 5), and the default 1 is black.
local min_brightness = "-n655 "

hl.bind(mainMod .. " + emdash", hl.dsp.exec_cmd("brightnessctl set 5%+" .. osd_brightness), { repeating = true, description = "Media: Brightness up" })
hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd("brightnessctl " .. min_brightness .. "set 5%-" .. osd_brightness), { repeating = true, description = "Media: Brightness down" })

-- Laptop media keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 " .. min_brightness .. "set 5%+" .. osd_brightness), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 " .. min_brightness .. "set 5%-" .. osd_brightness), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
