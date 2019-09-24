#!/bin/bash

if [ $(id -u) != 0 ]; then
	echo "You must run this with sudo / as root"
	exit 1
fi

read -r -p "Do you really want to install Pi-hole? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        ;;
    *)
        exit 0
        ;;
esac

read -r -p "Port for the Webserver (default: 80): " port

read -s -p "Enter new password for Pi-hole: " password
echo ""
read -s -p "Repeat: " password_check
echo ""
if [ $password != $password_check ];
then
	echo "Passwords do not match, exiting!"
	exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
	echo "Installing docker..."
	curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
else
	echo "Found docker"
fi

echo "Installing Pi-hole..."
sudo docker pull pihole/pihole:latest

ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
echo "IP: $ip"

mkdir -p "$(pwd)/etc-dnsmasq.d"
mkdir -p "$(pwd)/etc-pihole"

echo "Starting Pi-hole..."
sudo docker run -d --name pihole -p 53:53/tcp -p 53:53/udp -p 67:67/udp -p $port:80 -e ServerIP="$ip" -v "$(pwd)/etc-pihole:/etc/pihole" -v "$(pwd)/etc-dnsmasq.d:/etc/dnsmasq.d" --restart=unless-stopped --cap-add=NET_ADMIN pihole/pihole:latest

containerid=$(sudo docker ps | awk '{print $1}' | tail -1)
echo "ContainerID: $containerid"

echo "Setting password..."
sudo docker exec -it $containerid sh -c "pihole -a -p $password"

echo "Enabling auto-update (watchtower), every day at 4:30am"
docker pull v2tec/watchtower:latest
docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock v2tec/watchtower:latest --schedule "0 30 4 ? * *"

if [ $port == 80 ]; then
	portpart=""
else
	portpart=":$port"
fi
echo "Done! You can access your Pi-hole via: http://$ip$portpart/admin"

