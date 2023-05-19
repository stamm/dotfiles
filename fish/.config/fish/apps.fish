# source /usr/local/etc/grc.fish
if test -d (brew --prefix)"/share/fish/completions"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end
source /opt/homebrew/opt/asdf/libexec/asdf.fish

# psql
fish_add_path /opt/homebrew/opt/libpq/bin

status --is-interactive; and source (jump shell fish | psub)
starship init fish | source
eval (command direnv hook fish | source)
