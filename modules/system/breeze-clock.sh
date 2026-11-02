#!/usr/bin/env bash
# RedRog: the clock of the login and lock screens as "9:10 PM". Both show
# org.kde.breeze.components' Clock (plasma-workspace), which writes the time
# in the locale's format, and no Spanish locale has "PM" ("9:10 p. m."). A
# copy of that QML module, with Clock.qml patched and every other file linked
# to the original, goes in /usr/local/share/redrog/qml, which the login screen
# (plasma-login.service drop-in) and the session (environment.d) put first in
# QML_IMPORT_PATH. Installed by modules/system as
# /usr/local/lib/redrog/breeze-clock.sh and run again by the pacman hook
# zz-redrog-clock.hook after plasma-workspace updates. If Clock.qml changed
# upstream and the patch no longer applies, the copy is removed and the stock
# clock is used.
set -euo pipefail
SRC=/usr/lib/qt6/qml/org/kde/breeze/components
DST="${1:-/usr/local/share/redrog/qml}/org/kde/breeze/components"
rm -rf "$DST"
[ -f "$SRC/Clock.qml" ] || exit 0
mkdir -p "$DST"
for f in "$SRC"/*; do
  case "$(basename "$f")" in qmldir|Clock.qml) ;; *) ln -s "$f" "$DST/" ;; esac
done
# "prefer" would load the copies compiled into the plugin instead of these files
grep -v '^prefer ' "$SRC/qmldir" > "$DST/qmldir"
old='text: Qt.formatTime(timeSource.dateTime, Qt.locale(), Locale.ShortFormat)'
new='text: /a/i.test(Qt.locale().timeFormat(Locale.ShortFormat)) ? (timeSource.dateTime.getHours() % 12 || 12) + Qt.formatTime(timeSource.dateTime, ":mm") + (timeSource.dateTime.getHours() < 12 ? " AM" : " PM") : Qt.formatTime(timeSource.dateTime, Qt.locale(), Locale.ShortFormat)'
if grep -qF "$old" "$SRC/Clock.qml"; then
  python3 -I -c 'import sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(s.replace(sys.argv[3], sys.argv[4], 1))' \
    "$SRC/Clock.qml" "$DST/Clock.qml" "$old" "$new"
else
  rm -rf "$DST"
  echo "RedRog: Clock.qml changed upstream; the stock clock stays" >&2
fi
exit 0
