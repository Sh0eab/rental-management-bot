#!/bin/bash

# Change to bot directory
cd bot2

# Train the model if no model exists or if training is needed
if [ ! -d "models" ] || [ -z "$(ls -A models)" ]; then
    echo "Training Rasa model..."
    rasa train
fi

# Start actions server in background
echo "Starting actions server..."
rasa run actions --port 5055 &

# Wait a moment for actions server to start
sleep 5

# Start main Rasa server
echo "Starting Rasa server..."
rasa run --enable-api --cors "*" --port 5005
