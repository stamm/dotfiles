set -x LC_ALL en_US.UTF-8

set -U fish_greeting

source $__fish_config_dir/go.fish

fish_add_path -g /opt/homebrew/bin
fish_add_path /usr/local/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin
fish_add_path -a $GOPATH/bin $HOME/.krew/bin
fish_add_path -p $GOROOT/bin $HOME/Downloads/flutter/bin $HOME/.bin $HOME/.rbenv/shims /usr/local/opt/grep/libexec/gnubin

set -x ETCDCTL_API 3
set -x EDITOR nvim
set -x CHEAT_USE_FZF true
set GPG_TTY (tty)
set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES

# for calicoctl
set -x DATASTORE_TYPE kubernetes
set -x KUBECONFIG $HOME/.kube/config

alias krew "kubectl-krew"

function kgcm -w 'kubectl get cm' -d 'kubectl get cm'
  kubectl get cm $argv
end

source $__fish_config_dir/local/local.fish
source $__fish_config_dir/apps.fish
source $__fish_config_dir/ssh.fish
source $__fish_config_dir/abbr.fish

set -x GRPC_PYTHON_BUILD_SYSTEM_ZLIB true
# set -g fish_user_paths "/usr/local/opt/python@3.9/bin" $fish_user_paths
set DYLD_LIBRARY_PATH /usr/local/opt/openssl/lib $DYLD_LIBRARY_PATH
set CFLAGS -I/usr/local/opt/openssl@1.1/include
set CPPFLAGS -I/usr/local/opt/openssl@1.1/include
set LDFLAGS -L/usr/local/opt/openssl@1.1/lib
set CONFIGURE_OPTS --with-openssl=/usr/local/opt/openssl@1.1

bind \cx edit_command_buffer

# if [ $TERM != "screen-256color" ] && [ $TERM_PROGRAM != "vscode" ]
if [ $TERM != "screen-256color" ]
  tmux has-session -t base;
  if [ $status != 0 ]
    tmuxinator s base
  end
  tmux attach -t base;
end

