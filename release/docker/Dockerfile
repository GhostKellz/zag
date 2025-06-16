FROM alpine:latest

# Install dependencies
RUN apk add --no-cache \
    curl \
    tar \
    git \
    wget \
    bash

# Install Zig from zigbuild
RUN wget https://github.com/marler8997/zigup/releases/download/v2023_04_02/zigup.linux.x64 -O /usr/local/bin/zigup && \
    chmod +x /usr/local/bin/zigup && \
    zigup 0.11.0 && \
    ln -s ~/.zig/zig-linux-x86_64-0.11.0/zig /usr/local/bin/zig && \
    zig version

# Set working directory
WORKDIR /app

# Copy the source code
COPY . .

# Build the zag binary
RUN cd /app && zig build -Doptimize=ReleaseSafe

# Add zag to path
ENV PATH="/app/zig-out/bin:${PATH}"

# Verify installation
RUN zag version

# Set entry point
ENTRYPOINT ["zag"]
CMD ["help"]