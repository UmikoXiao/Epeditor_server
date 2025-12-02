# EnergyPlus Automated Simulation Server

## Overview
This is an automated EnergyPlus simulation server that scans NAS folders for IDF files and runs simulations automatically. The server monitors specified directories, detects simulation jobs, and processes them using various versions of EnergyPlus.

## Features
- **Automated Scanning**: Continuously monitors NAS folders for simulation jobs
- **Multi-version Support**: Installs and supports EnergyPlus versions from 8.9.0 to 25.1.0
- **Flexible Scanning Modes**: Random, time-based, or standard directory walking
- **NAS Integration**: Automatically mounts and processes files from NAS storage
- **Result Management**: Copies simulation results back to NAS after completion
- **Duplicate Prevention**: Uses .runit files to prevent duplicate processing

## Environment Variables

### Required Configuration
```bash
# NAS Configuration
NAS_USERNAME=your_username
NAS_PASSWORD=your_password
NAS_ADDRESS=10.0.0.1
NAS_SHARE=temp/epeditor
NAS_MOUNT_POINT=/mnt/remote

# Simulation Configuration
REMOTE_PROJECT_FOLDER=/mnt/remote/project/
EP_WORK_DIR=/epTemp
WALK_MODE=random  # Options: random, time, default

# EnergyPlus Versions (modify as needed)
ENERGYPLUS_VERSIONS="8.9.0 9.0.1 9.1.0 9.2.0 9.3.0 9.4.0 9.5.0 9.6.0 9.7.0 9.8.0 9.9.0 22.1.0 23.1.0 24.1.0 25.1.0"
```

## File Structure
```
/
├── app/
│   ├── servers.py          # Main application script
│   ├── start_server.sh     # Startup script
│   └── install_energyplus.sh # EnergyPlus installation script
├── epTemp/                 # EnergyPlus working directory
├── mnt/remote/             # Mounted NAS storage
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose configuration
├── .env                    # Environment variables
└── README.md               # Documentation
```

## How It Works

### Simulation Job Detection
1. The server scans `REMOTE_PROJECT_FOLDER` for directories containing `.runit` files
2. When a `.runit` file is found, the directory is processed
3. The `.runit` file is removed to prevent duplicate processing

### Simulation Process
1. Copies all files from the NAS directory to `EP_WORK_DIR`
2. Identifies IDF, EPW, and version files
3. Runs EnergyPlus simulation with the specified version
4. Copies all output files back to the original NAS directory
5. Cleans up the local working directory

## Installation and Setup

### Prerequisites
- Docker and Docker Compose installed
- Access to NAS storage with CIFS/SMB support
- Network connectivity to EnergyPlus download servers

### Quick Start

1. **Configure Environment Variables**
```bash
cp .env.example .env
nano .env  # Set your NAS credentials and configuration
```

2. **Build and Start the Server**
```bash
docker-compose build
docker-compose up -d
```

3. **Monitor Logs**
```bash
docker-compose logs -f
```

### Manual Docker Commands

```bash
# Build the image
docker build -t energyplus-simulator .

# Run the container
docker run -d \
  --name energyplus-simulator \
  --privileged \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_ADMIN \
  -e NAS_USERNAME=your_username \
  -e NAS_PASSWORD=your_password \
  -e REMOTE_PROJECT_FOLDER=/mnt/remote/project/ \
  -e EP_WORK_DIR=/epTemp \
  -e WALK_MODE=random \
  energyplus-simulator
```

## Usage Instructions

### Creating Simulation Jobs
1. Create a directory on the NAS under `REMOTE_PROJECT_FOLDER`
2. Add your IDF file (`.idf`), weather file (`.epw`), and version file (`.vrs`)
3. Create an empty `.runit` file to trigger simulation
4. The server will automatically detect and process the job

### Version File Format
Create a file named `version.vrs` containing only the EnergyPlus version number:
```
25.1.0
```

## Scanning Modes

### Random Mode (`WALK_MODE=random`)
- Directories are processed in random order
- Good for load balancing across multiple servers
- Prevents contention for the same directories

### Time Mode (`WALK_MODE=time`)
- Directories are processed by modification time
- Default: oldest first (can be reversed with code modification)
- Good for prioritizing newer or older jobs

### Default Mode (`WALK_MODE=default`)
- Standard os.walk() behavior
- Directories processed in alphabetical order
- Predictable but may cause bottlenecks

## Monitoring and Maintenance

### Checking Server Status
```bash
docker-compose ps
docker-compose logs --tail=50
```

### Viewing Simulation Progress
```bash
docker exec -it energyplus-simulator tail -f /app/simulation.log
```

### Manual Intervention
```bash
# Enter the container
docker exec -it energyplus-simulator bash

# Check NAS mount
mount | grep cifs

# Check EnergyPlus installations
ls -la /usr/local/EnergyPlus-*
```

## Troubleshooting

### Common Issues

1. **NAS Mount Failure**
   - Verify NAS credentials and network connectivity
   - Check CIFS/SMB service on the NAS
   - Ensure the share name is correct

2. **EnergyPlus Installation Issues**
   - Check internet connectivity
   - Verify version numbers in `ENERGYPLUS_VERSIONS`
   - Check download URLs in `install_energyplus.sh`

3. **Simulation Failures**
   - Check EnergyPlus error messages in logs
   - Verify IDF file validity
   - Ensure correct version is specified

## Performance Optimization

1. **Limit EnergyPlus Versions**
   - Only install versions you actually need
   - Reduces image size and installation time

2. **Adjust Scan Interval**
   - Modify the sleep time in `servers.py`
   - Balance between responsiveness and resource usage

3. **Use Multiple Servers**
   - Deploy multiple instances with random mode
   - Distribute load across servers

## Security Considerations

1. **Credentials Management**
   - Use Docker secrets in production
   - Avoid storing plaintext passwords in .env
   - Restrict access to the .env file

2. **Container Security**
   - Use non-root users in production
   - Limit container capabilities
   - Regularly update the base image

3. **Network Security**
   - Restrict NAS access to specific IPs
   - Use VPN for remote access
   - Monitor network traffic

## Maintenance Schedule

1. **Daily**
   - Check logs for errors
   - Verify NAS connectivity
   - Monitor disk usage

2. **Weekly**
   - Clean up old simulation files
   - Check for EnergyPlus updates
   - Verify backup integrity

3. **Monthly**
   - Update base Docker image
   - Review security settings
   - Performance optimization

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
Create by: [Umiko](htps://github.com/umikoxiao)
- [EnergyPlus](https://energyplus.net/) - Building energy simulation software
- [NREL](https://www.nrel.gov/) - National Renewable Energy Laboratory
- [Docker](https://www.docker.com/) - Containerization platform
- [Epeditor](https://github.com/Umikoxiao/epeditor) - client side and offline simulation tools


## 🤗 CERTIFICATION  

Developed by Research team directed by **Prof. Borong Lin** from Key Laboratory of Eco Planning & Green Building, Ministry of Education, Tsinghua University.  
**For collaboration, Please contact:**  
linbr@tsinghua.edu.cn  
**If you have any technical problems, Please reach to:**  
junx026@gmail.com


