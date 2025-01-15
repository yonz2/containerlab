# Dockerfile to add network utilities, sudo ssh and bash to alpine
#
# Version 1.0
# Alpine version 3.21 or later

FROM debian:bookworm-slim

LABEL \
    org.opencontainers.image.title="linux-netutils" \
    org.opencontainers.image.description="" \
    org.opencontainers.image.vendor="Yonz" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.created="2025-01-04T18:14:19Z" \
    org.opencontainers.image.revision="0" \
    maintainer="Yonz <yonz@me.com>"

RUN apt update &&  apt install -y \
    sudo \
    wget \
    curl \
    openssh-server \
    python3 \
    python3-pip \
    mosquitto-clients && rm -rf /var/lib/apt/lists/*


# Add admin user - Alternative to root, can be used as "client" user during testing;
# add to sudo group then set password (also root password)
RUN useradd -D -u 1000 -s /bin/bash admin && \
    echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo -n 'admin:SONiC@2025' | chpasswd && \
    echo -n 'root:SONiC@2025' | chpasswd
    
RUN usermod -aG sudo admin

# Configure SSHD to allow root login
EXPOSE 22

# Create sshd directory and generate host keys
RUN mkdir /var/run/sshd
RUN /usr/bin/ssh-keygen -A

# Set sshd parameters to allow root login and enable password less access (ssh keys only)
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Make SSD start at boot time
RUN systemctl enable ssh.service

# Create the .ssh directories and copy the authorized_keys file
RUN mkdir -p /home/admin/.ssh && \
    chown -R admin:admin /home/admin/.ssh && \
    chmod 700 /home/admin/.ssh && \
    mkdir -p /root/.ssh && \
    chown -R root:root /root/.ssh && \
    chmod 700 /root/.ssh

COPY authorized_keys /home/admin/.ssh/authorized_keys
COPY authorized_keys /root/.ssh/authorized_keys

# Set the correct permissions on the authorized_keys files
RUN chown admin:admin /home/admin/.ssh/authorized_keys && \
    chmod 600 /home/admin/.ssh/authorized_keys && \
    chown root:root /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys


# Set the default command to run when starting the container

CMD ["/bin/bash"]

