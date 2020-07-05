#!/bin/bash
docker buildx create --use --name gnuradio-build
docker buildx build \
  --push \
  --tag akfish/gnuradio-base:$1 \
  --platform linux/amd64,linux/arm,linux/arm64 \
  --build-args VERSION=$1 \
  .