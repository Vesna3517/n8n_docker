# N8N Distributed Setup

This repository contains a distributed setup for N8N workflow automation platform with PostgreSQL database and Redis queue management.

## Architecture

The setup consists of the following components:
- N8N servers (multiple instances for load balancing)
- PostgreSQL database for data storage
- Redis for queue management
- Traefik for load balancing and SSL termination

## Prerequisites

- Docker and Docker Compose installed on all servers
- Domain name with DNS access
- SSL certificate (handled by Traefik)
- Network access between servers

## Directory Structure

```
.
├── docker-compose.yml      # Main Traefik configuration
├── postgres.yml           # PostgreSQL service configuration
├── redis.yml             # Redis service configuration
├── n8n-server.yml        # N8N service configuration
├── .gitignore            # Git ignore rules
├── postgres.env          # PostgreSQL environment variables
├── postgres.env.example  # Example PostgreSQL environment
├── n8n.env              # N8N environment variables
├── n8n.env.example      # Example N8N environment
├── postgres_data/       # PostgreSQL data directory
├── redis_data/         # Redis data directory
└── n8n_data/          # N8N data directory
```

## Setup Instructions

### 1. Initial Setup

Clone the repository and create environment files:

```bash
# Clone the repository
git clone <repository-url>
cd <repository-directory>

# Make scripts executable
chmod +x setup.sh manage.sh

# Run setup script
sudo ./setup.sh
```

The setup script will:
- Install Docker and Docker Compose if not present
- Create required directories
- Generate secure passwords
- Setup Traefik authentication
- Configure SSL certificates
- Setup firewall rules

### 2. Service Management

Use the management script to control services:

```bash
# Start all services
./manage.sh start all

# Start specific service
./manage.sh start n8n
./manage.sh start db
./manage.sh start traefik

# Stop services
./manage.sh stop all
./manage.sh stop n8n

# Restart services
./manage.sh restart all
./manage.sh restart db

# Check service status
./manage.sh status

# View logs
./manage.sh logs all
./manage.sh logs n8n

# Backup data
./manage.sh backup

# Restore from backup
./manage.sh restore backups/20240101_120000
```

### 3. Database Server Setup

On the database server:

```bash
# Create required directories
mkdir -p postgres_data redis_data

# Edit environment files with secure passwords
nano postgres.env

# Start PostgreSQL and Redis
docker-compose -f postgres.yml up -d
docker-compose -f redis.yml up -d
```

### 4. N8N Server Setup

On each N8N server:

```bash
# Create required directory
mkdir -p n8n_data

# Edit environment file
nano n8n.env
# Update the following variables:
# - DB_POSTGRESDB_HOST: PostgreSQL server IP
# - QUEUE_BULL_REDIS_HOST: Redis server IP

# Start N8N
docker-compose -f n8n-server.yml up -d
```

### 4. Traefik Setup

On the main server:

```bash
# Create required directories
mkdir -p letsencrypt auth dynamic

# Start Traefik
docker-compose up -d
```

## Environment Variables

### PostgreSQL (.env)
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name
- `POSTGRES_NON_ROOT_USER`: Non-root user
- `POSTGRES_NON_ROOT_PASSWORD`: Non-root user password

### N8N (.env)
- `N8N_HOST`: N8N hostname
- `N8N_PORT`: N8N port
- `N8N_PROTOCOL`: Protocol (https)
- `WEBHOOK_URL`: Webhook URL
- `DB_TYPE`: Database type (postgresdb)
- `DB_POSTGRESDB_HOST`: PostgreSQL host
- `DB_POSTGRESDB_PORT`: PostgreSQL port
- `QUEUE_BULL_REDIS_HOST`: Redis host
- `QUEUE_BULL_REDIS_PORT`: Redis port

## N8N Servers Configuration

The `dynamic/n8n-servers.yml` file configures the load balancing and routing for N8N servers. Here's a detailed explanation of the configuration:

```yaml
http:
  services:
    n8n:
      loadBalancer:
        sticky:
          cookie:
            name: n8n_session
            secure: true
            httpOnly: true
            sameSite: strict
        healthCheck:
          path: /healthz
          interval: 30s
          timeout: 10s
          retries: 3
        servers:
          - url: "http://server1-ip:5678"
          - url: "http://server2-ip:5678"
```

### Configuration Components

1. **Load Balancer**:
   - Distributes traffic across multiple N8N servers
   - Supports dynamic server addition/removal
   - Health checks ensure only healthy servers receive traffic

2. **Sticky Sessions**:
   - Ensures user sessions stay on the same server
   - Cookie settings for security:
     - `secure`: Only sent over HTTPS
     - `httpOnly`: Not accessible via JavaScript
     - `sameSite`: Prevents CSRF attacks

3. **Health Checks**:
   - Regular monitoring of server health
   - Automatic removal of unhealthy servers
   - Configurable intervals and timeouts

4. **Server Configuration**:
   - Add new servers by adding entries to the `servers` list
   - Format: `http://server-ip:5678`
   - Each server must be accessible from Traefik

### Adding New Servers

To add a new N8N server to the load balancer:

1. Add the server to the configuration:
```yaml
servers:
  - url: "http://server1-ip:5678"
  - url: "http://server2-ip:5678"
  - url: "http://new-server-ip:5678"  # Add new server
```

2. Reload Traefik configuration:
```bash
docker-compose restart traefik
```

### Monitoring Server Health

1. **Check Server Status**:
```bash
# View Traefik dashboard
https://traefik.spectrumsys.pro

# Check server health directly
curl -f http://server-ip:5678/healthz
```

2. **View Server Logs**:
```bash
# Check Traefik logs
docker logs traefik

# Check specific N8N server logs
docker logs n8n
```

### Best Practices

1. **Server Configuration**:
   - Use internal IPs when possible
   - Ensure consistent port configuration
   - Monitor server resources

2. **Security**:
   - Keep server IPs private
   - Use secure network connections
   - Regular security updates

3. **Performance**:
   - Monitor server load
   - Balance server distribution
   - Regular health check reviews

## Security Considerations

1. **Passwords**:
   - Use strong, unique passwords
   - Change default passwords
   - Use different passwords for each environment

2. **Network Security**:
   - Restrict database access to N8N servers only
   - Use internal networks when possible
   - Enable SSL for all connections

3. **File Permissions**:
   - Secure .env files (chmod 600)
   - Protect data directories
   - Regular backups

## Maintenance

### Backup

```bash
# Backup PostgreSQL
docker exec n8n-postgres pg_dump -U n8n n8n > backup.sql

# Backup Redis
docker exec n8n-redis redis-cli SAVE
cp redis_data/dump.rdb backup.rdb
```

### Monitoring

- Check container status:
```bash
docker ps
docker logs n8n
docker logs n8n-postgres
docker logs n8n-redis
```

- Check Traefik dashboard:
  - Access: https://traefik.spectrumsys.pro
  - Default credentials in auth/.htpasswd

### Troubleshooting

1. **Database Connection Issues**:
   - Check PostgreSQL logs
   - Verify network connectivity
   - Check credentials in .env files

2. **N8N Issues**:
   - Check N8N logs
   - Verify Redis connection
   - Check database connection

3. **Traefik Issues**:
   - Check Traefik logs
   - Verify SSL certificates
   - Check routing rules

## Scaling

To add more N8N servers:

1. Copy n8n-server.yml and n8n.env to new server
2. Update n8n.env with correct database and Redis hosts
3. Start the new N8N instance
4. Update Traefik configuration if needed

## License

[Your License]

## Support

[Your Support Information] 