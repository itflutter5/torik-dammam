FROM node:20-alpine
WORKDIR /app
COPY server/package*.json ./
RUN npm install --omit=dev
COPY server/src ./src
EXPOSE 10000
CMD ["sh", "-c", "node src/migrate.js && node src/index.js"]
