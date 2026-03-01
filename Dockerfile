# ----------- BUILD STAGE -----------
FROM mcr.microsoft.com/dotnet/sdk:6.0-jammy AS build
WORKDIR /src

# Install build dependencies (only for compiling)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake ninja-build build-essential pkg-config \
    libssl-dev libboost-all-dev libsodium-dev libzmq3-dev libgmp-dev \
  && rm -rf /var/lib/apt/lists/*

# Copy repo
COPY . .

# Publish Miningcore
WORKDIR /src/src/Miningcore
RUN dotnet restore
RUN dotnet publish -c Release -f net6.0 --no-restore -o /out

# ----------- RUNTIME STAGE -----------
# IMPORTANT: aspnet image includes Microsoft.AspNetCore.App (fixes your error)
FROM mcr.microsoft.com/dotnet/aspnet:6.0-jammy AS runtime
WORKDIR /app

# Install runtime dependencies (what Miningcore needs when running)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzmq5 libsodium23 libgmp10 ca-certificates tzdata \
  && rm -rf /var/lib/apt/lists/*

# ZMQ "liblibzmq" compatibility shim (fixes the exact error you saw)
RUN set -eux; \
    ZMQ_SO="$(ldconfig -p | awk '/libzmq\.so/{print $NF; exit}')" ; \
    echo "Detected libzmq: $ZMQ_SO"; \
    ln -sf "$ZMQ_SO" /usr/lib/x86_64-linux-gnu/liblibzmq.so; \
    ldconfig

# Copy built output
COPY --from=build /out/ /app/

# Default config path inside container
ENV MININGCORE_CONFIG=/app/config.json

# Miningcore listens on 4000 and stratum ports; you still map them with -p
#EXPOSE 4000 3333 3334 3335 3336 3600 3601 3602 3603

ENTRYPOINT ["/app/Miningcore"]
CMD ["-c", "/app/config.json"]

