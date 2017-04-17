function setgo
	switch (echo $argv[1])
	case 1.5
		set version 1.5.3
	case 1.6
		set version 1.6.4
	case 1.7
		set version 1.7.5
	case 1.8
		set version 1.8.1
	case tip
		set version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$version /usr/local/go
end

complete -c setgo -x -a "1.5 1.6 1.7 1.8 tip"
