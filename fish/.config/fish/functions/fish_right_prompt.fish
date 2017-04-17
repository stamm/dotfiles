function fish_right_prompt
	set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
	date "+%H:%M:%S "

	echo "$CMD_DURATION ms"
	set_color normal
end
