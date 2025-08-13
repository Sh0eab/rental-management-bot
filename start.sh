#!/bin/bash
echo "Starting Rasa server..."
exec rasa run --enable-api --cors "*" --port 5005 --host 0.0.0.0
