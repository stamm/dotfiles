# source /usr/local/etc/grc.fish
source /usr/local/opt/asdf/asdf.fish
status --is-interactive; and source (jump shell fish | psub)
starship init fish | source
eval (command direnv hook fish | source)
