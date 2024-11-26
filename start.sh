#!/bin/bash

# 默认配置
SWIM_PORT=${SWIM_PORT:-7946}
HTTP_PORT=${HTTP_PORT:-4567}
SEEDS=${SEEDS:-""}
PRIMARY=${PRIMARY:-false}

bundle exec rackup -p $HTTP_PORT \
  -E production \
  --host 0.0.0.0 \
  -e "ENV['SWIM_PORT']=$SWIM_PORT; \
      ENV['HTTP_PORT']=$HTTP_PORT; \
      ENV['SEEDS']='$SEEDS'; \
      ENV['PRIMARY']=$PRIMARY" \
  config.ru
