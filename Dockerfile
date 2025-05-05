FROM ubuntu:22.04 AS megavul_base

LABEL authors="MegaVul" description="Out-of-the-box dependency environment for MegaVul" version="1.0"

ENV POETRY_VERSION=2.1.2 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Install dependencies in a single RUN command and clean up apt cache
RUN apt-get update && apt-get install -y \
    wget \
    curl  \
    build-essential  \
    cmake  \
    pkg-config  \
    libicu-dev  \
    zlib1g-dev  \
    libcurl4-openssl-dev  \
    libssl-dev  \
    ruby-dev  \
    ca-certificates  \
    gnupg  \
    git \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip3 install --no-cache-dir poetry==$POETRY_VERSION

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && npm -v \
    && npm install -g tree-sitter-cli@0.25.3

# Install github-linguist
RUN gem install github-linguist

# Install Java, Scala, and SBT using SDKMAN
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.6-amzn && sdk install scala 3.2.2 && sdk install sbt 1.9.9"
ENV PATH=/root/.sdkman/candidates/java/current/bin:$PATH
ENV PATH=/root/.sdkman/candidates/scala/current/bin:$PATH
ENV PATH=/root/.sdkman/candidates/sbt/current/bin:$PATH

# Verify installations (without conda)
RUN npm -v && java --version && scala --version && github-linguist --version && tree-sitter --version

# Copy project files
COPY environment.yml pyproject.toml megavul/ /MegaVul/

# Install dependencies with poetry
RUN echo poetry --version
RUN cd /MegaVul \
    && poetry install --no-root --without dev \
    && rm -rf $POETRY_CACHE_DIR \
    && cd -

# Set the working directory
WORKDIR /MegaVul
