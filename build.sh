#!/bin/bash

# Simple build script for Cloudflare Pages
echo "Building ClickMeter Dashboard..."

# Ensure public directory exists
mkdir -p public

# Copy index.html to public directory
cp index.html public/

# Copy any other static assets if they exist
if [ -d "assets" ]; then
    cp -r assets public/
fi

echo "Build complete! Files ready in public/ directory."
