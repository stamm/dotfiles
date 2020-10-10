set -x LC_ALL en_US.UTF-8

#export LC_CTYPE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=C

set -x GOPATH $HOME/go
set -x GOROOT /usr/local/go_versions/current
set -x GO111MODULE on

#set -x GOPROXY http://athens.s.o3.ru


set -x ETCDCTL_API 3

# set CDPATH . $GOPATH/src
# eval (command echo $PATH)
set PATH /usr/local/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
# /opt/X11/bin
#set PATH $HOME/.bin $PATH 
set PATH $GOROOT/bin $PATH $GOPATH/bin
set PATH $PATH $HOME/Downloads/flutter/bin
#set PATH $HOME/.cargo/bin $PATH
#set -x PAGER "most"

set -x EDITOR nvim

# set -x CHEAT_CONFIG_PATH ~/.cheat
set -x CHEAT_USE_FZF true
# set -x GOOGLE_APPLICATION_CREDENTIALS /Users/stamm/.config/gcloud/application_default_credentials.json

set PATH ~/.rbenv/shims $PATH
status --is-interactive; and source (rbenv init -|psub)
set PATH /usr/local/opt/grep/libexec/gnubin $PATH

set GPG_TTY (tty)

set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES

set PATH $HOME/.bin $PATH

abbr --add vim "nvim"
abbr --add c "cheat"
abbr --add q "qbec"

abbr --add k "kubectl"
abbr --add kx "kubectx"
abbr --add kn "kubens"
abbr --add kg "kubectl get"
abbr --add kcd 'kubectl config set-context (kubectl config current-context) --namespace '
abbr --add kstg "kubectl --context=o-dev"
abbr --add kgp "kubectl get po -o wide"
abbr --add kgpa "kubectl get po -A -o wide"
abbr --add kgpl "kubectl get po -owide -l app.kubernetes.io/name="
abbr --add kgpal "kubectl get po -A -o wide -l app.kubernetes.io/name="
abbr --add kgs "kubectl get svc"
abbr --add kgsa "kubectl get svc -A -o wide"
abbr --add kgi "kubectl get ing"
abbr --add kgia "kubectl get ing -A -o wide"
abbr --add kgn "kubectl get no -o wide"
abbr --add kgnl "kubectl get no -o wide -l node-role.kubernetes.io/"
abbr --add kdp "kubectl describe po"
abbr --add kdn "kubectl describe no"
abbr --add kd "kubectl describe"
abbr --add ku "kubectl uncordon"
abbr --add kdra "kubectl drain --ignore-daemonsets"
abbr --add ke "kubectl exec -it"
alias kgcma "kubectl get cm -A"

alias krew "kubectl-krew"

function kgcm -w 'kubectl get cm' -d 'kubectl get cm'
  kubectl get cm $argv
end


abbr --add be "bundle exec"

abbr --add g "git"
abbr --add gc "git commit"
abbr --add gp "git pull --rebase"

abbr --add ll "exa -l"


source ~/.config/fish/local/local.fish
source /usr/local/etc/grc.fish


set -g fish_user_paths "/usr/local/opt/python@3.7/bin" $fish_user_paths
set DYLD_LIBRARY_PATH /usr/local/opt/openssl/lib $DYLD_LIBRARY_PATH


eval (command direnv hook fish)

if [ $TERM != "screen-256color" ]
  tmux has-session -t base;
  if [ $status != 0 ]
    tmux new -s base
  end
  tmux attach -t base;
end
