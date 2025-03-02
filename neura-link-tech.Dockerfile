# neura-link.dockerfile
# Multi-architecture build for ARM/Raspberry Pi and x86_64

FROM --platform=$BUILDPLATFORM python:3.11-slim-bookworm as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    CAN_IFACE=can0 \
    NLT_AUTH_FILE=/etc/nlt_authorized.key \
    PYTHONUNBUFFERED=1

# Install core dependencies
RUN apt-get update && apt-get install -y \
    git \
    iproute2 \
    libsocketcan2 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN groupadd -r canusers && \
    useradd -r -g canusers -d /app -s /usr/sbin/nologin neurauser && \
    mkdir -p /app/{models,data} && \
    chown -R neurauser:canusers /app

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=neurauser:canusers . .

# Configure security permissions
RUN echo 'neurauser ALL=(root) NOPASSWD: /usr/sbin/ip link set can*' >> /etc/sudoers && \
    echo 'neurauser ALL=(root) NOPASSWD: /usr/sbin/ifconfig can*' >> /etc/sudoers

USER neurauser

# Health check and metrics endpoint
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -sf http://localhost:8080/health || exit 1

EXPOSE 8080
VOLUME ["/app/models", "/app/data", "/etc/nlt_authorized.key"]
CMD ["./entrypoint.sh"]