#!/bin/sh
set -e

# Start n8n FIRST (priority service)
echo "Starting n8n..."
n8n start &
N8N_PID=$!

# Wait for n8n to be ready
echo "Waiting for n8n to start..."
sleep 10

# Then start Ollama in background
echo "Starting Ollama in background..."
ollama serve > /dev/null 2>&1 &

# Pull model in background (don't wait)
sleep 2
ollama pull llama3.2:3b > /dev/null 2>&1 &

# Keep n8n in foreground
wait $N8N_PID
