FROM node:20-alpine

WORKDIR /app

# Copy package.json FIRST
COPY package.json .

# npm install (kein package-lock.json vorhanden)
RUN npm install

# Then copy everything else
COPY . .

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

EXPOSE 3000

CMD ["npm", "start"]
