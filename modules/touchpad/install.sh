#!/usr/bin/env bash
# The touchpad like a Mac's, and desktops like macOS Spaces:
#  - tap to click, two-finger click or tap for the right button, natural
#    (content follows the fingers) two-finger scrolling, tap and drag, ignored
#    while typing
#  - KWin's gestures: three or four fingers left/right switch desktops, four up
#    show every window and desktop (Mission Control), four down the desktop
#    grid; pinch and two-finger swipes go to the apps (zoom, back/forward)
#  - dynamic desktops (KWin script redrog-dynamic-desktops): at least three,
#    a new one appears when the last fills up, empty ones close by themselves
# KWin 6.8 has no three-finger drag; the scroll speed set by the user is kept.
# describe: Mac-like touchpad and dynamic desktops | touchpad como el de Mac y escritorios dinámicos

# Touchpad settings, in kcminputrc (read by KWin at login) and applied now
for dev in /sys/class/input/event*; do
  name=$(cat "$dev/device/name" 2>/dev/null)
  case "$name" in *[Tt]ouchpad*) ;; *) continue ;; esac
  vendor=$((16#$(cat "$dev/device/id/vendor"))); product=$((16#$(cat "$dev/device/id/product")))
  T=(--file kcminputrc --group Libinput --group "$vendor" --group "$product" --group "$name")
  kw "${T[@]}" --key TapToClick true
  kw "${T[@]}" --key ClickMethod 2          # clickfinger: two fingers = right button
  kw "${T[@]}" --key NaturalScroll true
  kw "${T[@]}" --key ScrollTwoFinger true
  kw "${T[@]}" --key TapAndDrag true
  kw "${T[@]}" --key TapDragLock false
  kw "${T[@]}" --key DisableWhileTyping true
  kw "${T[@]}" --key MiddleEmulation false
  if [ "$DRY_RUN" != 1 ]; then
    o=org.kde.KWin; p="/org/kde/KWin/InputDevice/$(basename "$dev")"; i=org.kde.KWin.InputDevice
    for prop in tapToClick:true clickMethodClickfinger:true naturalScroll:true scrollTwoFinger:true \
                tapAndDrag:true tapDragLock:false disableWhileTyping:true middleEmulation:false; do
      qdbus6 $o "$p" org.freedesktop.DBus.Properties.Set $i "${prop%%:*}" "${prop#*:}" >/dev/null 2>&1 || true
    done
  fi
  info "$(L "touchpad: $name like a Mac's" "touchpad: $name como el de Mac")"
done

# Dynamic desktops
S="$DATA_HOME/kwin/scripts/redrog-dynamic-desktops"
run rm -rf "$S"
run mkdir -p "$(dirname "$S")"
run cp -r "$REDROG_ROOT/modules/touchpad/redrog-dynamic-desktops" "$S"
kw --file kwinrc --group Plugins --key redrog-dynamic-desktopsEnabled true
kw --file kwinrc --group Desktops --key Rows 1
kw --file kwinrc --group Plugins --key slideEnabled true
if [ "$DRY_RUN" != 1 ]; then
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript redrog-dynamic-desktops >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi
info "$(L "dynamic desktops: at least three, more when needed" "escritorios dinámicos: al menos tres, más cuando hacen falta")"
