#!/bin/bash

set -euo pipefail

sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g'      /etc/apt/sources.list.d/debian.sources
sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources

pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
pip install --no-cache-dir --upgrade pip setuptools wheel

apt-get update
apt-get install -y \
    build-essential \
    ca-certificates \
    bash-completion \
    git \
    curl \
    wget \
    vim \
    sudo

rm -rf /var/lib/apt/lists/*
