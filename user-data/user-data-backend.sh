#!/bin/bash

set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo '{"text": "${server_text}"}' > index.html
nohup busybox httpd -f -p "${server_http_port}" &
