# macOS Sequoia Theme for Omarchy

An authentic Apple macOS Sequoia theme for the **Omarchy Hyprland Desktop**, featuring translucent frosted glass surfaces, SF-inspired palette, refined drop shadows, and authentic macOS Spaces gestures.

![Preview](preview.png)

---

## What's Included

* **Apple SF Pro Fonts**: Bundles authentic Apple **SF Pro Display** & **SF Pro Text** typography across UI elements, topbar, window titles, and menus.
* **Authentic macOS Glass Rim Borders**: 1px subtle Retina translucent glass hairline reflection (`rgba(ffffff28)`) that blends naturally with wide 36px macOS drop shadows.
* **Apple Spring & Deceleration Physics**: Custom fluid cubic-bezier curves (`macEase`, `macSpring`, `macSpace`) matching macOS Mission Control and Spaces transitions.
* **macOS "Shake to Find" Dynamic Cursor**: Enlarge cursor on rapid mouse shake, smoothly scaling down back to normal size (powered by `dynamic-cursors`).
* **Translucent Frosted Glass Surfaces**: Menu bar, system panels, overlays, and launcher tuned for SF typography and spacing.
* **Optional macOS Spaces & Gestures Experience**: Enhanced scripts for seamless fullscreen spaces, 3-finger horizontal workspace sliding, and Spotlight window switching.

---

## Quick 1-Command Automatic Install (Recommended)

To install everything automatically in one single command (theme, helper scripts, gestures, shortcuts, and spaces auto-clean daemon):

```bash
curl -fsSL https://raw.githubusercontent.com/ayush-rdev/omarchy-macos-theme/master/install.sh | bash
```

*(Or if running from a local clone: `./install.sh`)*

---

## Manual Step-by-Step Installation

If you prefer to configure things manually:

### 1. Install & Apply the Theme
```bash
omarchy theme install https://github.com/ayush-rdev/omarchy-macos-theme.git
omarchy theme set macos
```

### 2. Install Helper Scripts
Copy the bundled macOS helper scripts to your user bin directory:
```bash
cp ~/.config/omarchy/themes/macos/scripts/* ~/.local/bin/
chmod +x ~/.local/bin/omarchy-* ~/.local/bin/toggle-window-switcher
```

### 3. Autostart the Spaces Daemon (`~/.config/hypr/autostart.lua`)
Add the following line so empty fullscreen spaces automatically clean up when their window closes:
```lua
o.launch_on_start("omarchy-spaces-listener")
```

### 4. (Optional) macOS "Shake to Find" Dynamic Cursor
To enable macOS cursor enlargement on rapid shaking:
```bash
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm enable dynamic-cursors
```
Or build from source and load `dynamic-cursors.so` via `hl.plugin.load(...)` in your `~/.config/hypr/hyprland.lua`.

---

## Recommended macOS Keybindings & Gestures

To get the full macOS experience with touchpad gestures and window management, add the following to your Hyprland configuration:

### 1. Touchpad Gestures (`~/.config/hypr/input.lua`)
```lua
-- 3-finger swipe horizontally to slide between workspaces (macOS Spaces)
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

-- 3-finger swipe up to toggle Spotlight Window Switcher
hl.gesture({
  fingers = 3,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/toggle-window-switcher"))
  end,
})
```

### 2. Window & Workspace Shortcuts (`~/.config/hypr/bindings.lua`)
```lua
-- macOS Style Fullscreen Spaces (Win + F and 3-finger click)
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Toggle fullscreen space", "~/.local/bin/omarchy-toggle-fullscreen-space")
o.bind("mouse:274", "Toggle fullscreen space", "~/.local/bin/omarchy-toggle-fullscreen-space", { mouse = true })

-- Clean Window Hide / Unhide (Win + H to hide, Win + Alt + H to unhide)
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")
o.bind("SUPER + H", "Hide window", "~/.local/bin/omarchy-window-hide")
o.bind("SUPER + ALT + H", "Unhide window", "~/.local/bin/omarchy-window-hide unhide")

-- Clipboard manager on Win + V
hl.unbind("SUPER + V")
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Capture Menu & OCR (remapped from Ctrl to Alt)
hl.unbind("SUPER + CTRL + C")
hl.unbind("SUPER + CTRL + PRINT")
o.bind("SUPER + ALT + C", "Capture menu", "omarchy-menu toggle capture")
o.bind("SUPER + ALT + PRINT", "Extract text (OCR) from screenshot", "omarchy-capture-text")

-- Close all windows on current workspace (Win + Alt + W)
o.bind("SUPER + ALT + W", "Close all windows in workspace", "~/.local/bin/omarchy-close-workspace-windows")

-- Fast Workspace Navigation (Win + Tab)
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

-- Move Window to Workspace:
-- Win + Alt + 1..10: Move window and follow
-- Win + Shift + 1..10: Move window silently
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + ALT + " .. key)
  o.bind("SUPER + ALT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end
```

---

## Helper Scripts (`scripts/`)
Copy the scripts to `~/.local/bin/` to enable dedicated Spaces and Hide/Unhide workflows:
- `omarchy-toggle-fullscreen-space`: Moves active window into its own dedicated space (zero resize bounce) and returns it back on exit.
- `omarchy-spaces-listener`: Background daemon that automatically returns you to your previous workspace when a fullscreen space window is closed, just like macOS destroying the space.
- `omarchy-close-workspace-windows`: Closes all windows on the current workspace simultaneously.
- `omarchy-window-hide`: Properly hides windows to scratchpad and unhides them onto the active workspace so `Alt + Tab` and Spotlight switcher see them immediately.
- `toggle-window-switcher`: Spotlight-style window menu for all open windows.
