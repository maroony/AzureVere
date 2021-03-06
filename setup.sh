#!/usr/bin/env bash

set -e
set -o pipefail

dockerVersionSub="18.09.6"
dockerversion="5:${dockerVersionSub}~3-0~ubuntu-bionic"

USER_MOUNTPOINT=/mnt

echo "[setup.sh] install docker"
apt update
apt install -y -q -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y -q -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    "docker-ce=${dockerversion}" "docker-ce-cli=${dockerversion}" containerd.io

# prep docker
echo "[setup.sh] Stop docker"
systemctl stop docker.service
rm -rf /var/lib/docker
echo "[setup.sh] Mkdir docker"
mkdir -p /etc/docker
echo "{ \"data-root\": \"$USER_MOUNTPOINT/docker\", \"hosts\": [ \"unix:///var/run/docker.sock\", \"tcp://127.0.0.1:2375\" ] }" > /etc/docker/daemon.json
sed -i 's|^ExecStart=/usr/bin/dockerd.*|ExecStart=/usr/bin/dockerd|' /lib/systemd/system/docker.service

echo "[setup.sh] daemon-reload"
systemctl daemon-reload
# do not auto-enable docker to start due to temp disk issues
echo "[setup.sh] disable docker.service"
systemctl disable docker.service
echo "[setup.sh] start docker.service"
systemctl start docker.service
#echo "[setup.sh] status docker.service"
#systemctl status docker.service || true
echo "[setup.sh] finished"

exit 0
