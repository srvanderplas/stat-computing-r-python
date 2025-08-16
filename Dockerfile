FROM rocker/verse:4.5

ENV DEBIAN_FRONTEND=noninteractive
ENV RENV_PATHS_CACHE=/root/.local/share/renv
ENV PIP_CACHE_DIR=/root/.cache/pip
ENV JAVA_HOME=/usr/bin/java
ENV RETICULATE_PYTHON_ENV=venv

# --- Layer 1: OS deps (cacheable with BuildKit)
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv python3-dev \
      libcurl4-openssl-dev libssl-dev libxml2-dev \
      default-jdk default-jre r-cran-rjava unixodbc unixodbc-dev \
      libtesseract-dev libpoppler-cpp-dev tesseract-ocr \
      libleptonica-dev libpng-dev libjpeg-dev libtiff-dev \
      imagemagick gdal-bin libgdal-dev libsecret-1-dev \
      libglpk-dev libudunits2-dev \
      curl gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && install2.r --error --deps TRUE \
      RJDBC odbc tinytex quarto devtools rmarkdown rstudioapi reticulate yaml digest \\
    && Rscript -e "tinytex::install_tinytex(force=T)"

ENV JAVA_HOME=/usr/lib/jvm/default-java/
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${JAVA_HOME}/lib/server:${LD_LIBRARY_PATH}"

# Verify Java install
RUN java -version && javac -version

# --- Layer 2: GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# --- Layer 3: Quarto CLI
RUN curl -fsSL https://quarto.org/download/latest/quarto-linux-amd64.deb -o /tmp/quarto.deb && \
    apt-get update && apt-get install -y /tmp/quarto.deb && rm -f /tmp/quarto.deb && \
    rm -rf /var/lib/apt/lists/*

# --- Layer 4: Check cache dirs
# Ensure cache dirs exist
RUN mkdir -p ${RENV_PATHS_CACHE} ${PIP_CACHE_DIR} /root/.virtualenvs


WORKDIR /project

# Default command: render and publish
CMD ["/bin/sh","-c","quarto render && quarto publish"]
