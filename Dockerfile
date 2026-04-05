# Usa a base oficial sem trava de hash para suportar arm64 nativamente
FROM debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS builder

ARG BUILD_FEATURES=""

# Instala as dependências de compilação
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    clang \
    libclang-dev \
    git \
    libssl-dev \
    pkg-config \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala o Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup default 1.81.0

WORKDIR /opt/app

# Baixa o código fonte oficial do Floresta mais recente na hora do build
RUN git clone https://github.com/getfloresta/floresta.git .

# Compila o projeto
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    if [ -n "$BUILD_FEATURES" ]; then \
    cargo build --release --features "$BUILD_FEATURES"; \
    else \
    cargo build --release; \
    fi

# Imagem final, limpa e multiplataforma
FROM debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016

COPY --from=builder /opt/app/target/release/florestad /usr/local/bin/florestad
COPY --from=builder /opt/app/target/release/floresta-cli /usr/local/bin/floresta-cli
RUN chmod +x /usr/local/bin/florestad

EXPOSE 50001
EXPOSE 8332
EXPOSE 3333

CMD [ "florestad" ]
