# this dockerfile builds a container that can be used to run `yarn run watch` inside
FROM node:10.15.3-alpine as build-stage
RUN apk update && apk upgrade && \
    apk add --no-cache bash git python make g++

RUN yarn global add -D webpack webpack-dev-server webpack-cli webpack-merge

WORKDIR /app

EXPOSE 8300