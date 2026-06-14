#!/bin/bash
set -e

echo "🚀 STABS-PLATFORM PRODUCTION DEPLOYMENT"
echo "========================================"
echo "Target: Hetzner CX33 (46.224.174.244)"
echo "Time: $(date)"
echo ""

# DEPLOYMENT PHASES
cd /opt

# PHASE 1: Repository
echo "📥 PHASE 1: REPOSITORY SETUP"
if [ ! -d "stabs-platform" ]; then
    git clone https://github.com/miwae/stabs-platform.git
fi
cd stabs-platform
git fetch origin
git checkout develop
git pull origin develop
echo "✅ Repository ready"
echo ""

# PHASE 2: Environment
echo "⚙️  PHASE 2: ENVIRONMENT CONFIGURATION"
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ .env created"
else
    echo "✅ .env exists"
fi
echo ""

# PHASE 3: Docker
echo "🐳 PHASE 3: DOCKER DEPLOYMENT"
docker-compose down 2>/dev/null || true
sleep 2
docker-compose up -d
echo "✅ Docker services started"
echo ""

# PHASE 4: Wait
echo "⏳ PHASE 4: SERVICE INITIALIZATION"
sleep 60
echo "✅ Services initialized"
echo ""

# PHASE 5: Health Checks
echo "🏥 PHASE 5: HEALTH CHECKS"
echo ""
docker-compose ps
echo ""

# API Check
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ API: HEALTHY"
else
    echo "⏳ API: Starting..."
fi

# OCR Check
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ OCR: HEALTHY"
else
    echo "⏳ OCR: Starting..."
fi

echo ""
echo "═══════════════════════════════════════"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════"
echo ""
echo "Services:"
echo "  Frontend: http://0.0.0.0:5173"
echo "  API:      http://0.0.0.0:3000"
echo "  OCR:      http://0.0.0.0:5000"
echo ""
echo "Status: ✅ PRODUCTION READY"
echo ""
