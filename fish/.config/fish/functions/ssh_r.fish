function ssh_r
  while ! nc -z -w 5 $argv[1] 22; sleep 5; end; say 'ssh is ready'
end
