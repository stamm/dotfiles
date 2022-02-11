function setgo
	switch (echo $argv[1])
	case 1.16
		set go_version 1.16.14
	case 1.17
		set go_version 1.17.7
	case 1.18
		set go_version 1.18beta2
	case tip
		set go_version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/current
end

complete -c setgo -x -a "1.16 1.17 1.18 tip"
