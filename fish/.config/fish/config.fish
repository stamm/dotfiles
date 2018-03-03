set -x LC_ALL en_US.UTF-8

#export LC_CTYPE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=C

set -x GOPATH $HOME/code/go
set -x GOROOT /usr/local/go_versions/current
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

set GPG_TTY (tty)

abbr --add vim "nvim"
abbr --add k "kubectl"
abbr --add kcd 'kubectl config set-context (kubectl config current-context) --namespace '


abbr --add setgo15 "ln -nfs /usr/local/go_versions/1.5.3 /usr/local/go_versions/current"
abbr --add setgo16 "ln -nfs /usr/local/go_versions/1.6.4 /usr/local/go_versions/current"
abbr --add setgo17 "ln -nfs /usr/local/go_versions/1.7.5 /usr/local/go_versions/current"
abbr --add setgo18 "ln -nfs /usr/local/go_versions/1.8.5 /usr/local/go_versions/current"
abbr --add setgo19 "ln -nfs /usr/local/go_versions/1.9.2 /usr/local/go_versions/current"
abbr --add setgo110 "ln -nfs /usr/local/go_versions/1.10beta1 /usr/local/go_versions/current"
abbr --add setgotip "ln -nfs /usr/local/go_versions/tip /usr/local/go_versions/current"







if [ -z "$TMUX" ]
	set -x TERM xterm-256color
end

if [ "$TERM" != "screen-255color" ]
	eval (command tmuxinator start local)
end

eval (command direnv hook fish)

