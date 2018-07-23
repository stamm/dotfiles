function setgo
	switch (echo $argv[1])
	case 1.10
		set version 1.10.3
	case 1.11
		set version 1.11beta1
	case tip
		set version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$version /usr/local/go_versions/current
end

complete -c setgo -x -a "1.10 1.11 tip"
