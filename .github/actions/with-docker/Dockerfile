ARG K_VERSION
FROM runtimeverificationinc/kframework-k:ubuntu-jammy-${K_VERSION}

ARG PYTHON_VERSION=3.10

RUN    apt-get -y update             \
    && apt-get -y install            \
         curl                        \
         graphviz                    \
         python${PYTHON_VERSION}     \
         python${PYTHON_VERSION}-dev \
         wget                        \
         pkg-config                  \
         libdbus-1-dev               \
         libudev-dev                 \
         libssl-dev                  \
    && apt-get -y clean

ARG USER_ID=9876
ARG GROUP_ID=9876
RUN    groupadd -g ${GROUP_ID} user \
    && useradd -m -u ${USER_ID} -s /bin/bash -g user user

USER user
WORKDIR /home/user

ENV PATH="/home/user/.local/bin:${PATH}"
ARG UV_VERSION
RUN curl -LsSf https://astral.sh/uv/$UV_VERSION/install.sh | sh && uv --version


ENV PATH="/home/user/.local/bin:/home/user/.cargo/bin:${PATH}"
RUN    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y \
    && rustup target add wasm32-unknown-unknown \
    && rustup target add wasm32v1-none

RUN cargo install --locked stellar-cli@23.1.4
