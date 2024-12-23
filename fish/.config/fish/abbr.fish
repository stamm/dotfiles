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
abbr --add kgd "kubectl get deploy -o wide"
abbr --add kgda "kubectl get deploy -A -o wide"
abbr --add kgdl "kubectl get deploy -owide -l app.kubernetes.io/name="
abbr --add kgdal "kubectl get deploy -A -owide -l app.kubernetes.io/name="
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
abbr --add kgcma "kubectl get cm -A"


abbr --add be "bundle exec"

abbr --add g "git"
abbr --add gl "git log -p --stat"
abbr --add gc "git commit"
abbr --add gd "git diff"
abbr --add gp "git pull --rebase"

abbr --add ll "eza -laB"
