```dockerfile
# Multi-stage build for production
ARG PYTHON_VERSION=3.11-slim-bookworm

# Builder stage
FROM python:${PYTHON_VERSION} as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:${PYTHON_VERSION}
WORKDIR /app

# Copy built packages
COPY --from=builder /root/.local /root/.local
COPY . .

# Environment variables
ENV PATH="/root/.local/bin:${PATH}"
ENV PYTHONPATH=/app
ENV CAN_INTERFACE=can0

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsocketcan2 \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Security hardening
RUN useradd -r -s /bin/false neuralink && \
    chown -R neuralink:neuralink /app

USER neuralink

CMD ["python", "-m", "neuralink.core"]
```
