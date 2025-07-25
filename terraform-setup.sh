#!/bin/bash

set -euo pipefail

# Config
ENVIRONMENTS_DIR="environments"
AVAILABLE_ENVS=("dev" "qa" "uat" "alice-redax")
LOG_FILE="terraform-setup.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} $message" ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        INFO)    echo "[INFO] $message" ;;
        *)       echo "[$level] $message" ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Install and configure Docker
install_and_configure_docker() {
    if command -v docker >/dev/null 2>&1; then
        log INFO "Docker is already installed."
        return
    fi

    log INFO "Docker not found. Installing Docker on Amazon Linux 2..."
    sudo yum update -y
    sudo amazon-linux-extras enable docker
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user

    sleep 5

    if ! sudo systemctl is-active --quiet docker; then
        log ERROR "Docker service failed to start."
        sudo journalctl -u docker --no-pager | tail -n 20 >> "$LOG_FILE"
        exit 1
    fi

    if sudo docker version >/dev/null 2>&1 && sudo docker info >/dev/null 2>&1; then
        log SUCCESS "Docker installed and running (verified with sudo)."
        log WARN "Docker CLI will only work without sudo after logout/login due to group change."
    else
        log ERROR "Docker installed but not functional even with sudo."
        exit 1
    fi
}

# Check if Terraform is already installed
check_terraform() {
    if command -v terraform >/dev/null 2>&1; then
        local version
        version=$(terraform version | head -n1 | grep -o 'v[0-9.]*' | sed 's/v//')
        log INFO "Terraform is already installed. Version: $version"
        return 0
    else
        log WARN "Terraform not found."
        return 1
    fi
}

# Install Terraform if missing
install_terraform() {
    log INFO "Installing Terraform..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform
    log SUCCESS "Terraform installed."
}

# Validate environments directory
validate_environment_directory() {
    log INFO "Checking environments directory..."
    if [[ ! -d "$ENVIRONMENTS_DIR" ]]; then
        log ERROR "Directory '$ENVIRONMENTS_DIR' not found."
        exit 1
    fi
    log SUCCESS "Found environments directory."
}

# Prompt user for environment name
select_environment() {
    echo ""
    log INFO "Available environments: ${AVAILABLE_ENVS[*]}"
    echo ""

    while true; do
        read -p "Type the target environment (dev/qa/uat/alice-redax): " env_input

        if [[ "$env_input" =~ [A-Z] ]]; then
            log ERROR "Use lowercase only (dev, qa, uat, alice-redax)."
            continue
        fi

        for env in "${AVAILABLE_ENVS[@]}"; do
            if [[ "$env_input" == "$env" ]]; then
                selected_env="$env"
                log INFO "Selected environment: $selected_env"
                return 0
            fi
        done

        log ERROR "Invalid input. Choose one of: ${AVAILABLE_ENVS[*]}"
    done
}

# Manage Terraform workspace
manage_workspace() {
    local env=$1

    log INFO "Running 'terraform init' to initialize working directory..."
    if ! terraform init -input=false; then
        log ERROR "Terraform init failed."
        exit 1
    fi

    log INFO "Checking if workspace '$env' exists..."
    local ws_list
    ws_list=$(terraform workspace list)
    log INFO "Available workspaces:\n$ws_list"

    if echo "$ws_list" | grep -E "^[* ]+$env$" >/dev/null 2>&1; then
        log INFO "Workspace '$env' exists. Selecting..."
        if ! terraform workspace select "$env"; then
            log ERROR "Failed to select existing workspace '$env'."
            exit 1
        fi
    else
        log INFO "Workspace '$env' does not exist. Creating..."
        if ! terraform workspace new "$env"; then
            log ERROR "Failed to create new workspace '$env'."
            exit 1
        fi
    fi

    log INFO "Current workspace is: $(terraform workspace show)"
}

# Run Terraform plan
run_terraform_plan() {
    local env=$1
    local tfvars_file="$ENVIRONMENTS_DIR/${env}.tfvars"

    if [[ ! -f "$tfvars_file" ]]; then
        log ERROR "Missing variables file: $tfvars_file"
        exit 1
    fi

    echo ""
    echo "=========== TERRAFORM PLAN ==========="

    if terraform plan -var-file="$tfvars_file" -input=false; then
        log SUCCESS "Terraform plan successful."
        return 0
    else
        log ERROR "Terraform plan failed."
        tail -n 20 terraform.log 2>/dev/null || true
        return 1
    fi
}

# Run Terraform apply
run_terraform_apply() {
    local env=$1
    local tfvars_file="$ENVIRONMENTS_DIR/${env}.tfvars"

    echo ""
    echo "=========== TERRAFORM APPLY ==========="
    read -p "Apply Terraform changes to $env? (yes/no): " confirm
    if [[ "$confirm" == "yes" || "$confirm" == "y" ]]; then
        if terraform apply -var-file="$tfvars_file" -input=false; then
            log SUCCESS "Terraform apply completed."
            return 0
        else
            log ERROR "Terraform apply failed."
            tail -n 20 terraform.log 2>/dev/null || true
            return 1
        fi
    else
        log INFO "Terraform apply cancelled."
        return 0
    fi
}

# Main execution
main() {
    echo "Terraform Setup Script - $(date)" > "$LOG_FILE"
    log INFO "Starting setup on Amazon Linux 2..."

    install_and_configure_docker

    if ! check_terraform; then
        install_terraform
    fi

    if check_terraform; then
        log SUCCESS "Terraform is ready."
    else
        log ERROR "Terraform verification failed."
        exit 1
    fi

    validate_environment_directory
    select_environment
    manage_workspace "$selected_env"

    if run_terraform_plan "$selected_env"; then
        run_terraform_apply "$selected_env"
    else
        log ERROR "Aborting due to failed Terraform plan."
        exit 1
    fi

    log SUCCESS "Terraform setup completed successfully!"
    log INFO "Log saved to: $LOG_FILE"
}

trap 'log ERROR "Script interrupted."; exit 1' INT TERM
main
