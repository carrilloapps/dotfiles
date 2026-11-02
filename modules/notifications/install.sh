#!/usr/bin/env bash
# macOS-style notifications:
#  - Banners appear at the top right, below the top bar, and hide after 5 s.
#  - Everything is kept in the history (low priority too), which opens from the
#    bell at the right end of the top bar, like the Notification Center (the
#    layout module puts it there).
# describe: top-right banners with history in the top bar | avisos arriba a la derecha con historial en la barra superior

N=(--file plasmanotifyrc --group Notifications)
kw "${N[@]}" --key PopupPosition TopRight
kw "${N[@]}" --key PopupTimeout 5000
kw "${N[@]}" --key LowPriorityPopups true
kw "${N[@]}" --key LowPriorityHistory true
kw "${N[@]}" --key CriticalInDndMode true
kw "${N[@]}" --key ShowPopupTimeout false   # no countdown line (macOS has none)
# Notifications without a desktop entry ("Other applications") stay in the
# history too
kw --file plasmanotifyrc --group Applications --group @other --key ShowInHistory true
kw --file plasmanotifyrc --group Badges --key InTaskManager true
info "$(L "banners at the top right; history in the top bar bell" "avisos arriba a la derecha; historial en la campana de la barra superior")"
