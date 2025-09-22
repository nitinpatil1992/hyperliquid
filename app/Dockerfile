FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID
ARG CHAIN=Testnet

ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc

RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.math.princeton.edu/pub/ubuntu/|g' /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y curl gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN mkdir -p /home/$USERNAME/hl/data \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

RUN echo "{\"chain\": \"$CHAIN\"}" > visor.json

RUN curl -o pub_key.asc $PUB_KEY_URL \
    && gpg --import pub_key.asc

RUN if [ "$CHAIN" = "Mainnet" ]; then \
      BINARY_URL="https://binaries.hyperliquid.xyz/Mainnet" && \
      HL_VISOR_URL="https://binaries.hyperliquid.xyz/Mainnet/hl-visor" && \
      HL_VISOR_ASC_URL="https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc" ; \
      
    else \
      BINARY_URL="https://binaries.hyperliquid-testnet.xyz/Testnet" && \
      HL_VISOR_URL="https://binaries.hyperliquid-testnet.xyz/$CHAIN/hl-visor" && \
      HL_VISOR_ASC_URL="https://binaries.hyperliquid-testnet.xyz/$CHAIN/hl-visor.asc" ; \
    fi && \
    echo "Downloading $BINARY_URL/hl-visor" && \
    curl -o hl-visor "$BINARY_URL/hl-visor" && \
    curl -o hl-visor.asc "$BINARY_URL/hl-visor.asc" && \
    gpg --verify hl-visor.asc hl-visor && \
    chmod +x hl-visor && \
    echo "Downloading $BINARY_URL/hl-node" && \
    curl -o hl-visor "$BINARY_URL/hl-node" && \


EXPOSE 4000-4010
EXPOSE 26656-26660

ENTRYPOINT ["./hl-visor", "run-non-validator", "--replica-cmds-style", "recent-actions"]
