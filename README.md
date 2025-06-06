# N8N Docker Setup with Traefik and Fail2ban

This repository contains a Docker Compose setup for running N8N with Traefik as a reverse proxy and Fail2ban for SSH protection.

## Prerequisites

- Docker
- Docker Compose
- Git

## Components

- **N8N**: Workflow automation platform
- **PostgreSQL**: Database for N8N
- **Redis**: For caching and queue management
- **Traefik**: Reverse proxy with automatic SSL
- **Fail2ban**: SSH brute force protection

## Configuration

### Environment Variables

1. Copy the example environment files:
```bash
cp .env.example .env
cp n8n-server.env.example n8n-server.env
cp postgres.env.example postgres.env
cp redis.env.example redis.env
```

2. Update the environment variables in each file with your settings.

### Traefik Configuration

1. Create required directories:
```bash
mkdir -p letsencrypt auth dynamic
```

2. Generate basic auth credentials for Traefik dashboard:
```bash
htpasswd -bc auth/.htpasswd admin your_password
```

### Fail2ban Configuration

Fail2ban is pre-configured to protect SSH with the following settings:
- 5 failed login attempts within 10 minutes
- 1 hour ban duration
- Local IPs (127.0.0.1 and ::1) are whitelisted

Configuration files are located in the `fail2ban` directory.

## Usage

### Management Script

Use the `manage.sh` script to control the services:

```bash
# Start all services
./manage.sh start all

# Start specific service
./manage.sh start [service_type]
# Available services: all, db, n8n, traefik, fail2ban

# Stop services
./manage.sh stop [service_type]

# Restart services
./manage.sh restart [service_type]

# Check status
./manage.sh status

# View logs
./manage.sh logs [service_type]

# Backup data
./manage.sh backup

# Restore from backup
./manage.sh restore [backup_directory]
```

### Accessing Services

- N8N: https://n8n.example.com
- Traefik Dashboard: https://traefik.example.com
- PostgreSQL: localhost:5432
- Redis: localhost:6379

## Security Features

### Traefik
- Automatic SSL with Let's Encrypt
- Basic authentication for dashboard
- Secure headers and redirects

### Fail2ban
- SSH brute force protection
- Automatic IP blocking
- Configurable ban duration and retry limits
- Real-time monitoring of banned IPs

## Backup and Restore

The setup includes automatic backup functionality for:
- PostgreSQL database
- Redis data
- Configuration files

Backups are stored in the `backups` directory with timestamps.

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   - Check Let's Encrypt logs
   - Verify domain DNS settings
   - Ensure ports 80 and 443 are accessible

2. **Database Connection Issues**
   - Verify PostgreSQL is running
   - Check database credentials
   - Ensure network connectivity

3. **Fail2ban Issues**
   - Check fail2ban logs: `./manage.sh logs fail2ban`
   - Verify SSH log path
   - Check iptables rules

### Logs

View logs for any service:
```bash
./manage.sh logs [service_type]
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 