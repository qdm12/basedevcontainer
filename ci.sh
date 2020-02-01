#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" = "true" ]; then
  docker buildx build  \
    -f alpine.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    .
  [ -z $? ] || exit $?
  docker buildx build  \
    -f debian.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    .
  exit $?
fi
echo $DOCKER_PASSWORD | docker login -u qmcgaw --password-stdin &> /dev/null
LATEST_TAG="${TRAVIS_TAG:-latest}"
TAG_SUFFIX="${TRAVIS_TAG:-}"
echo "Building Docker images for \"$DOCKER_REPO:alpine-$TAG_SUFFIX\" and \"$DOCKER_REPO:$LATEST_TAG\""
docker buildx build \
    -f alpine.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg VCS_REF=`git rev-parse --short HEAD` \
    --build-arg VERSION=alpine-$TAG_SUFFIX \
    -t $DOCKER_REPO:$LATEST_TAG \
    -t $DOCKER_REPO:alpine-$TAG_SUFFIX \
    --push \
    .
echo "Building Docker images for \"$DOCKER_REPO:debian-$TAG_SUFFIX\""
docker buildx build \
    -f debian.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg VCS_REF=`git rev-parse --short HEAD` \
    --build-arg VERSION=debian-$TAG_SUFFIX \
    -t $DOCKER_REPO:debian-$TAG_SUFFIX \
    --push \
    .
