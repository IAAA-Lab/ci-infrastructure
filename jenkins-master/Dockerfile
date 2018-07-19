FROM jenkins/jenkins:lts-alpine

RUN /usr/local/bin/install-plugins.sh \
  git \
  github \
  matrix-auth \
  workflow-aggregator \
  docker-workflow \
  blueocean \
  credentials-binding
