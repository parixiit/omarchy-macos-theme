#!/usr/bin/env bash
# macOS Sequoia Setup for Omarchy
# One-line installer: curls and sets up all scripts, gestures, shortcuts, systemd daemon, and dynamic cursors.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==>${NC} Installing macOS Sequoia Theme for Omarchy..."

# 1. Install & set theme
omarchy theme install https://github.com/ayush-rdev/omarchy-macos-theme.git 2>/dev/null || true
omarchy theme set macos

THEME_DIR="$HOME/.config/omarchy/themes/macos"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$BIN_DIR" "$SYSTEMD_USER_DIR"

# 2. Install all macOS helper scripts
echo -e "${BLUE}==>${NC} Installing macOS helper scripts to $BIN_DIR..."
if [[ -d "$THEME_DIR/scripts" ]]; then
  cp -f "$THEME_DIR/scripts/"* "$BIN_DIR/"
  chmod +x "$BIN_DIR/omarchy-toggle-fullscreen-space" \
           "$BIN_DIR/omarchy-spaces-listener" \
           "$BIN_DIR/omarchy-close-workspace-windows" \
           "$BIN_DIR/omarchy-window-hide" \
           "$BIN_DIR/toggle-window-switcher" 2>/dev/null || true
fi

# 3. Setup and start the Spaces Auto-Clean & Return background daemon
echo -e "${BLUE}==>${NC} Enabling macOS Spaces auto-clean daemon..."
cat << 'EOF' > "$SYSTEMD_USER_DIR/omarchy-spaces-listener.service"
[Unit]
Description=macOS Spaces Auto-Clean & Return daemon for Hyprland
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/omarchy-spaces-listener
Restart=always
RestartSec=2s

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now omarchy-spaces-listener.service

# 4. Configure Gestures & Shortcuts if not already present
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"
HYPR_INPUT="$HOME/.config/hypr/input.lua"

if [[ -f "$HYPR_BINDINGS" ]] && ! grep -q "omarchy-toggle-fullscreen-space" "$HYPR_BINDINGS"; then
  echo -e "${BLUE}==>${NC} Configuring macOS shortcuts (Win+F, Win+H, Win+Alt+W, Win+V)..."
  cat << 'EOF' >> "$HYPR_BINDINGS"

-- macOS Theme Shortcuts
o.bind("SUPER + H", "Hide window", os.getenv("HOME") .. "/.local/bin/omarchy-window-hide")
o.bind("SUPER + ALT + H", "Unhide window", os.getenv("HOME") .. "/.local/bin/omarchy-window-hide unhide")
o.bind("SUPER + ALT + W", "Close all windows in workspace", os.getenv("HOME") .. "/.local/bin/omarchy-close-workspace-windows")
o.bind("SUPER + F", "Toggle fullscreen space", os.getenv("HOME") .. "/.local/bin/omarchy-toggle-fullscreen-space")
o.bind("SUPER + ALT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("mouse:274", "Toggle fullscreen space", os.getenv("HOME") .. "/.local/bin/omarchy-toggle-fullscreen-space", { mouse = true })
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + ALT + " .. key)
  o.bind("SUPER + ALT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end
EOF
fi

if [[ -f "$HYPR_INPUT" ]] && ! grep -q "toggle-window-switcher" "$HYPR_INPUT"; then
  echo -e "${BLUE}==>${NC} Configuring macOS Touchpad Gestures..."
  cat << 'EOF' >> "$HYPR_INPUT"

-- macOS Touchpad gestures (3-finger swipe to slide spaces, 3-finger swipe up for window switcher)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({
  fingers = 3,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/toggle-window-switcher"))
  end,
})
EOF
fi

# 5. Setup macOS "Shake to Find" Dynamic Cursor
PLUGINS_DIR="$HOME/.config/hypr/plugins"
mkdir -p "$PLUGINS_DIR"
if [[ -f "$THEME_DIR/plugins/dynamic-cursors.so" ]]; then
  echo -e "${BLUE}==>${NC} Installing macOS Dynamic Cursor (Shake to Find)..."
  cp -f "$THEME_DIR/plugins/dynamic-cursors.so" "$PLUGINS_DIR/dynamic-cursors.so"

  HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
  if [[ -f "$HYPR_MAIN" ]] && ! grep -q "dynamic-cursors.so" "$HYPR_MAIN"; then
    cat << 'EOF' >> "$HYPR_MAIN"

-- Load dynamic cursor plugin for macOS-like shake to find
hl.plugin.load(os.getenv("HOME") .. "/.config/hypr/plugins/dynamic-cursors.so")
EOF
  fi

  HYPR_LOOK="$HOME/.config/hypr/looknfeel.lua"
  if [[ -f "$HYPR_LOOK" ]] && ! grep -q "dynamic_cursors" "$HYPR_LOOK"; then
    cat << 'EOF' >> "$HYPR_LOOK"

-- macOS "Shake to Find" Cursor Magnification (Zero wobble/tilt, pure enlargement)
hl.config({
  plugin = {
    dynamic_cursors = {
      enabled = true,
      mode = "none", -- Strictly "none" to disable all tilt/wobble/rotation effects
      shake = {
        enabled = true,
        threshold = 5.0,  -- Trigger sensitivity
        base = 3.5,       -- Initial magnification when shaken
        speed = 4.0,      -- Growth speed while shaking continues
        limit = 5.5,      -- Maximum cursor size
        timeout = 1000,   -- Milliseconds before shrinking back
        effects = false,  -- Explicitly false to prevent wobbling or distortions
        ipc = false,
      },
      hyprcursor = {
        enabled = true,
        nearest = true,
        resolution = -1,
        fallback = "clientside",
      },
    },
  },
})
EOF
  fi

  hyprctl plugin load "$PLUGINS_DIR/dynamic-cursors.so" 2>/dev/null || true
fi

# Reload Hyprland
hyprctl reload >/dev/null 2>&1 || true

echo -e "${GREEN}==>${NC} macOS Sequoia Theme, gestures, shortcuts, spaces daemon, and dynamic cursor setup complete! 🎉"
