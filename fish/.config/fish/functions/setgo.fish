function setgo
	switch (echo $argv[1])
	case 1.10
		set go_version 1.10.3
	case 1.11
		set go_version 1.11.5
	case 1.12
		set go_version 1.12.5
	case tip
		set go_version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/current
end

complete -c setgo -x -a "1.10 1.11 1.12 tip"
