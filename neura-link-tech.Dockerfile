# neura-link-tech.Dockerfile
# Multi-platform Docker build for NeuraLinkTech Diagnostics

# Base image
FROM python:3.9-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    CAN_INTERFACE=can0 \
    PLATFORM_TYPE=auto

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    iproute2 \
    libglib2.0-0 \
    libgl1-mesa-glx \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Clone repository
RUN git clone https://github.com/MykeHaunt/NeuraLinkTech-AI-Vehicle-Diagnostics /app
WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    torch==1.13.1 \
    python-can==4.1.0 \
    RPi.GPIO==0.7.1 \
    cryptography==38.0.4

# Setup CAN interface (non-root operation)
RUN groupadd -r canusers && \
    useradd -r -g canusers neurauser && \
    chown -R neurauser:canusers /app

# Configure system permissions
RUN echo 'neurauser ALL=(ALL) NOPASSWD: /sbin/ip' >> /etc/sudoers && \
    echo 'neurauser ALL=(ALL) NOPASSWD: /sbin/ifconfig' >> /etc/sudoers

# Switch to non-root user
USER neurauser

# Entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Runtime configuration
EXPOSE 8080
VOLUME ["/app/models", "/app/data"]
CMD ["./entrypoint.sh"]