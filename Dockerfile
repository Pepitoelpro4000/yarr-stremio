ARG NODE_VERSION=20.11.1
ARG PNPM_VERSION=8.15.4
ARG TS_VERSION=5.3.3

# Builder stage
FROM node:${NODE_VERSION} as build

WORKDIR /usr/src/app

RUN npm install -g typescript@${TS_VERSION}
RUN --mount=type=cache,target=/root/.npm \
    npm install -g pnpm@${PNPM_VERSION}

COPY package.json ./
COPY patches ./patches/

RUN pnpm install

COPY . .

RUN pnpm run build

# Runner stage
FROM node:${NODE_VERSION}-slim as final

COPY package.json .
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist

ENV NODE_ENV production
ENV HTTPS_METHOD local-ip.medicmobile.org
ENV DOWNLOAD_DIR /data
ENV KEEP_DOWNLOADED_FILES false
ENV MAX_CONNS_PER_TORRENT 50
ENV DOWNLOAD_SPEED_LIMIT 20971520
ENV UPLOAD_SPEED_LIMIT 1048576
ENV SEED_TIME 60000
ENV TORRENT_TIMEOUT 5000

VOLUME /data

RUN mkdir -p /data
RUN chown -R node /data

USER node

EXPOSE 58827
EXPOSE 58828

CMD npm start