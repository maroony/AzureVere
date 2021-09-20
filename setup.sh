#!/usr/bin/env bash

set -e
set -o pipefail

dockerVersionSub="18.09.6"
dockerversion="5:${dockerVersionSub}~3-0~ubuntu-bionic"
# @see: batch-shipyard/convoy/data.py [https://github.com/Azure/batch-shipyard/blob/d6da749f9cd678037bd520bc074e40066ea35b56/convoy/data.py]
blobxferVersion="1.9.4"
# @see: batch-shipyard/convoy/version.py [https://github.com/Azure/batch-shipyard/blob/d6da749f9cd678037bd520bc074e40066ea35b56/convoy/version.py]
shipyardVersion="3.9.1"
userMountpoint=/mnt

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
echo "{ \"data-root\": \"${userMountpoint}/docker\", \"hosts\": [ \"unix:///var/run/docker.sock\", \"tcp://127.0.0.1:2375\" ] }" > /etc/docker/daemon.json
sed -i 's|^ExecStart=/usr/bin/dockerd.*|ExecStart=/usr/bin/dockerd|' /lib/systemd/system/docker.service

# pull necassary images for offline node prepartion
mcrRepo="mcr.microsoft.com"
docker pull "${mcrRepo}/blobxfer:${blobxferVersion}"
docker pull "${mcrRepo}/azure-batch/${shipyardVersion}"

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
