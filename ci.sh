#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" = "true" ]; then
  docker buildx build  \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/armv7 \
    --platform=linux/armv8 \
    .
  exit $?
fi
echo $DOCKER_PASSWORD | docker login -u qmcgaw --password-stdin &> /dev/null
TAG="${TRAVIS_TAG:-latest}"
echo "Building Docker images for \"$DOCKER_REPO:$TAG\""
docker buildx build \
    --progress plain \
    --platform=linux/amd64 \
    --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg VCS_REF=`git rev-parse --short HEAD` \
    --build-arg VERSION=$TAG \
    -t $DOCKER_REPO:$TAG \
    --push \
    .
