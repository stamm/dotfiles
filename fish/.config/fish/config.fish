set -x LC_ALL en_US.UTF-8

#export LC_CTYPE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=C

set -x GOPATH $HOME/code/go
set -x GOROOT /usr/local/go_versions/current
set -x GO15VENDOREXPERIMENT 1

set CDPATH . $GOPATH/src
# eval (command echo $PATH)
set PATH /usr/local/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
# /opt/X11/bin
#set PATH $HOME/.bin $PATH 
set PATH $GOROOT/bin $PATH $GOPATH/bin
#set PATH $HOME/.cargo/bin $PATH
set PAGER "most"

set -x EDITOR nvim

# set -x GOOGLE_APPLICATION_CREDENTIALS /Users/stamm/.config/gcloud/application_default_credentials.json

set PATH ~/.rbenv/shims $PATH
# status --is-interactive; and source (rbenv init -|psub)

set GPG_TTY (tty)

abbr --add vim "nvim"
abbr --add k "kubectl"
abbr --add kx "kubectx"
abbr --add kcd 'kubectl config set-context (kubectl config current-context) --namespace '
abbr --add kstg "kubectl --context=o-stg"
abbr --add kgp "kubectl get po"
abbr --add kgpa "kubectl get po --all-namespaces"
abbr --add kgs "kubectl get svc"
abbr --add kgsa "kubectl get svc --all-namespaces"
abbr --add kgi "kubectl get ing"
abbr --add kgia "kubectl get ing --all-namespaces"

function kgcm -w 'kubectl get cm' -d 'kubectl get cm'
	kubectl get cm $argv
end
alias kgcma "kubectl get cm --all-namespaces"

#abbr --add setgo110 "ln -nfs /usr/local/go_versions/1.10.3 /usr/local/go_versions/current"
#abbr --add setgotip "ln -nfs /usr/local/go_versions/tip /usr/local/go_versions/current"







eval (command direnv hook fish)
if [ -z "$TMUX" ]
	set -x TERM xterm-256color
end

tmux attach -t base; or tmux new -s base


