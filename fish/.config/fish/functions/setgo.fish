function setgo
	switch (echo $argv[1])
	case 17
		set go_version 1.17.13
	case 18
		set go_version 1.18.10
	case 19
		set go_version 1.19.9
		ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/1.19
	case 20
		set go_version 1.20.4
		ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/1.20
	case tip
		set go_version tip
	case '*'
		echo "Don't have this version"
		return 1
	end
	ln -nfs /usr/local/go_versions/$go_version /usr/local/go_versions/current
end

complete -c setgo -x -a "17 18 19 20 tip"
