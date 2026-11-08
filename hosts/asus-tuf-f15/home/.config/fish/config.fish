# RedRog: the Claude desktop terminal doesn't answer fish's terminal queries;
# without this every new shell there waits 10 s and prints a warning
if test "$TERM_PROGRAM" = claude-desktop; and status is-interactive; and not set -q REDROG_FISH_NOQUERY
    set -gx REDROG_FISH_NOQUERY 1
    exec fish --features no-query-term
end
source /usr/share/cachyos-fish-config/cachyos-config.fish
source ~/.config/fish/redrog/greeting.fish  # RedRog

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

status is-interactive; and eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"  # RedRog: interactive only



# Added by Antigravity CLI installer
set -gx PATH "/home/m/.local/bin" $PATH

# mise: per-project tool versions
if test -x ~/.local/bin/mise
    ~/.local/bin/mise activate fish | source
end
