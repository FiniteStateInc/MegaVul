FROM ubuntu:22.04 AS megavul_base

LABEL authors="MegaVul" description="Out-of-the-box dependency environment for MegaVul" version="1.0"

RUN apt-get clean
RUN apt-get update && apt-get install -y  \
    wget  \
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
    curl  \
    gnupg  \
    git  \
    vim \
    python3.11 \
    libc6 \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && npm -v \
    && npm install -g tree-sitter-cli@0.25.3

# Install github-linguist
RUN gem install github-linguist

# Install miniconda
RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-aarch64.sh -b \
    && rm -f Miniconda3-latest-Linux-aarch64.sh

# Install SDKMAN for Java, Scala, and SBT
RUN curl -s "https://get.sdkman.io" | bash
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.6-amzn && sdk install scala 3.2.2 && sdk install sbt 1.9.9"
ENV PATH=/root/miniconda3/bin:$PATH
ENV PATH=/root/.sdkman/candidates/java/current/bin:$PATH
ENV PATH=/root/.sdkman/candidates/scala/current/bin:$PATH
ENV PATH=/root/.sdkman/candidates/sbt/current/bin:$PATH
RUN conda --version &&  npm -v && java --version && scala --version && github-linguist --version && tree-sitter --version

# Copy the source code and install dependencies
COPY . /MegaVul
WORKDIR /MegaVul
RUN conda env create -f environment.yml
RUN echo "source activate megavul" > ~/.bashrc
ENV PATH=/root/miniconda3/envs/megavul/bin:$PATH
RUN pip install -e .