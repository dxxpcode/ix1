# ix1 Design System

Status: approved direction (interface brainstorm, 2026-11-11). This is the M4
design contract. The desktop shell, Settings, Software Center, and all
first-party applications must consume these tokens and components.

## Direction

Two themes derived from one token set:

- **Graphite** — dark theme. Engineering target and default for development.
- **Porcelain** — light theme. Derived from the same tokens, not a separate design.

Both share: bottom-center floating dock, top panel, frosted-glass shell
chrome, 12 px default corner radius, hairline borders, restrained motion.

Approved concept mockups (generated during brainstorm):

1. Graphite — deep charcoal surfaces, aurora wallpaper, glass dock.
2. Porcelain — soft white surfaces, blue-white wave wallpaper, glass dock.

A third concept (warm "Gallery" palette) was explored and deferred; it may
return later as a wallpaper/accent pack, not a theme.

## Layout

```
┌──────────────────────────────────────────────────────────┐
│ ix1   [workspaces]            9:41   wifi audio batt ⚙  │  top panel
│                                                          │
│                                                          │
│                       desktop surface                    │
│                                                          │
│        [dock: pinned + running apps, centered]           │
└──────────────────────────────────────────────────────────┘
```

- **Top panel** — full width, 32 px tall. Left: product mark / active
  workspace indicator. Center: clock (click → calendar). Right: tray
  cluster (network, audio, battery) and system menu.
- **Dock** — floating, bottom center. Pinned apps + running apps with
  indicator dots. Click to launch/focus, middle-click to close (where
  supported). No magnification effect.
- **Launcher** — overlay summoned from dock icon or `Super`. Search-first
  list with category sections; app grid secondary.
- **Quick settings** — slide-down panel from tray: Wi-Fi, Bluetooth,
  volume slider, brightness (where supported), power, Settings shortcut.
- **Notifications** — top-right cards, auto-dismiss, dismiss on click,
  do-not-disturb toggle in quick settings.
- **Lock screen** — full-bleed wallpaper, large clock, user avatar,
  PAM-based unlock.

## Color tokens

All colors are design tokens consumed by QML; components never hardcode
hex values.

### Graphite (dark)

| Token | Value | Use |
|---|---|---|
| `bg.base` | `#0E0F12` | desktop background fallback |
| `surface.1` | `#17181C` | panel, dock base |
| `surface.2` | `#1D1F24` | raised surfaces, cards |
| `surface.3` | `#24262B` | hover/active states |
| `border.hairline` | `rgba(255,255,255,0.08)` | 1 px dividers, panel edges |
| `text.primary` | `#F2F3F5` | primary text |
| `text.secondary` | `#9BA1AB` | secondary text, inactive icons |
| `accent` | `#8AB4FF` | focus rings, selection, primary actions |

Wallpaper: abstract dark aurora gradient (deep blue → violet), subtle,
never behind body text without a scrim.

### Porcelain (light)

| Token | Value | Use |
|---|---|---|
| `bg.base` | `#F6F7F9` | desktop background fallback |
| `surface.1` | `#FFFFFF` | panel, dock base |
| `surface.2` | `#ECEEF2` | raised surfaces, cards |
| `surface.3` | `#E2E5EA` | hover/active states |
| `border.hairline` | `rgba(15,23,42,0.08)` | 1 px dividers, panel edges |
| `text.primary` | `#16181D` | primary text |
| `text.secondary` | `#5B6472` | secondary text, inactive icons |
| `accent` | `#3563E9` | focus rings, selection, primary actions |

Wallpaper: soft blue-white wave gradient, subtle.

**Accent discipline:** the accent color is used only for focus rings,
selection, links, and primary buttons — never large fills or decorative
areas. Both themes keep identical layout, spacing, and component shapes.

## Typography

- **UI typeface**: Inter Tight (fallback: Inter, then Noto Sans). Fedora
  package: `inter-fonts` (verify availability at M4 build time).
- **Numerals**: tabular figures for clock, battery, and any live values so
  layouts never shift.
- **Type scale**: 11 / 12 / 13 / 15 / 20 / 28 px; weights 400 / 500 / 600.
- **Labels**: 11 px secondary text, sentence case — no all-caps except the
  clock's AM/PM.

## Spacing, radius, icons

- **Spacing scale**: 4 / 8 / 12 / 16 / 24 / 32 px (base unit 4 px).
- **Corner radius**: 12 px default (dock, launcher, cards); 8 px small
  controls; pill radius only for indicator dots and toggles.
- **Icons**: single-weight line icons, 1.5 px stroke, consistent 24 px
  grid. The ix1 X mark anchors the icon theme (see `branding.md`).
- **Borders over shadows**: elevation is expressed with hairline borders
  and surface steps, not drop shadows. One soft shadow allowed for the
  floating dock only.

## Materials

- **Frosted glass is shell-only**: panel, dock, launcher, and quick
  settings use translucency + background blur over the wallpaper. Apps and
  content surfaces stay solid. No glass inside applications.

## Motion

- **Durations**: 200–250 ms ease-out for panel/dock/launcher transitions.
- **Travel**: 4–8 px slide or fade; no bounce, no overshoot.
- **Restraint**: no continuous animations, no decorative motion. Honor
  reduced-motion settings.

## Brand usage in UI

- Product name `ix1` (lowercase) in text; X mark for icons/splash.
- Monochrome mark only — do not recolor (see `branding.md`).
- PNG/SVG derivatives of the official marks are required before M4 UI
  implementation (tracked as an M4 prerequisite).

## Component notes (spec §4.3 mapping)

| Spec component | Design note |
|---|---|
| Desktop shell | Wallpaper layer + shell chrome layer; apps render above |
| Dock | Bottom center, floating, 12 px radius, indicator dots |
| Launcher | Search-first overlay, category sections, keyboard navigable |
| System panel | 32 px top bar, clock center-left, tray right |
| Quick settings | Slide-down card from tray, grouped toggles + sliders |
| Notifications | Top-right cards, grouped by app, actions inline |
| Window management | KWin SSD titlebars in M4, matching panel height; CSD deferred |
| Lock screen | Full-bleed wallpaper, large clock, avatar, PAM unlock |

## Engineering notes (M4 inputs, decisions deferred to M4 plan)

- Qt 6 / QML shell over KWin (Wayland). No custom compositor (spec §4.3).
- Shell chrome placement mechanism (layer-shell vs KWin-specific) to be
  decided in the M4 plan after validating Qt6 support.
- Workspaces: KWin virtual desktops, exposed via panel/dock later.
- Both themes must be implemented as token swaps; Graphite is the default
  development theme.

## Open decisions

- Launcher default key binding (`Super` proposed).
- Dock magnification: rejected for M4 (spec: avoid unnecessary effects).
- Accent hue final sign-off on real hardware/screenshots during M4.
