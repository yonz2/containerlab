# Dockerfile to install missing components to sonic-vs image
FROM docker-sonic-vs:latest
ENV DEBIAN_FRONTEND=noninteractive
LABEL \
    org.opencontainers.image.title="SONiC-VS" \
    org.opencontainers.image.description="SONiC-VS image with SSHD installed and user admin added" \
    org.opencontainers.image.vendor="Yonz" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.created="2025-01-04T18:14:19Z" \
    org.opencontainers.image.revision="0" \
    maintainer="Yonz <yonz@me.com>"

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo 

# Add a user    
RUN useradd -m -u 1000 -s /bin/bash admin && \
    mkdir -p /home/admin/.ssh && \
    chown -R admin:admin /home/admin/.ssh && \
    chmod 700 /home/admin/.ssh

RUN echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'admin:SONiC@2025' | chpasswd && \
    echo -n 'root:SONiC@2025' | chpasswd

# Allow root login
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Append the supervisord config file for sshd to the supervisord.conf file
RUN echo ' ' >> /etc/supervisor/conf.d/supervisord.conf &&  \
    echo '[program:sshd]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/usr/sbin/sshd -D' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf

RUN ssh-keygen -A
COPY authorized_keys /home/admin/.ssh/authorized_keys
RUN chown admin:admin /home/admin/.ssh/authorized_keys && \
    chmod 600 /home/admin/.ssh/authorized_keys
    
EXPOSE 22

