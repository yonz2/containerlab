# add internal DNS first, public as fallback
sudo tee /etc/resolvconf/resolv.conf.d/head >/dev/null <<'EOF'
nameserver 10.0.0.3
nameserver 8.8.8.8
EOF

sudo resolvconf -u

cat /etc/resolv.conf
ping -c 3 registry-1.docker.io
# sudo docker run hello-world


