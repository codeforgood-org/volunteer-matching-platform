# Deployment Guide

This guide covers deploying the VolunteerMatch platform to production.

## Prerequisites

- Docker and Docker Compose installed
- PostgreSQL with PostGIS extension
- Domain name configured
- SSL certificates (Let's Encrypt recommended)
- SMTP server for emails
- (Optional) AWS S3 for file uploads

## Environment Variables

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Edit the `.env` file with your production values:

```env
# Database
DATABASE_URL=postgresql://user:password@db/volunteer_match_prod
DATABASE_POOL_SIZE=10

# Phoenix
SECRET_KEY_BASE=<generate with: mix phx.gen.secret>
GUARDIAN_SECRET_KEY=<generate with: mix phx.gen.secret>
PHX_HOST=volunteermatch.org
PHX_PORT=4000

# Email
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
FROM_EMAIL=noreply@volunteermatch.org

# AWS S3 (optional)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_BUCKET=volunteer-match-uploads
AWS_REGION=us-east-1

# Sentry
SENTRY_DSN=your-sentry-dsn
```

## Docker Deployment

### 1. Build the Production Image

```bash
docker-compose -f docker-compose.prod.yml build
```

### 2. Run Database Migrations

```bash
docker-compose -f docker-compose.prod.yml run app bin/migrate
```

### 3. Start the Application

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Check Logs

```bash
docker-compose -f docker-compose.prod.yml logs -f app
```

## Manual Deployment (without Docker)

### 1. Install Dependencies

```bash
mix deps.get --only prod
cd assets && npm install && npm run deploy
```

### 2. Compile Assets

```bash
mix assets.deploy
```

### 3. Build Release

```bash
MIX_ENV=prod mix release
```

### 4. Run Migrations

```bash
_build/prod/rel/volunteer_match/bin/migrate
```

### 5. Start the Server

```bash
_build/prod/rel/volunteer_match/bin/server
```

## Nginx Configuration

Create `/etc/nginx/sites-available/volunteermatch`:

```nginx
upstream phoenix {
    server localhost:4000;
}

server {
    listen 80;
    server_name volunteermatch.org www.volunteermatch.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name volunteermatch.org www.volunteermatch.org;

    ssl_certificate /etc/letsencrypt/live/volunteermatch.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/volunteermatch.org/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /socket {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/volunteermatch /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL with Let's Encrypt

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d volunteermatch.org -d www.volunteermatch.org
```

## Database Backup

### Backup

```bash
pg_dump -h localhost -U postgres volunteer_match_prod > backup.sql
```

### Restore

```bash
psql -h localhost -U postgres volunteer_match_prod < backup.sql
```

## Monitoring

### Health Check Endpoint

The application exposes a health check at `/health`:

```bash
curl https://volunteermatch.org/health
```

### Log Aggregation

Logs are output to stdout/stderr and can be collected by:

- Docker logs: `docker-compose logs -f app`
- Systemd journal: `journalctl -u volunteermatch -f`
- File: Configure in `config/runtime.exs`

### Metrics

Phoenix LiveDashboard is available at `/dev/dashboard` (configure auth in production).

## Scaling

### Horizontal Scaling

Run multiple instances behind a load balancer:

```bash
docker-compose -f docker-compose.prod.yml up --scale app=3
```

Configure sticky sessions for LiveView:

```nginx
upstream phoenix {
    ip_hash;
    server app1:4000;
    server app2:4000;
    server app3:4000;
}
```

### Database Connection Pooling

Adjust `DATABASE_POOL_SIZE` based on:
- Number of app instances
- Expected concurrent users
- Database max connections

Rule of thumb: `pool_size = (max_connections / num_instances) - buffer`

## Maintenance

### Running Migrations

```bash
docker-compose -f docker-compose.prod.yml run app bin/migrate
```

### Database Seeding

```bash
docker-compose -f docker-compose.prod.yml run app bin/seed
```

### IEx Console

```bash
docker-compose -f docker-compose.prod.yml run app bin/remote
```

## Rollback

### Rollback Migration

```bash
docker-compose -f docker-compose.prod.yml run app bin/rollback
```

### Rollback Deployment

```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --no-deps --build app
```

## Troubleshooting

### Application won't start

Check logs:
```bash
docker-compose -f docker-compose.prod.yml logs app
```

Common issues:
- Missing environment variables
- Database not accessible
- Port already in use

### Database connection errors

- Verify DATABASE_URL is correct
- Check database is running: `docker-compose ps`
- Test connection: `psql $DATABASE_URL`

### High memory usage

- Check Oban queue sizes
- Review database query performance
- Monitor Phoenix LiveView connections

## Security Checklist

- [ ] SECRET_KEY_BASE is randomly generated (64+ chars)
- [ ] GUARDIAN_SECRET_KEY is randomly generated
- [ ] Database passwords are strong and unique
- [ ] SSL/TLS is enabled
- [ ] CORS is properly configured
- [ ] Rate limiting is enabled
- [ ] Admin dashboard is password protected
- [ ] Database backups are automated
- [ ] Firewall rules are configured
- [ ] Environment variables are not committed
- [ ] Dependencies are up to date
- [ ] Sentry or error tracking is configured

## Performance Optimization

### Database Indexes

All necessary indexes are created in migrations. Monitor slow queries:

```sql
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```

### Caching

Consider adding:
- Redis for session storage
- CDN for static assets
- Database query result caching

### Asset Optimization

Assets are automatically optimized in production:

```bash
mix assets.deploy
```

## Support

For deployment issues:
- Check logs first
- Review configuration
- Consult the troubleshooting section
- Open an issue on GitHub
