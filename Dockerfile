ARG NODE_VERSION=18
ARG NODE_PRDUCTION_VERSION=${NODE_VERSION}

FROM node:${NODE_VERSION} AS builder
ENV NODE_ENV=production
WORKDIR /opt/app
COPY package.json package-lock.json ./
RUN npm ci && npm cache clean --force
COPY . .
RUN npm run build

FROM node:${NODE_VERSION} AS develop
ENV NODE_ENV=development
# hadolint ignore=DL3008
RUN apt-get update && apt-get install --no-install-recommends -y git gnupg2 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN git config --global gpg.program gpg2 \
  && [ -f ~/.bashrc ] && echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
WORKDIR /opt/app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# hadolint ignore=DL3006
FROM gcr.io/distroless/nodejs${NODE_PRDUCTION_VERSION}-debian11 AS production
ENV NODE_ENV=production
COPY --from=builder --chown=nonroot:nonroot /opt/app/dist /opt/app
WORKDIR /opt/app
USER nonroot
RUN npm ci && npm cache clean --force
CMD [ "index.js" ]
