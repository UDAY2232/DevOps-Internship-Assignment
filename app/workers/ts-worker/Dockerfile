FROM node:18-slim
WORKDIR /opt/ts-worker

COPY app/workers/ts-worker/package.json ./package.json
COPY app/workers/ts-worker/tsconfig.json ./tsconfig.json
COPY app/workers/ts-worker/index.ts ./index.ts

RUN npm install --production --silent

EXPOSE 9002

CMD ["npx", "ts-node", "index.ts"]
