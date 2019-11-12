set -x LC_ALL en_US.UTF-8

#export LC_CTYPE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=C

set -x GOPATH $HOME/go
set -x GOROOT /usr/local/go_versions/current

set -x ETCDCTL_API 3

# set CDPATH . $GOPATH/src
# eval (command echo $PATH)
set PATH /usr/local/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
# /opt/X11/bin
#set PATH $HOME/.bin $PATH 
set PATH $GOROOT/bin $PATH $GOPATH/bin
#set PATH $HOME/.cargo/bin $PATH
#set -x PAGER "most"

set -x EDITOR nvim

# set -x GOOGLE_APPLICATION_CREDENTIALS /Users/stamm/.config/gcloud/application_default_credentials.json

set PATH ~/.rbenv/shims $PATH
# status --is-interactive; and source (rbenv init -|psub)
set PATH /usr/local/opt/grep/libexec/gnubin $PATH

set GPG_TTY (tty)

set PATH $HOME/.krew/bin $PATH
abbr --add vim "nvim"
abbr --add k "kubectl"
abbr --add kx "kubectx"
abbr --add kn "kubens"
abbr --add kg "kubectl get"
abbr --add kcd 'kubectl config set-context (kubectl config current-context) --namespace '
abbr --add kstg "kubectl --context=o-dev"
abbr --add kgp "kubectl get po -owide"
abbr --add kgpa "kubectl get po -A -owide"
abbr --add kgpl "kubectl get po -owide -l app.kubernetes.io/name="
abbr --add kgpal "kubectl get po -A -owide -l app.kubernetes.io/name="
abbr --add kgs "kubectl get svc"
abbr --add kgsa "kubectl get svc -A -owide"
abbr --add kgi "kubectl get ing"
abbr --add kgia "kubectl get ing -A -owide"
abbr --add kgn "kubectl get no -owide"
abbr --add kdp "kubectl describe po"
abbr --add kdn "kubectl describe no"
abbr --add kd "kubectl describe"

abbr --add be "bundle exec"

function kgcm -w 'kubectl get cm' -d 'kubectl get cm'
  kubectl get cm $argv
end
alias kgcma "kubectl get cm -A"

alias krew "kubectl-krew"


abbr --add g "git"
abbr --add gc "git commit"
abbr --add gp "git pull --rebase"
abbr --add ll "exa -l"


source ~/.config/fish/local/local.fish


alias python /usr/local/bin/python3
set DYLD_LIBRARY_PATH /usr/local/opt/openssl/lib $DYLD_LIBRARY_PATH


eval (command direnv hook fish)

if [ $TERM != "screen-256color" ]
  tmux has-session -t base;
  if [ $status != 0 ]
    tmux new -s base
  end
  tmux attach -t base;
end
