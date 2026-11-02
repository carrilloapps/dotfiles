#!/bin/bash
# RedRog: asusd's power profile and its power limits, kept (modules/system).
# Installed as /usr/local/lib/redrog/asusd-profile-keeper, run by
# redrog-asusd-profile.service alongside asusd.
#
# 1. Power limits at every start. Since Linux 7.3, asus-armoury refuses PPT
#    (CPU power limit) writes until a custom fan curve is active ("PPT change
#    requires an active fan curve on this model"), and asusd restores the
#    limits before the fan curves: they failed with "Device or resource busy"
#    and the CPU was left throttled until the profile changed. Setting the
#    active profile again, once the fan curves are on, makes asusd write the
#    profile's limits; retried until asusd logs no failure.
# 2. The user's choice survives restarts and plugging the charger. asusd
#    switches to its on-AC / on-battery profile at start and on every power
#    change, but never records a profile picked by hand. Whichever way it is
#    picked (RedRog panel, Fn+F5, the Armoury key, ROG Control Center,
#    asusctl), it is saved as the profile for the current power source.
set -u
SVC=xyz.ljones.Asusd OBJ=/xyz/ljones IF=xyz.ljones.Platform
get() { busctl --system get-property "$SVC" "$OBJ" "$IF" "$1" 2>/dev/null | awk '{print $2}'; }
put() { busctl --system set-property "$SVC" "$OBJ" "$IF" "$1" u "$2"; }
on_ac() {
  local s
  for s in /sys/class/power_supply/*; do
    case "$(cat "$s/type" 2>/dev/null)" in Mains|USB) ;; *) continue ;; esac
    [ "$(cat "$s/online" 2>/dev/null)" = 1 ] && return 0
  done
  return 1
}

for _ in $(seq 60); do
  profile="$(get PlatformProfile)"
  [ -n "$profile" ] && break
  sleep 1
done
[ -n "$profile" ] || { echo "asusd did not answer" >&2; exit 1; }

# ── 1. power limits ──────────────────────────────────────────────────────────
for try in 1 2 3 4 5; do
  sleep 3   # asusd turns the fan curves on right after its restore pass
  since="$(date '+%F %T')"
  put PlatformProfile "$(get PlatformProfile)"
  sleep 2
  if ! journalctl -u asusd --since "$since" --no-pager -q 2>/dev/null | grep -q 'Could not restore PPT'; then
    echo "power limits of the active profile applied (try $try)"
    break
  fi
done

# ── 2. persist the profile picked by hand ────────────────────────────────────
gdbus monitor --system --dest "$SVC" --object-path "$OBJ" | while read -r line; do
  case "$line" in *"'PlatformProfile': <uint32 "*) ;; *) continue ;; esac
  value="${line##*\'PlatformProfile\': <uint32 }"
  value="${value%%>*}"
  # let a power change settle: asusd itself switching profiles on plug or
  # unplug always matches the saved profile, so nothing is written then
  sleep 1
  [ "$(get PlatformProfile)" = "$value" ] || continue
  if on_ac; then key=PlatformProfileOnAc; else key=PlatformProfileOnBattery; fi
  if [ "$(get "$key")" != "$value" ]; then
    put "$key" "$value" && echo "profile $value saved as $key"
  fi
done
# gdbus ends when asusd goes away: fail, so systemd starts over with it
exit 1
