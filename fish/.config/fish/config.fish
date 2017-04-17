set -x LC_ALL en_US.UTF-8

#export LC_CTYPE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=C

set -x GOPATH $HOME/code/go
set -x GOROOT /usr/local/go
set -x GO15VENDOREXPERIMENT 1

set CDPATH . $GOPATH/src
# eval (command echo $PATH)
set PATH /usr/local/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /opt/X11/bin
set PATH $HOME/.bin $PATH 
set PATH $GOROOT/bin $PATH $GOPATH/bin

set -x EDITOR nvim

set -x GOOGLE_APPLICATION_CREDENTIALS /Users/stamm/.config/gcloud/application_default_credentials.json

set PATH ~/.rbenv/shims $PATH
# status --is-interactive; and source (rbenv init -|psub)


if [ -z "$TMUX" ]
	set -x TERM xterm-256color
end

if [ "$TERM" != "screen-255color" ]
	eval (command tmuxinator start local)
end

eval (command direnv hook fish)

