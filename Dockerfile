# EnergyPlus Automated Simulation Server
# Based on Ubuntu 22.04 LTS
FROM ubuntu:22.04

# Environment variables configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# EnergyPlus versions to install (from 8.9.0 to 25.1.0)
ENV ENERGYPLUS_VERSIONS="8.9.0 9.0.1 9.1.0 9.2.0 9.3.0 9.4.0 9.5.0 9.6.0 9.7.0 9.8.0 9.9.0 22.1.0 23.1.0 24.1.0 25.1.0"

# NAS configuration (will be overwritten by .env file)
ENV REMOTE_PROJECT_FOLDER="/mnt/remote/project/"
ENV NAS_ADDRESS="10.0.0.1"
ENV NAS_SHARE="temp/epeditor"
ENV NAS_USERNAME="your_username"
ENV NAS_PASSWORD="your_password"
ENV NAS_MOUNT_POINT="/mnt/remote"

# EnergyPlus working directory
ENV EP_WORK_DIR="/epTemp"

# Scanning mode: random, time, or default
ENV WALK_MODE="random"

# Update system and install required packages
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-dev \
    build-essential \
    net-tools \
    iproute2 \
    cifs-utils \
    wget \
    curl \
    unzip \
    git \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure Python environment
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
RUN pip3 install --upgrade pip

# Create working directories
WORKDIR /app
RUN mkdir -p ${EP_WORK_DIR}

# Copy application files
COPY servers.py /app/servers.py

# Install Python dependencies (if any)
RUN pip3 install python-dotenv

# Create EnergyPlus installation script
RUN echo '#!/bin/bash\n\
for version in $ENERGYPLUS_VERSIONS; do\n\
    echo "Installing EnergyPlus $version"\n\
    if [ $(echo "$version < 9.0" | bc) -eq 1 ]; then\n\
        url="https://github.com/NREL/EnergyPlus/releases/download/v$version/EnergyPlus-$version-Linux-x86_64.sh"\n\
    else\n\
        url="https://github.com/NREL/EnergyPlus/releases/download/v$version/EnergyPlus-$version-Linux-Ubuntu22.04-x86_64.sh"\n\
    fi\n\
    wget -q $url -O energyplus-$version.sh\n\
    chmod +x energyplus-$version.sh\n\
    ./energyplus-$version.sh --accept --nox11 --prefix=/usr/local/EnergyPlus-$version\n\
    rm energyplus-$version.sh\n\
    # Create version file for compatibility\n\
    echo "$version" > /usr/local/EnergyPlus-$version/version.vrs\n\
done' > install_energyplus.sh && chmod +x install_energyplus.sh

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 1. Configure network settings\n\
echo "Configuring network interfaces..."\n\
cat > /etc/netplan/01-dual-dhcp.yaml << EOF\n\
network:\n\
  version: 2\n\
  renderer: networkd\n\
  ethernets:\n\
    eth0:\n\
      dhcp4: true\n\
      routes:\n\
        - to: 0.0.0.0/0\n\
          via: 192.168.1.1\n\
          metric: 100\n\
    eth1:\n\
      dhcp4: true\n\
      routes:\n\
        - to: 0.0.0.0/0\n\
          via: 10.0.0.1\n\
          metric: 200\n\
EOF\n\
\n\
# 2. Apply network configuration\n\
echo "Applying network configuration..."\n\
netplan apply || true\n\
systemctl restart systemd-networkd || true\n\
\n\
# 3. Mount NAS storage\n\
echo "Mounting NAS storage at $NAS_MOUNT_POINT..."\n\
mkdir -p $NAS_MOUNT_POINT\n\
umount $NAS_MOUNT_POINT 2>/dev/null || true\n\
mount -t cifs \\\n    //${NAS_ADDRESS}/${NAS_SHARE} $NAS_MOUNT_POINT \\\n    -o username=${NAS_USERNAME},password=${NAS_PASSWORD},rw,exec,uid=$(id -u),gid=$(id -g),iocharset=utf8,vers=3.0\n\
\n\
# 4. Install EnergyPlus versions\n\
echo "Installing EnergyPlus versions..."\n\
/app/install_energyplus.sh\n\
\n\
# 5. Create EnergyPlus working directory\n\
echo "Creating EnergyPlus working directory: $EP_WORK_DIR"\n\
mkdir -p $EP_WORK_DIR\n\
chmod 777 $EP_WORK_DIR\n\
\n\
# 6. Start the simulation server\n\
echo "Starting EnergyPlus simulation server..."\n\
echo "Configuration:"\n\
echo "  REMOTE_PROJECT_FOLDER: $REMOTE_PROJECT_FOLDER"\n\
echo "  EP_WORK_DIR: $EP_WORK_DIR"\n\
echo "  WALK_MODE: $WALK_MODE"\n\
echo "  NAS_MOUNT_POINT: $NAS_MOUNT_POINT"\n\
\n\
python3 /app/servers.py' > /app/start_server.sh && chmod +x /app/start_server.sh

# Set the startup command
CMD ["/app/start_server.sh"]