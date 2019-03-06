# this dockerfile builds a container that can be used to run `yarn run watch` inside
FROM node:9.11.1-alpine as build-stage
RUN apk update && apk upgrade && \
    apk add --no-cache bash git python make g++

WORKDIR /app
COPY ./src .
RUN yarn global add -D  webpack webpack-dev-server webpack-cli webpack-merge

EXPOSE 8300

RUN yarn install && yarn dist && yarn 