-- macOS — Theme-scoped Hyprland appearance, physics, and animations.
--
-- Omarchy loads this file only while this theme is active:
--   require_optional.module("omarchy.current.theme.hyprland")
-- and re-evaluates the entire config on every theme switch, so nothing here
-- leaks. Switch to any other theme and the Omarchy defaults are cleanly restored.

local function read_theme_colors()
  local colors = {}
  local path = os.getenv("HOME") .. "/.local/state/omarchy/current/theme/colors.toml"
  local file = io.open(path, "r")
  if not file then return colors end

  for line in file:lines() do
    local key, value = line:match('^%s*([%w_%-]+)%s*=%s*"([^"]*)"')
    if key then colors[key] = value end
  end

  file:close()
  return colors
end

local colors = read_theme_colors()

local function gradient(token, fallback)
  local spec = colors[token] or (fallback and colors[fallback]) or ""
  local stops = {}
  local angle = nil

  for part in spec:gmatch("%S+") do
    local deg = part:match("^(%-?%d+)deg$")
    if deg then
      angle = tonumber(deg)
    else
      stops[#stops + 1] = colors[part] or part
    end
  end

  if #stops == 0 then return nil end
  if #stops == 1 then return stops[1] end
  local res = { colors = stops }
  if angle then res.angle = angle end
  return res
end

-- Authentic macOS subtle 1px Retina rim: soft translucent glass reflection on active, subtle dark glass on inactive
local active_border = gradient("hyprland_active_border") or "rgba(ffffff28)"
local inactive_border = gradient("hyprland_inactive_border") or "rgba(ffffff10)"

hl.config({
  general = {
    -- Authentic macOS fine 1px border rim
    border_size = 1,
    gaps_in = 6,
    -- macOS style: minimal 5px gap under the topbar so windows align cleanly with the bar,
    -- with comfortable 10px margins on left, right, and bottom.
    gaps_out = { top = 5, right = 10, bottom = 10, left = 10 },

    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },

    resize_on_border = true,
    layout = "dwindle",
  },

  decoration = {
    -- Iconic macOS squircle / rounded window corners
    rounding = 12,

    -- Directional downward macOS drop shadows with wide 36px diffusion
    shadow = {
      enabled = true,
      range = 36,
      render_power = 4,
      offset = { 0, 6 },
      color = "rgba(00000070)",
      color_inactive = "rgba(00000035)",
    },

    -- Smooth macOS glass blur
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      new_optimizations = true,
      vibrancy = 0.20,
      noise = 0.01,
    },
  },

  group = {
    col = {
      border_active = active_border,
      border_inactive = inactive_border,
    },

    groupbar = {
      height = 24,
      font_weight_active = "bold",
      indicator_height = 2,
      gradient_rounding = 8,
    },
  },
})

-- App-specific scroll smoothing tuned for macOS feel
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.3 })
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 0.8 })
o.window("(org.telegram.desktop|AyuGram)", { scroll_touchpad = 0.85 })
o.window("org.gnome.Nautilus", { scroll_touchpad = 0.9 })

-- Apple macOS fluid bezier curves and spring physics
-- Standard macOS fluid deceleration: cubic-bezier(0.16, 1, 0.3, 1)
hl.curve("macEase", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
-- Subtle spring overshoot: feels alive and responsive
hl.curve("macSpring", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.04 } } })
-- Quick responsive curve for menus, tooltips, and popups
hl.curve("macQuick", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
-- Smooth macOS Spaces horizontal sliding curve: cubic-bezier(0.2, 0.8, 0.2, 1.0)
hl.curve("macSpace", { type = "bezier", points = { { 0.2, 0.8 }, { 0.2, 1.0 } } })

-- macOS window, layer, and workspace animations
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "macEase" })
hl.animation({ leaf = "border", enabled = true, speed = 6.0, bezier = "macEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 6.0, bezier = "macSpring" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5.2, bezier = "macSpring", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4.2, bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4.0, bezier = "macQuick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3.2, bezier = "macQuick" })
hl.animation({ leaf = "fade", enabled = true, speed = 4.0, bezier = "macQuick" })
hl.animation({ leaf = "layers", enabled = true, speed = 5.5, bezier = "macEase" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4.5, bezier = "macEase", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3.5, bezier = "macQuick", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 4.0, bezier = "macQuick" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3.0, bezier = "macQuick" })
-- Smooth macOS Spaces swipe/switch animation
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.0, bezier = "macSpace", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.8, bezier = "macEase", style = "slidevert" })

-- Frosted glass blur for top bar and system overlays
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({
  match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel|omarchy-notifications|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.2,
})

-- macOS "Shake to Find" Cursor Magnification (if dynamic-cursors plugin is installed)
hl.config({
  plugin = {
    dynamic_cursors = {
      enabled = true,
      mode = "none", -- Clean standard pointer behaviour
      shake = {
        enabled = true,
        threshold = 5.0,  -- Trigger sensitivity
        base = 3.5,       -- Initial magnification when shaken
        speed = 4.0,      -- Growth rate while shaking continues
        limit = 5.5,      -- Maximum cursor size
        timeout = 1000,   -- Milliseconds before smoothly shrinking back
        effects = false,  -- No distortion effects
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

