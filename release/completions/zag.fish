# Zag fish completion script
# Install to ~/.config/fish/completions/zag.fish

# Main commands
complete -c zag -f
complete -c zag -n __fish_use_subcommand -a init -d 'Initialize a new project'
complete -c zag -n __fish_use_subcommand -a add -d 'Add a dependency to the project'
complete -c zag -n __fish_use_subcommand -a remove -d 'Remove a dependency from the project'
complete -c zag -n __fish_use_subcommand -a rm -d 'Alias for remove'
complete -c zag -n __fish_use_subcommand -a update -d 'Update all dependencies to latest versions'
complete -c zag -n __fish_use_subcommand -a list -d 'List all dependencies in the project'
complete -c zag -n __fish_use_subcommand -a ls -d 'Alias for list'
complete -c zag -n __fish_use_subcommand -a info -d 'Show detailed information about a package'
complete -c zag -n __fish_use_subcommand -a fetch -d 'Fetch dependencies'
complete -c zag -n __fish_use_subcommand -a build -d 'Build the project'
complete -c zag -n __fish_use_subcommand -a lock -d 'Update the lock file without downloading'
complete -c zag -n __fish_use_subcommand -a clean -d 'Remove cache and build artifacts'
complete -c zag -n __fish_use_subcommand -a version -d 'Show zag version'
complete -c zag -n __fish_use_subcommand -a help -d 'Show help information'

# Command-specific options
function __fish_zag_packages
    if test -f "build.zig.zon"
        grep -o '\..*= \.' build.zig.zon | awk '{print $1}' | sed 's/\.//'
    end
end

# List options
complete -c zag -n "__fish_seen_subcommand_from list ls" -l json -d "Output as JSON"

# Clean options
complete -c zag -n "__fish_seen_subcommand_from clean" -l all -d "Remove all build artifacts and lock files"

# Package name completions for remove/info
complete -c zag -n "__fish_seen_subcommand_from remove rm info" -a "(__fish_zag_packages)"