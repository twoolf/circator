#!/bin/sh

if [ ! -d blackbox ]; then
  git clone https://github.com/StackExchange/blackbox.git
  (cd blackbox && make manual-install) \
    || echo -n "Failed to install blackbox!"
fi
