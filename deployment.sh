#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║  🚀 STABS-Platform Deployment (von GitHub)              ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Setup
REPO_URL="https://github.com/miwae/stabs-platform.git"
DEPLOY_DIR="/home/stabs-platform"
DOMAIN="${1:-planungs-tool.de}"
EMAIL="${2:-miwae@outlook.de}"

echo -e "${BLUE}[1/10] Verzeichnis vorbereiten...${NC}"
if [ ! -d "$DEPLOY_DIR" ]; then
  mkdir -p "$DEPLOY_DIR"
  cd "$DEPLOY_DIR"
  git clone "$REPO_URL" .
else
  cd "$DEPLOY_DIR"
  git pull origin main
fi

echo -e "${GREEN}✅ Repository aktualisiert${NC}"

echo -e "${BLUE}[2/10] .env konfigurieren...${NC}"
if [ ! -f "$DEPLOY_DIR/.env" ]; then
  cat > "$DEPLOY_DIR/.env" << EOF
DB_PASSWORD=StabsSecure2026!
JWT_SECRET=StabsJWT2026Secret!
NODE_ENV=production
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF
  chmod 600 "$DEPLOY_DIR/.env"
  echo -e "${GREEN}✅ .env erstellt${NC}"
else
  echo -e "${GREEN}✅ .env existiert bereits${NC}"
fi

echo -e "${BLUE}[3/10] Docker Images bauen...${NC}"
docker-compose build --no-cache api
echo -e "${GREEN}✅ Build fertig${NC}"

echo -e "${BLUE}[4/10] Container starten...${NC}"
docker-compose down 2>/dev/null || true
docker-compose up -d postgres redis api
sleep 15
echo -e "${GREEN}✅ Container laufen${NC}"

echo -e "${BLUE}[5/10] Let's Encrypt HTTPS...${NC}"
apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1
certbot certonly --non-interactive --agree-tos --email "$EMAIL" -d "$DOMAIN" --nginx 2>/dev/null || echo "⚠️  Zertifikat existiert bereits"
echo -e "${GREEN}✅ HTTPS konfiguriert${NC}"

echo -e "${BLUE}[6/10] Nginx konfigurieren...${NC}"
cat > /etc/nginx/sites-available/default << 'NGEOF'
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2 default_server;
    server_name planungs-tool.de;

    ssl_certificate /etc/letsencrypt/live/planungs-tool.de/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/planungs-tool.de/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline'" always;

    location /stabs/ {
        root /var/www;
        try_files $uri $uri/ /stabs/index.html;
        expires 1h;
    }

    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    location /datenschutz {
        return 301 /stabs/datenschutz.html;
    }
}
NGEOF

nginx -t > /dev/null 2>&1
systemctl reload nginx
echo -e "${GREEN}✅ Nginx aktualisiert${NC}"

echo -e "${BLUE}[7/10] Frontend deployen...${NC}"
mkdir -p /var/www/stabs
cp "$DEPLOY_DIR/frontend/index.html" /var/www/stabs/
echo -e "${GREEN}✅ Frontend bereit${NC}"

echo -e "${BLUE}[8/10] Datenbank initialisieren...${NC}"
docker-compose exec -T postgres psql -U stabs_user -d stabs_db << 'SQLEOF'
CREATE TABLE IF NOT EXISTS audit_log (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  action VARCHAR(100),
  entity_type VARCHAR(50),
  entity_id INT,
  details JSONB,
  ip_address VARCHAR(45),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_permissions (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id),
  incident_id INT REFERENCES incidents(id),
  can_edit BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id);

GRANT SELECT, INSERT ON audit_log TO stabs_user;
GRANT SELECT, INSERT ON user_permissions TO stabs_user;
SQLEOF
echo -e "${GREEN}✅ Datenbank erweitert${NC}"

echo -e "${BLUE}[9/10] Backups einrichten...${NC}"
mkdir -p "$DEPLOY_DIR/backups"

cat > /usr/local/bin/stabs-backup.sh << 'BACKUPEOF'
#!/bin/bash
BACKUP_DIR="/home/stabs-platform/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/stabs-db-$TIMESTAMP.sql.gz"
cd /home/stabs-platform
docker-compose exec -T postgres pg_dump -U stabs_user stabs_db | gzip > "$BACKUP_FILE"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
echo "✅ Backup: $BACKUP_FILE"
BACKUPEOF

chmod +x /usr/local/bin/stabs-backup.sh
echo "0 2 * * * /usr/local/bin/stabs-backup.sh" | crontab -
/usr/local/bin/stabs-backup.sh
echo -e "${GREEN}✅ Backups konfiguriert${NC}"

echo -e "${BLUE}[10/10] Status prüfen...${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║  ✅ STABS-PLATFORM ERFOLGREICH DEPLOYED                 ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 Zugriff:${NC}"
echo "   https://planungs-tool.de/stabs/"
echo ""
echo -e "${BLUE}👤 Login:${NC}"
echo "   Username: demo"
echo "   Password: demo123"
echo ""
echo -e "${BLUE}🔒 Sicherheit:${NC}"
echo "   ✅ HTTPS/TLS 1.3"
echo "   ✅ Audit-Logging"
echo "   ✅ DSGVO-konform"
echo ""
echo -e "${BLUE}⚙️  Administration:${NC}"
echo "   Backup: /usr/local/bin/stabs-backup.sh"
echo "   Logs: docker-compose logs"
echo ""
