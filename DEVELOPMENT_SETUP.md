# 🚀 DEVELOPMENT SETUP GUIDE

## Prerequisites

- Docker & Docker Compose (v20.10+)
- Node.js 18+
- Python 3.11+
- Git

## Quick Start

### 1️⃣ Clone Repository
```bash
git clone https://github.com/miwae/stabs-platform.git
cd stabs-platform
git checkout develop
```

### 2️⃣ Setup Environment Variables
```bash
cp .env.example .env
```

Edit `.env`:
```
DB_PASSWORD=StabsSecure2026!
ENCRYPTION_KEY=your-encryption-key-here
JWT_SECRET=your-jwt-secret-here
```

### 3️⃣ Start Development Environment
```bash
docker-compose up -d
```

This starts:
- PostgreSQL database (port 5432)
- Python OCR service (port 5000)
- Node.js API (port 3000)
- Vue.js frontend (port 5173)
- Redis cache (port 6379)

### 4️⃣ Verify Services
```bash
# Check all services running
docker-compose ps

# Check API health
curl http://localhost:3000/health

# Check OCR service
curl http://localhost:5000/health

# View logs
docker-compose logs -f api
```

### 5️⃣ Access Applications

| Service | URL | Purpose |
|---------|-----|---------|
| **Frontend** | http://localhost:5173 | Vue.js UI |
| **API** | http://localhost:3000 | Express API |
| **OCR Service** | http://localhost:5000 | Python OCR |
| **Database** | localhost:5432 | PostgreSQL |

## Development Workflow

### Install Dependencies
```bash
# Node dependencies
npm install

# Python dependencies
pip install -r services/ocr/requirements.txt

# Tesseract (macOS)
brew install tesseract

# Tesseract (Ubuntu)
sudo apt-get install tesseract-ocr tesseract-ocr-deu
```

### Running Tests
```bash
# Node tests with coverage
npm test -- --coverage

# Python tests
pytest services/ocr/tests/ -v

# Run linting
npm run lint
```

### Git Workflow
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Make changes, commit, push
git add .
git commit -m "feat: description of changes"
git push origin feature/your-feature-name

# Create Pull Request on GitHub
# Target: develop branch
```

## Database Management

### Access PostgreSQL
```bash
# Connect to database
docker-compose exec postgres psql -U stabs_user -d stabs_ocr

# Common queries
\dt                    # List tables
\d documents          # Describe table
SELECT * FROM documents LIMIT 5;  # View data
```

### Database Migrations
```bash
# Apply migrations
npm run migrate

# Create new migration
npm run migrate:create migration_name

# Rollback
npm run migrate:rollback
```

## Troubleshooting

### Services won't start
```bash
# Check Docker daemon
docker --version

# Clean up and restart
docker-compose down -v
docker-compose up -d
```

### Database connection error
```bash
# Wait for postgres to be ready
docker-compose logs postgres

# Manually run init script
docker-compose exec postgres psql -U stabs_user -d stabs_ocr < services/database/init.sql
```

### Port already in use
```bash
# Find process using port
lsof -i :3000

# Change ports in docker-compose.yml and .env
```

## IDE Setup (VSCode)

### Extensions
- ESLint
- Prettier
- Python
- PostgreSQL
- REST Client

### Settings (.vscode/settings.json)
```json
{
  "editor.formatOnSave": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "ms-python.python"
  }
}
```

## Next Steps

- Read the [Sprints Documentation](../docs/04_IMPLEMENTATION_ROADMAP.md)
- Check [GitHub Issues](https://github.com/miwae/stabs-platform/issues) for tasks
- Review [Architecture](../docs/02_ID_DOCUMENT_OCR_SYSTEM.md)
- Join daily standup

## Questions?

- Check [README_PROJECT.md](../README_PROJECT.md)
- Review [docs/00_INDEX.md](../docs/00_INDEX.md)
- Create an issue on GitHub

🚀 **Happy coding!**
