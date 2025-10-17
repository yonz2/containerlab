# WireGuard Container Image

This document outlines the procedure for deploying the official `linuxserver/wireguard` Docker image within this project, specifically for use on a SONiC virtual machine.

This method does not involve building a new image from a `Dockerfile`. Instead, the pre-built image is pulled from Docker Hub, archived, and then transferred to the target system where it is loaded into the local Docker environment.

---

## Image Source

The image used is the standard, unmodified `linuxserver/wireguard` image.

* **Docker Hub Registry**: `linuxserver/wireguard`
* **Official Page**: [https://hub.docker.com/r/linuxserver/wireguard](https://hub.docker.com/r/linuxserver/wireguard)

---

## Deployment Process

The deployment involves four main steps, moving the image from an internet-connected machine to the isolated SONiC VM.

### 1. Pull the Image

On a machine with internet access and Docker installed, pull the latest version of the image from Docker Hub.

```bash
docker pull linuxserver/wireguard:latest
```

### 2. Save the Image to a Tar Archive

Package the pulled image into a `.tar` file. This allows for easy transfer.

```bash
docker save -o wireguard.tar linuxserver/wireguard:latest
```
This command creates a file named `wireguard.tar` in your current directory.

### 3. Transfer the Archive

Copy the `wireguard.tar` file to the target SONiC VM. You can use tools like `scp`, a shared folder, or any other file transfer method suitable for your environment.

### 4. Load the Image on the SONiC Host

Once the archive is on the SONiC VM, use the `docker load` command to import the image into the local Docker image cache.

```bash
docker load -i wireguard.tar
```

After this step, the `linuxserver/wireguard:latest` image will be available locally and can be used to start a container on the SONiC VM.

---

## Configuration

For details on how to run and configure the container (e.g., setting up peer configurations, port mappings, and volumes), please refer to the comprehensive documentation on the official [linuxserver/wireguard Docker Hub page](https://hub.docker.com/r/linuxserver/wireguard).
