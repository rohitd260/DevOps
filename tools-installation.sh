#!/bin/bash

# Ubuntu DevOps Tools Installation Script
# Installs: AWS CLI, Java 21, Docker, Jenkins, jq
# Configures Jenkins with Docker permissions
# Author: DevOps Setup Script
# Date: $(date +%Y-%m-%d)

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Error handling function
handle_error() {
    log_error "Script failed at line $1. Exit code: $2"
    log_error "Command that failed: $BASH_COMMAND"
    exit $2
}

# Set up error trap
trap 'handle_error $LINENO $?' ERR

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons"
        log_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        log_error "Please ensure your user is in the sudo group"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "This script is designed for Ubuntu systems only"
        exit 1
    fi
    
    local ubuntu_version=$(lsb_release -rs)
    log "Detected Ubuntu version: $ubuntu_version"
    
    # Check if version is supported (18.04+)
    if ! dpkg --compare-versions "$ubuntu_version" "ge" "18.04"; then
        log_error "Ubuntu 18.04 or higher is required"
        exit 1
    fi
}

# Update system packages
update_system() {
    log_section "UPDATING SYSTEM PACKAGES"
    
    log "Updating package lists..."
    sudo apt-get update -qq
    
    log "Upgrading existing packages..."
    sudo apt-get upgrade -y -qq
    
    log "Installing essential packages..."
    sudo apt-get install -y -qq \
        curl \
        wget \
        gnupg \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        lsb-release \
        unzip
    
    log "System update completed successfully"
}

# Install AWS CLI
install_aws_cli() {
    log_section "INSTALLING AWS CLI"
    
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        log "AWS CLI is already installed (version: $aws_version)"
        return 0
    fi
    
    log "Installing AWS CLI v2..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download and install AWS CLI
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    # Verify installation
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        log "AWS CLI v2 installed successfully (version: $aws_version)"
    else
        log_error "AWS CLI installation failed"
        exit 1
    fi
}

# Install Java 21
install_java21() {
    log_section "INSTALLING JAVA 21"
    
    if java -version 2>&1 | grep -q "openjdk version \"21"; then
        log "Java 21 is already installed"
        java -version 2>&1 | head -1
        return 0
    fi
    
    log "Installing OpenJDK 21..."
    
    # Install OpenJDK 21
    sudo apt-get update -qq
    sudo apt-get install -y -qq openjdk-21-jdk
    
    # Set JAVA_HOME
    local java_home="/usr/lib/jvm/java-21-openjdk-amd64"
    
    if [[ -d "$java_home" ]]; then
        echo "export JAVA_HOME=$java_home" | sudo tee -a /etc/environment > /dev/null
        echo "export PATH=\$PATH:\$JAVA_HOME/bin" | sudo tee -a /etc/environment > /dev/null
        
        # Source the environment for current session
        export JAVA_HOME="$java_home"
        export PATH="$PATH:$JAVA_HOME/bin"
        
        log "JAVA_HOME set to: $JAVA_HOME"
    else
        log_warning "Could not find Java installation directory"
    fi
    
    # Verify installation
    if command -v java &> /dev/null; then
        log "Java 21 installed successfully:"
        java -version 2>&1 | head -1
    else
        log_error "Java 21 installation failed"
        exit 1
    fi
}

