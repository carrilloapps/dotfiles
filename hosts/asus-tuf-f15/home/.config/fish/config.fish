source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"



# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH
