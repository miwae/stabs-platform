FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

# npm install statt npm ci (kein package-lock.json vorhanden)
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
