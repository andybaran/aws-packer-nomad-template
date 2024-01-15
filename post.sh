#!/bin/bash
set -e

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o install-docker.sh
sh install-docker.sh
echo "Done!"

echo "Adding Hashicorp repo..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update -y 
apt upgrade -y
echo "Done!"

echo "Installing Podman..."
touch /etc/{subgid,subuid}
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${OS_USER}
grep ${OS_USER} /etc/subuid /etc/subgid
apt install -y podman
podman system service -t 0 &
echo "Done!"

echo "Creating directories..."
mkdir -p /opt/nomad/data/plugins
mkdir -p /etc/nomad.d 
echo "Done!"

if [ "${ENTERPRISE}" == true ]; then
  curl --silent --remote-name "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}+ent/nomad_${NOMAD_VERSION}+ent_linux_amd64.zip"
  7z x "nomad_${NOMAD_VERSION}+ent_linux_amd64.zip" -o./nomad
  mv /tmp/license.hclic /etc/nomad.d/license.hclic
else
  curl --silent --remote-name "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
  7z x "nomad_${NOMAD_VERSION}_linux_amd64.zip" -o./nomad
fi


echo "Configuring Nomad..."
#Set nomad path owner as root since this will be run as client
mv ./nomad/nomad /usr/bin/nomad
chown root:root /usr/bin/nomad
nomad -autocomplete-install && complete -C /usr/bin/nomad nomad
mv /tmp/nomad.hcl /etc/nomad.d/nomad.hcl
mv /tmp/nomad.service /etc/systemd/system/nomad.service

echo "Downloading and extracting Podman driver..."
wget https://releases.hashicorp.com/nomad-driver-podman/0.5.1/nomad-driver-podman_0.5.1_linux_amd64.zip
7z x nomad-driver-podman_0.5.1_linux_amd64.zip -o./
mv ./nomad-driver-podman /opt/nomad/data/plugins

systemctl reboot