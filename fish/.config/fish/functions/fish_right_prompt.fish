function kubectl_status
  [ -z "$KUBECTL_PROMPT_ICON" ]; and set -l KUBECTL_PROMPT_ICON "⎈"
  [ -z "$KUBECTL_PROMPT_SEPARATOR" ]; and set -l KUBECTL_PROMPT_SEPARATOR "/"
  set -l config $KUBECONFIG
  [ -z "$config" ]; and set -l config "$HOME/.kube/config"
  if [ ! -f $config ]
    echo (set_color red)$KUBECTL_PROMPT_ICON" "(set_color white)"no config"
    return
  end

  set -l ctx (grep -oP '(?<=current-context: ).+' $config 2>/dev/null)
  if [ $status -ne 0 ]
    echo (set_color red)$KUBECTL_PROMPT_ICON" "(set_color white)"no context"
    return
  end

  set -l color_k8s white
  set -l color_k8s_icon cyan
  switch $ctx
  	case o-prod
			set color_k8s red
			set color_k8s_icon brred
  	case o-infra-ts
			set color_k8s magenta
			set color_k8s_icon brmagenta
  	case o-stg
			set color_k8s yellow
			set color_k8s_icon bryellow
  	case o-dev
			set color_k8s blue
			set color_k8s_icon brblue
  	case o-cicd-infra
			set color_k8s green
			set color_k8s_icon brgreen
  end

  # set -l ns (kubectl config view -o "jsonpath={.contexts[?(@.name==\"$ctx\")].context.namespace}")
  set -l ns (grep -A1 -E "cluster: $ctx\$" $config | grep -oP '(?<=namespace: ).+')
  [ -z $ns ]; and set -l ns 'default'

  echo (set_color $color_k8s_icon)$KUBECTL_PROMPT_ICON" "(set_color $color_k8s)"($ctx$KUBECTL_PROMPT_SEPARATOR$ns)"
end

function fish_right_prompt
	echo (kubectl_status)
	echo " "

	set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
	date "+%H:%M:%S "

	echo "$CMD_DURATION ms"
	set_color normal
end
