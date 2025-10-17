# Container Images

This directory contains the `Dockerfiles` used to build the custom container images for this project. Each image serves a specific role within the network simulations.

---

### 1. `alpine-iot-node`

* **Base Image**: `alpine`
* **Description**: A minimal image equipped with basic networking utilities (like `iproute2`, `ping`, `curl`) and an MQTT client (`mosquitto-clients`).
* **Intended Use**: Designed to function as a lightweight IoT leaf node in Containerlab network topologies.

---

### 2. `debian-client-slim`

* **Base Image**: `debian:bookworm-slim`
* **Description**: A lean Debian-based image that includes a standard set of networking tools.
* **Intended Use**: Serves as a simulated user client or general-purpose host within Containerlab network simulations.

---

### 3. `zerotier`

* **Base Image**:  `debian:bookworm-slim`
* **Description**: A container running the ZeroTier One client. It is configured to use a persistent identity and static network interface names, which are supplied via a mounted volume.
* **Intended Use**: Acts as a secure network node that can connect to virtual networks across different environments.
* 