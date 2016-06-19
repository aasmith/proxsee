# -*- ruby -*-

require "rubygems"
require "hoe"

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :minitest
# Hoe.plugin :racc
# Hoe.plugin :rcov
# Hoe.plugin :rdoc

Hoe.spec "proxsee" do
  developer("Andrew A. Smith", "andy@tinnedfruit.org")

  license "MIT"
end

task "example" => %w(example:haproxy example:nginx)

task "example:haproxy" do
  sh %{ docker run -it --rm \
          -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
          -v $(pwd):/tests proxsee-haproxy }.squeeze " "
end

task "example:nginx" do
  sh %{ docker run -it --rm \
          -v $(pwd)/nginx-proxy.conf:/etc/nginx/conf.d/default.conf \
          -v $(pwd):/tests proxsee-nginx }.squeeze " "
end

task "example:build" => %w(example:build:haproxy example:build:nginx)

task "example:build:haproxy" do
  sh %{ docker build -f Dockerfile.haproxy -t proxsee-haproxy . }
end

task "example:build:nginx" do
  sh %{ docker build -f Dockerfile.nginx -t proxsee-nginx . }
end

# vim: syntax=ruby
