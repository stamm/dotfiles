function setgo
	switch (echo $argv[1])
	case 1.14
		set go_version 1.14.12
	case 1.15
		set go_version 1.15.5
	case tip
		set go_version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/current
end

complete -c setgo -x -a "1.14 1.15 tip"
