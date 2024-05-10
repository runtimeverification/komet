ARG K_VERSION
FROM runtimeverificationinc/kframework-k:ubuntu-jammy-${K_VERSION}

ARG PYTHON_VERSION=3.10

RUN    apt-get -y update             \
    && apt-get -y install            \
         graphviz                    \
         python${PYTHON_VERSION}     \
         python${PYTHON_VERSION}-dev \
    && apt-get -y clean

ARG USER_ID=9876
ARG GROUP_ID=9876
RUN    groupadd -g ${GROUP_ID} user \
    && useradd -m -u ${USER_ID} -s /bin/bash -g user user

USER user
WORKDIR /home/user

ENV PATH=/home/user/.local/bin:${PATH}
RUN curl -sSL https://install.python-poetry.org | python3 -
