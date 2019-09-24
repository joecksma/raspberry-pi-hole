
#!/bin/bash
read -r -p "Do you really want to force a Pi-hole update? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        continue
        ;;
    *)
        exit 0
        ;;
esac

echo "Updating Pi-hole"
echo "Downloading new container..."
sudo docker pull pihole/pihole:latest
echo "Removing old container..."
sudo docker rm -f pihole
echo "Starting new container..."
sudo docker run -d --name pihole \
        -p 53:53/tcp \
        -p 53:53/udp \
        -p 67:67/udp \
        -p 8080:80 \
        -e ServerIP=192.168.178.70 \
        -v "$(pwd)/etc-pihole:/etc/pihole" \
        -v "$(pwd)/etc-dnsmasq.d:/etc/dnsmasq.d" \
        --restart=unless-stopped \
        --cap-add=NET_ADMIN \
        pihole/pihole:latest
echo "Finished. It might take a while before Pi-hole finished loading."
