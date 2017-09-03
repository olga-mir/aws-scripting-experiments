#!/bin/bash
set -e
set -u

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://openresty.org/package/amazon/openresty.repo
sudo yum install -y openresty
sudo yum install -y openresty-resty
PATH=/usr/local/openresty/nginx/sbin:$PATH
export PATH

ami_launch_index=`curl http://169.254.169.254/latest/meta-data/ami-launch-index`

PAYLOAD_SMALL='payload_small'
PAYLOAD_0_5GB='payload_0_5gb'

dd if=/dev/urandom of=$PAYLOAD_0_5GB bs=1024k count=512
dd if=/dev/urandom of=$PAYLOAD_SMALL bs=10k count=1

nginx_conf_delay="events { worker_connections 1024; } http { server { listen 80; server_name localhost; location / { root html; echo \"I'm a teapot $ami_launch_index\"; } location /payload { echo_blocking_sleep 10; } } }"
nginx_conf_payload="events { worker_connections 1024; } http { server { listen 80; server_name localhost; location / { root html; echo \"I'm a teapot $ami_launch_index\"; } location /payload { root html/data; } } }"

NGINX_CONF=''
PAYLOAD=''

case "$ami_launch_index" in
  0)
    NGINX_CONF=$nginx_conf_delay
    PAYLOAD=$PAYLOAD_SMALL
    ;;
  1)
    NGINX_CONF=$nginx_conf_payload
    PAYLOAD=$PAYLOAD_SMALL
    ;;
  2)
    NGINX_CONF=$nginx_conf_payload
    PAYLOAD=$PAYLOAD_0_5GB
    ;;
esac

NGINX_ROOT_DIR="/usr/local/openresty/nginx"
echo $NGINX_CONF > ./nginx.conf
sudo cp ./nginx.conf $NGINX_ROOT_DIR/conf/nginx.conf
sudo mkdir $NGINX_ROOT_DIR/html/data
sudo cp  ./$PAYLOAD $NGINX_ROOT_DIR/html/data/payload

chkconfig openresty on
sudo service openresty start
