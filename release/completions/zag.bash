# Zag bash completion script
# Install to /usr/share/bash-completion/completions/ for system-wide installation
# or source this file directly in your ~/.bashrc

_zag() {
    local cur prev commands
    _init_completion || return
    
    commands="init add remove rm update list ls info fetch build lock clean version help"
    
    case $prev in
        zag)
            # Complete with available commands
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            return
            ;;
        remove|rm|info)
            # Try to complete with package names from build.zig.zon
            if [ -f "build.zig.zon" ]; then
                local packages=$(grep -o '\..*= \.' build.zig.zon | awk '{print $1}' | sed 's/\.//')
                COMPREPLY=($(compgen -W "$packages" -- "$cur"))
            fi
            return
            ;;
        list|ls)
            # Complete with list options
            COMPREPLY=($(compgen -W "--json" -- "$cur"))
            return
            ;;
        clean)
            # Complete with clean options
            COMPREPLY=($(compgen -W "--all" -- "$cur"))
            return
            ;;
        add)
            # Can't easily complete GitHub repos, so don't provide completions
            return
            ;;
    esac
    
    # Default to command completion if we're at the start
    if [[ "$cur" == "" ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    fi
}

complete -F _zag zag