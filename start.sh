ulimit -n 1048576
openresty -p `pwd`/ -c conf/nginx.conf
