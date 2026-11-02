# RedRog (modules/artcraft), sourced by Plasma at login
# (~/.config/plasma-workspace/env): the control token that PhotoCraft and
# FilmCraft share with their MCP bridge (artcraft-mcp). It is made at each
# login and kept only in the session's runtime folder (memory, owner only),
# which is removed at logout.
redrog_artcraft_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/redrog-artcraft"
if [ ! -s "$redrog_artcraft_dir/token" ]; then
  mkdir -p -m 700 "$redrog_artcraft_dir"
  (umask 077; od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "$redrog_artcraft_dir/token")
fi
PHOTOCRAFT_CONTROL_TOKEN=$(cat "$redrog_artcraft_dir/token")
FILMCRAFT_CONTROL_TOKEN=$PHOTOCRAFT_CONTROL_TOKEN
export PHOTOCRAFT_CONTROL_TOKEN FILMCRAFT_CONTROL_TOKEN
unset redrog_artcraft_dir
