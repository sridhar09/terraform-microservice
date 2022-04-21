#!/bin/bash

set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

sudo apt-get install -y ruby
sudo gem install sinatra --no-rdoc --no-ri

cat << EOF > app.rb
require 'sinatra'
require 'open-uri'

set :port, ${server_http_port}
set :bind, '0.0.0.0'

get '/' do
  open('${backend_url}') do |content|
    "<h1>${server_text}</h1><p>Response from backend:</p><pre>" + content.read.to_s + "</pre>"
  end
end
EOF

nohup ruby app.rb &
