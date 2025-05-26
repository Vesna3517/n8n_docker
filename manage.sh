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

# Function to check if a service is running
check_service() {
    local service=$1
    if docker ps | grep -q "$service"; then
        return 0
    else
        return 1
    fi
}

# Function to start services
start_services() {
    local service_type=$1
    
    case $service_type in
        "all")
            print_status "Starting all services..."
            docker-compose -f postgres.yml up -d
            docker-compose -f redis.yml up -d
            docker-compose -f n8n-server.yml up -d
            docker-compose up -d
            ;;
        "db")
            print_status "Starting database services..."
            docker-compose -f postgres.yml up -d
            docker-compose -f redis.yml up -d
            ;;
        "n8n")
            print_status "Starting N8N service..."
            docker-compose -f n8n-server.yml up -d
            ;;
        "traefik")
            print_status "Starting Traefik..."
            docker-compose up -d
            ;;
        *)
            print_error "Unknown service type: $service_type"
            exit 1
            ;;
    esac
}

# Function to stop services
stop_services() {
    local service_type=$1
    
    case $service_type in
        "all")
            print_status "Stopping all services..."
            docker-compose down
            docker-compose -f n8n-server.yml down
            docker-compose -f postgres.yml down
            docker-compose -f redis.yml down
            ;;
        "db")
            print_status "Stopping database services..."
            docker-compose -f postgres.yml down
            docker-compose -f redis.yml down
            ;;
        "n8n")
            print_status "Stopping N8N service..."
            docker-compose -f n8n-server.yml down
            ;;
        "traefik")
            print_status "Stopping Traefik..."
            docker-compose down
            ;;
        *)
            print_error "Unknown service type: $service_type"
            exit 1
            ;;
    esac
}

# Function to restart services
restart_services() {
    local service_type=$1
    stop_services "$service_type"
    start_services "$service_type"
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    echo "----------------------------------------"
    
    # Check Traefik
    if check_service "traefik"; then
        echo -e "Traefik: ${GREEN}Running${NC}"
    else
        echo -e "Traefik: ${RED}Stopped${NC}"
    fi
    
    # Check PostgreSQL
    if check_service "n8n-postgres"; then
        echo -e "PostgreSQL: ${GREEN}Running${NC}"
    else
        echo -e "PostgreSQL: ${RED}Stopped${NC}"
    fi
    
    # Check Redis
    if check_service "n8n-redis"; then
        echo -e "Redis: ${GREEN}Running${NC}"
    else
        echo -e "Redis: ${RED}Stopped${NC}"
    fi
    
    # Check N8N
    if check_service "n8n"; then
        echo -e "N8N: ${GREEN}Running${NC}"
    else
        echo -e "N8N: ${RED}Stopped${NC}"
    fi
}

# Function to show logs
show_logs() {
    local service_type=$1
    
    case $service_type in
        "all")
            docker-compose logs -f
            ;;
        "db")
            docker-compose -f postgres.yml logs -f
            docker-compose -f redis.yml logs -f
            ;;
        "n8n")
            docker-compose -f n8n-server.yml logs -f
            ;;
        "traefik")
            docker-compose logs -f
            ;;
        *)
            print_error "Unknown service type: $service_type"
            exit 1
            ;;
    esac
}

# Function to backup data
backup_data() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    print_status "Creating backup in $backup_dir"
    
    # Backup PostgreSQL
    docker exec n8n-postgres pg_dump -U n8n n8n > "$backup_dir/postgres_backup.sql"
    
    # Backup Redis
    docker exec n8n-redis redis-cli SAVE
    cp redis_data/dump.rdb "$backup_dir/redis_backup.rdb"
    
    # Backup configuration files
    cp *.env "$backup_dir/"
    cp *.yml "$backup_dir/"
    
    print_status "Backup completed successfully"
}

# Function to restore data
restore_data() {
    local backup_dir=$1
    
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory not found: $backup_dir"
        exit 1
    fi
    
    print_status "Restoring from backup: $backup_dir"
    
    # Restore PostgreSQL
    if [ -f "$backup_dir/postgres_backup.sql" ]; then
        docker exec -i n8n-postgres psql -U n8n n8n < "$backup_dir/postgres_backup.sql"
    fi
    
    # Restore Redis
    if [ -f "$backup_dir/redis_backup.rdb" ]; then
        cp "$backup_dir/redis_backup.rdb" redis_data/dump.rdb
    fi
    
    # Restore configuration files
    cp "$backup_dir"/*.env .
    cp "$backup_dir"/*.yml .
    
    print_status "Restore completed successfully"
}

# Main script
case "$1" in
    "start")
        start_services "$2"
        ;;
    "stop")
        stop_services "$2"
        ;;
    "restart")
        restart_services "$2"
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "backup")
        backup_data
        ;;
    "restore")
        restore_data "$2"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|backup|restore} [service_type]"
        echo "Service types: all, db, n8n, traefik"
        exit 1
        ;;
esac 