# Install Docker
install_docker() {
    log_section "INSTALLING DOCKER"
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log "Docker is already installed (version: $docker_version)"
        return 0
    fi
    
    log "Installing Docker..."
    
    # Remove old versions
    sudo apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    sudo apt-get update -qq
    
    # Install Docker Engine
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Verify installation
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log "Docker installed successfully (version: $docker_version)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

# Install Jenkins
install_jenkins() {
    log_section "INSTALLING JENKINS"
    
    if command -v jenkins &> /dev/null || systemctl is-active --quiet jenkins; then
        log "Jenkins is already installed"
        if systemctl is-active --quiet jenkins; then
            log "Jenkins service is running"
        fi
        return 0
    fi
    
    log "Installing Jenkins..."
    
    # Add Jenkins repository key
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    # Add Jenkins repository
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Update package index
    sudo apt-get update -qq
    
    # Install Jenkins
    sudo apt-get install -y -qq jenkins
    
    # Start and enable Jenkins service
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Wait for Jenkins to start
    log "Waiting for Jenkins to start..."
    local timeout=60
    local count=0
    
    while ! sudo systemctl is-active --quiet jenkins && [ $count -lt $timeout ]; do
        sleep 2
        ((count+=2))
    done
    
    if sudo systemctl is-active --quiet jenkins; then
        log "Jenkins installed and started successfully"
        log "Jenkins will be available at: http://localhost:8080"
        
        # Display initial admin password location
        if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
            log "Initial admin password location: /var/lib/jenkins/secrets/initialAdminPassword"
        fi
    else
        log_error "Jenkins installation failed or service didn't start"
        exit 1
    fi
}

# Configure Jenkins Docker permissions
configure_jenkins_docker() {
    log_section "CONFIGURING JENKINS DOCKER PERMISSIONS"
    
    # Check if jenkins user exists
    if ! id jenkins &>/dev/null; then
        log_error "Jenkins user not found. Make sure Jenkins is installed properly."
        exit 1
    fi
    
    # Check if docker group exists
    if ! getent group docker &>/dev/null; then
        log "Creating docker group..."
        sudo groupadd docker
    fi
    
    # Add jenkins user to docker group
    log "Adding jenkins user to docker group..."
    sudo usermod -aG docker jenkins
    
    # Restart Jenkins to apply new group membership
    log "Restarting Jenkins service to apply changes..."
    sudo systemctl restart jenkins
    
    # Wait for Jenkins to restart
    sleep 10
    
    # Verify Jenkins can access Docker
    if sudo systemctl is-active --quiet jenkins; then
        log "Jenkins Docker permissions configured successfully"
        log "Jenkins user has been added to the docker group"
    else
        log_error "Failed to restart Jenkins after Docker configuration"
        exit 1
    fi
}

# Install jq
install_jq() {
    log_section "INSTALLING JQ"
    
    if command -v jq &> /dev/null; then
        local jq_version=$(jq --version)
        log "jq is already installed ($jq_version)"
        return 0
    fi
    
    log "Installing jq..."
    sudo apt-get install -y -qq jq
    
    # Verify installation
    if command -v jq &> /dev/null; then
        local jq_version=$(jq --version)
        log "jq installed successfully ($jq_version)"
    else
        log_error "jq installation failed"
        exit 1
    fi
}

# Display installation summary
display_summary() {
    log_section "INSTALLATION SUMMARY"
    
    echo -e "${GREEN}✓ System packages updated${NC}"
    
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        echo -e "${GREEN}✓ AWS CLI v2 (version: $aws_version)${NC}"
    else
        echo -e "${RED}✗ AWS CLI installation failed${NC}"
    fi
    
    if command -v java &> /dev/null; then
        local java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
        echo -e "${GREEN}✓ Java (version: $java_version)${NC}"
    else
        echo -e "${RED}✗ Java installation failed${NC}"
    fi
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "${GREEN}✓ Docker (version: $docker_version)${NC}"
    else
        echo -e "${RED}✗ Docker installation failed${NC}"
    fi
    
    if systemctl is-active --quiet jenkins; then
        echo -e "${GREEN}✓ Jenkins (service running)${NC}"
        echo -e "${GREEN}✓ Jenkins Docker permissions configured${NC}"
    else
        echo -e "${RED}✗ Jenkins installation failed${NC}"
    fi
    
    if command -v jq &> /dev/null; then
        local jq_version=$(jq --version)
        echo -e "${GREEN}✓ jq ($jq_version)${NC}"
    else
        echo -e "${RED}✗ jq installation failed${NC}"
    fi
    
    echo ""
    log "Installation completed!"
    log "Please log out and log back in to apply group changes"
    
    if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
        echo ""
        log_warning "Jenkins Initial Setup:"
        log_warning "1. Access Jenkins at: http://localhost:8080"
        log_warning "2. Use this command to get the initial admin password:"
        log_warning "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
}

# Main execution function
main() {
    log_section "UBUNTU DEVOPS TOOLS INSTALLATION"
    log "Starting installation process..."
    
    # Pre-flight checks
    check_root
    check_sudo
    check_ubuntu
    
    # Installation steps
    update_system
    install_aws_cli
    install_java21
    install_docker
    install_jenkins
    configure_jenkins_docker
    install_jq
    
    # Summary
    display_summary
    
    log "Script execution completed successfully!"
}

# Execute main function
main "$@"
