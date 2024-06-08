# build stage
FROM node:16-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --production

COPY . .

# run stage
FROM node:16-alpine

WORKDIR /app
COPY --from=build /app /app
EXPOSE 3000
CMD ["node", "helloworld.js"]
