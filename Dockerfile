FROM rasa/rasa:3.6.0-full

# Switch to root user to install system dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Switch back to rasa user
USER 1001

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies from requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Expose port
EXPOSE 5005

# Start the server
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005"]