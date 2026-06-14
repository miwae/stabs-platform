#!/bin/bash
# Stabs Platform Development Setup Script
# Usage: chmod +x setup.sh && ./setup.sh

set -e

echo "🚀 Stabs Platform Development Setup"
echo "====================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $2 not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ $2 installed${NC}"
}

check_command "docker" "Docker"
check_command "docker-compose" "Docker Compose"
check_command "git" "Git"
check_command "node" "Node.js"

# Clone/Pull repository
echo ""
echo -e "${YELLOW}📂 Setting up repository...${NC}"

if [ ! -d "stabs-platform" ]; then
    echo "Cloning repository..."
    git clone https://github.com/miwae/stabs-platform.git
    cd stabs-platform
    git checkout develop
else
    cd stabs-platform
    echo "Updating existing repository..."
    git pull origin develop
fi

# Create .env file if not exists
if [ ! -f ".env" ]; then
    echo -e "${CYAN}Creating .env file...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env with your configuration${NC}"
fi

# Start Docker Compose
echo ""
echo -e "${YELLOW}🐳 Starting Docker Compose...${NC}"
docker-compose up -d

# Wait for services
echo -e "${YELLOW}⏳ Waiting for services to be ready (30 seconds)...${NC}"
sleep 30

# Check services
echo ""
echo -e "${YELLOW}🔍 Checking services...${NC}"

check_service() {
    local name=$1
    local port=$2
    local url=$3
    
    if [ -z "$url" ]; then
        # Check port availability
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✅ $name is running (port $port)${NC}"
        else
            echo -e "${YELLOW}⚠️  $name not responding (port $port)${NC}"
        fi
    else
        # Check HTTP endpoint
        if curl -s -f $url &>/dev/null; then
            echo -e "${GREEN}✅ $name is running (port $port)${NC}"
        else
            echo -e "${YELLOW}⚠️  $name not responding (port $port)${NC}"
        fi
    fi
}

check_service "API" "3000" "http://localhost:3000/health"
check_service "OCR" "5000" "http://localhost:5000/health"
check_service "Frontend" "5173" "http://localhost:5173"
check_service "Database" "5432"
check_service "Redis" "6379"

# Install npm dependencies
echo ""
echo -e "${YELLOW}📦 Installing npm dependencies...${NC}"
npm install
echo -e "${GREEN}✅ npm dependencies installed${NC}"

# Create Tesseract note for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo -e "${YELLOW}🍎 macOS detected - Install Tesseract:${NC}"
    echo "   brew install tesseract"
fi

# Show next steps
echo ""
echo -e "${GREEN}✨ Setup complete!${NC}"
echo ""
echo -e "${CYAN}📝 Next steps:${NC}"
echo "  1. Edit .env with your configuration"
echo "  2. Access frontend: http://localhost:5173"
echo "  3. Run tests: npm test"
echo "  4. View logs: docker-compose logs -f api"
echo ""
echo -e "${CYAN}🚀 Start developing!${NC}"
