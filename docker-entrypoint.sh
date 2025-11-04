#!/bin/bash
set -e

echo "==> Starting Mydia development environment..."

# CRITICAL: Clean any host-compiled NIFs that are incompatible with container
if [ -d "_build/dev/lib/exqlite" ]; then
    echo "==> Cleaning exqlite build artifacts to prevent GLIBC issues..."
    rm -rf _build/dev/lib/exqlite
fi

# Check if build dependencies are installed
if ! command -v gcc &> /dev/null || ! command -v node &> /dev/null; then
    echo "==> Installing build dependencies (first-time setup)..."
    apt-get update -qq
    apt-get install -y -qq build-essential git inotify-tools curl > /dev/null 2>&1

    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
    echo "==> Build dependencies installed"
else
    echo "==> Build dependencies already installed, skipping..."
fi

# Install Hex and Rebar if not already installed
if [ ! -d "$MIX_HOME" ] || [ ! -f "$MIX_HOME/rebar" ]; then
    echo "==> Installing Hex and Rebar..."
    mix local.hex --force
    mix local.rebar --force
fi

# Install Mix dependencies (always run to ensure container-compatible deps)
echo "==> Installing Elixir dependencies..."
mix deps.get --only dev

# Compile exqlite if it's not already built (it was cleaned at startup)
if [ -d "deps/exqlite" ] && [ ! -f "_build/dev/lib/exqlite/priv/sqlite3_nif.so" ]; then
    echo "==> Compiling exqlite with container-compatible GLIBC..."
    mix deps.compile exqlite
fi

# Setup and migrate database
echo "==> Setting up database..."
mix ecto.create --quiet 2>/dev/null || echo "Database already exists"
mix ecto.migrate

# Install and build assets if not already built
if [ ! -d "assets/node_modules" ] || [ -z "$(ls -A assets/node_modules 2>/dev/null)" ]; then
    echo "==> Installing Node.js dependencies..."
    mix assets.setup
fi

if [ ! -d "priv/static/assets" ] || [ -z "$(ls -A priv/static/assets 2>/dev/null)" ]; then
    echo "==> Building assets..."
    mix assets.build
fi

echo "==> Starting Phoenix server..."
exec mix phx.server
