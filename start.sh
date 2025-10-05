#!/bin/sh
set -e

echo "Starting Ollama in background..."
ollama serve > /dev/null 2>&1 &
OLLAMA_PID=$!

echo "Waiting for Ollama to be ready..."
sleep 5

echo "Pulling llama3.2:3b model in background..."
ollama pull llama3.2:3b > /dev/null 2>&1 &

echo "Starting n8n..."
exec n8n start
