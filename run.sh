#!/bin/bash

set -e

echo "Making sure all containers are down..."
podman compose down

echo "Building Quarkus application..."
cd quarkus-app
mvn clean package
cd ..

echo "Generating Apache certificates and OIDC configuration..."
cd apache
./generate-certs.sh
./generate-apache-config.sh
cd ..

echo "Building Apache container..."
podman compose build apache

echo "Building Quarkus container..."
podman compose build quarkus-app

echo "Build complete. Starting services..."
podman compose up -d