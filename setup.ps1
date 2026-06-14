# Stabs Platform Development Setup Script
# Run with: powershell -ExecutionPolicy Bypass -File setup.ps1

Write-Host "🚀 Stabs Platform Development Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`n📋 Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker --version | Out-Null
    Write-Host "✅ Docker installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not installed. Please install Docker Desktop" -ForegroundColor Red
    exit 1
}

# Check Git
try {
    git --version | Out-Null
    Write-Host "✅ Git installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not installed" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    node --version | Out-Null
    Write-Host "✅ Node.js installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not installed" -ForegroundColor Red
    exit 1
}

# Clone/Pull repository
Write-Host "`n📂 Setting up repository..." -ForegroundColor Yellow
if (-not (Test-Path "stabs-platform")) {
    Write-Host "Cloning repository..."
    git clone https://github.com/miwae/stabs-platform.git
    cd stabs-platform
    git checkout develop
} else {
    cd stabs-platform
    Write-Host "Updating existing repository..."
    git pull origin develop
}

# Create .env file if not exists
if (-not (Test-Path ".env")) {
    Write-Host "Creating .env file..." -ForegroundColor Cyan
    Copy-Item ".env.example" ".env"
    Write-Host "⚠️  Please edit .env with your configuration" -ForegroundColor Yellow
}

# Start Docker Compose
Write-Host "`n🐳 Starting Docker Compose..." -ForegroundColor Yellow
docker-compose up -d

# Wait for services
Write-Host "⏳ Waiting for services to be ready (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check services
Write-Host "`n🔍 Checking services..." -ForegroundColor Yellow

$services = @(
    @{Name="API"; Port=3000; Url="http://localhost:3000/health"},
    @{Name="OCR"; Port=5000; Url="http://localhost:5000/health"},
    @{Name="Frontend"; Port=5173; Url="http://localhost:5173"},
    @{Name="Database"; Port=5432; Url=$null},
    @{Name="Redis"; Port=6379; Url=$null}
)

foreach ($service in $services) {
    try {
        if ($service.Url) {
            $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 2 -ErrorAction Stop
            Write-Host "✅ $($service.Name) is running (port $($service.Port))" -ForegroundColor Green
        } else {
            # Check if port is open
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $service.Port)
            if ($tcpClient.Connected) {
                Write-Host "✅ $($service.Name) is running (port $($service.Port))" -ForegroundColor Green
                $tcpClient.Close()
            }
        }
    } catch {
        Write-Host "⚠️  $($service.Name) not responding (port $($service.Port))" -ForegroundColor Yellow
    }
}

# Install npm dependencies
Write-Host "`n📦 Installing npm dependencies..." -ForegroundColor Yellow
npm install
Write-Host "✅ npm dependencies installed" -ForegroundColor Green

# Show next steps
Write-Host "`n✨ Setup complete!" -ForegroundColor Green
Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit .env with your configuration"
Write-Host "  2. Access frontend: http://localhost:5173"
Write-Host "  3. Run tests: npm test"
Write-Host "  4. View logs: docker-compose logs -f api"
Write-Host "`n🚀 Start developing!" -ForegroundColor Cyan
