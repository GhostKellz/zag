#compdef zag

# Zag zsh completion script
# Install to /usr/share/zsh/site-functions/_zag for system-wide installation
# or to ~/.zsh/completions/_zag and ensure this directory is in your fpath

local -a commands packages options

_zag_packages() {
    local -a packages
    if [[ -f "build.zig.zon" ]]; then
        packages=(${(f)"$(grep -o '\..*= \.' build.zig.zon | awk '{print $1}' | sed 's/\.//')"})
    fi
    _describe 'packages' packages
}

# Main commands
commands=(
    'init:Initialize a new project'
    'add:Add a dependency to the project'
    'remove:Remove a dependency from the project'
    'rm:Alias for remove'
    'update:Update all dependencies to latest versions'
    'list:List all dependencies in the project'
    'ls:Alias for list'
    'info:Show detailed information about a package'
    'fetch:Fetch dependencies'
    'build:Build the project'
    'lock:Update the lock file without downloading'
    'clean:Remove cache and build artifacts'
    'version:Show zag version'
    'help:Show help information'
)

# Command-specific options
_zag() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case $state in
        command)
            _describe 'commands' commands
            ;;
        args)
            case ${line[1]} in
                remove|rm|info)
                    _zag_packages
                    ;;
                list|ls)
                    _arguments ':options:(--json)'
                    ;;
                clean)
                    _arguments ':options:(--all)'
                    ;;
                build)
                    _arguments '*:zig build arguments:'
                    ;;
                *)
                    _default
                    ;;
            esac
            ;;
    esac
}

_zag "$@"