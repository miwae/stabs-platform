#!/bin/bash

#############################################################################
# STABS-PLATTFORM - VOLLSTÄNDIGES SETUP FÜR UBUNTU 26.04
# Einfach ausführen: bash setup-stabs.sh
#############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║                                                             ║"
echo "║      🎯 STABS-PLATTFORM - AUTOMATISCHES SETUP              ║"
echo "║                                                             ║"
echo "║      Multi-User Echtzeit-Einsatzleitung                    ║"
echo "║      (Open-Source Alternative zu CommandX)                 ║"
echo "║                                                             ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}⚠️  Muss als root laufen!${NC}"
   echo "Versuche: sudo bash setup-stabs.sh"
   exit 1
fi

echo -e "${BLUE}[1/10] System-Updates...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git build-essential

echo -e "${BLUE}[2/10] Docker installieren...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker root
systemctl start docker
systemctl enable docker

echo -e "${BLUE}[3/10] Docker Compose installieren...${NC}"
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo -e "${BLUE}[4/10] Nginx installieren...${NC}"
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx

echo -e "${BLUE}[5/10] Verzeichnisse erstellen...${NC}"
STABS_DIR="/home/stabs-platform"
mkdir -p "$STABS_DIR/api"
cd "$STABS_DIR"

echo -e "${BLUE}[6/10] Konfigurationsdateien erstellen...${NC}"

# .env
DB_PW=$(openssl rand -base64 24)
JWT_SEC=$(openssl rand -base64 32)

cat > .env << EOF
DB_PASSWORD=$DB_PW
JWT_SECRET=$JWT_SEC
NODE_ENV=production
PORT=3000
REDIS_URL=redis://redis:6379
DATABASE_URL=postgresql://stabs_user:$DB_PW@postgres:5432/stabs_db
EOF
chmod 600 .env

echo -e "${BLUE}[7/10] Docker Container starten...${NC}"
docker-compose up -d
sleep 20

echo -e "${BLUE}[8/10] Nginx konfigurieren...${NC}"
cat > /etc/nginx/sites-available/default << 'ENDFILE'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location /stabs/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    location / {
        return 404;
    }
}
ENDFILE

nginx -t > /dev/null 2>&1
systemctl reload nginx

echo -e "${BLUE}[9/10] Health Checks...${NC}"
sleep 10

docker-compose ps

echo -e "${BLUE}[10/10] Finalisieren...${NC}"

echo ""
echo -e "${GREEN}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ STABS-PLATTFORM INSTALLATION ERFOLGREICH!        ║${NC}"
echo -e "${GREEN}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 ZUGRIFF:${NC}    http://SERVER_IP/stabs/"
echo -e "${BLUE}🔐 LOGIN:${NC}      demo / demo123"
echo -e "${BLUE}📁 VERZEICHNIS:${NC} $STABS_DIR"
echo ""
echo -e "${GREEN}🚀 BEREIT!${NC}"
echo ""
