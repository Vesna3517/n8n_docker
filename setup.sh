#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker if not present
install_docker() {
    if ! command_exists docker; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    else
        print_status "Docker is already installed"
    fi
}

# Function to install Docker Compose if not present
install_docker_compose() {
    if ! command_exists docker-compose; then
        print_status "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        print_status "Docker Compose is already installed"
    fi
}

# Function to create required directories
create_directories() {
    local dirs=("postgres_data" "redis_data" "n8n_data" "letsencrypt" "auth" "dynamic")
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_status "Creating directory: $dir"
            mkdir -p "$dir"
        fi
    done
}

# Function to setup environment files
setup_env_files() {
    if [ ! -f "postgres.env" ]; then
        print_status "Creating postgres.env from example"
        cp postgres.env.example postgres.env
        chmod 600 postgres.env
    fi

    if [ ! -f "n8n.env" ]; then
        print_status "Creating n8n.env from example"
        cp n8n.env.example n8n.env
        chmod 600 n8n.env
    fi
}

# Function to generate secure passwords
generate_passwords() {
    local postgres_password=$(openssl rand -base64 32)
    local redis_password=$(openssl rand -base64 32)
    
    # Update postgres.env with new password
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$postgres_password/" postgres.env
    sed -i "s/POSTGRES_NON_ROOT_PASSWORD=.*/POSTGRES_NON_ROOT_PASSWORD=$postgres_password/" postgres.env
    
    print_status "Generated new secure passwords"
    print_warning "Please save these passwords securely"
}

# Function to setup Traefik basic auth
setup_traefik_auth() {
    if [ ! -f "auth/.htpasswd" ]; then
        print_status "Setting up Traefik basic auth"
        mkdir -p auth
        htpasswd -bc auth/.htpasswd admin $(openssl rand -base64 12)
        print_warning "Default Traefik credentials: admin / <generated-password>"
    fi
}

# Function to setup SSL certificates
setup_ssl() {
    if [ ! -d "letsencrypt" ]; then
        print_status "Setting up SSL certificates directory"
        mkdir -p letsencrypt
        chmod 700 letsencrypt
    fi
}

# Function to check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check memory
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 2048 ]; then
        print_warning "System has less than 2GB of RAM"
    fi
    
    # Check disk space
    local free_space=$(df -m . | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 10240 ]; then
        print_warning "Less than 10GB of free disk space"
    fi
}

# Function to setup firewall
setup_firewall() {
    if command_exists ufw; then
        print_status "Configuring firewall..."
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 5678/tcp
        ufw allow 5432/tcp
        ufw allow 6379/tcp
    fi
}

# Main installation process
main() {
    print_status "Starting installation process..."
    
    check_system
    install_docker
    install_docker_compose
    create_directories
    setup_env_files
    generate_passwords
    setup_traefik_auth
    setup_ssl
    setup_firewall
    
    print_status "Installation completed successfully!"
    print_warning "Please review and update the configuration files before starting the services"
    print_warning "Don't forget to save the generated passwords"
}

# Run main function
main 