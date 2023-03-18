#!/usr/bin/env bash

PIP_PACKAGES={$PIP_PACKAGES:-ansible}

apt-get update \
  && apt-get install -y --no-install-recommends \
     apt-utils \
     build-essential \
     locales \
     libffi-dev \
     libssl-dev \
     libyaml-dev \
     python3-dev \
     python3-setuptools \
     python3-pip \
     python3-yaml \
     software-properties-common \
     rsyslog systemd systemd-cron sudo iproute2 \
     curl git \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/* \
  && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

# Set Python3 to be the default (allow users to call "python" and "pip" instead of "python3" "pip3"
update-alternatives --install /usr/bin/python python /usr/bin/python3 1

python -m pip install --upgrade pip

pip3 install $PIP_PACKAGES
