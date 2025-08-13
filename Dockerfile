# Fast, sane base with R + tools
FROM rocker/verse:4.5

ENV DEBIAN_FRONTEND=noninteractive
# Default cache locations (can be overridden at runtime)
ENV RENV_PATHS_CACHE=/root/.local/share/renv \
    PIP_CACHE_DIR=/root/.cache/pip

# --- Layer 1: OS deps (cacheable)
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv python3-dev \
      libcurl4-openssl-dev libssl-dev libxml2-dev \
      libtesseract-dev libpoppler-cpp-dev tesseract-ocr \
      libleptonica-dev libpng-dev libjpeg-dev libtiff-dev \
      imagemagick gdal-bin libgdal-dev libsecret-1-dev \
      libglpk-dev libudunits2-dev \
      curl gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- Layer 2: GitHub CLI (optional)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# --- Layer 3: Quarto
RUN curl -fsSL https://quarto.org/download/latest/quarto-linux-amd64.deb -o /tmp/quarto.deb && \
    apt-get update && apt-get install -y /tmp/quarto.deb && rm -f /tmp/quarto.deb && \
    rm -rf /var/lib/apt/lists/*

# --- Layer 4: TinyTeX (LaTeX)
RUN Rscript -e "install.packages('tinytex', repos='https://cloud.r-project.org'); tinytex::install_tinytex()"

# Optional: a couple of helper R packages used during checks
RUN Rscript -e "install.packages(c('digest'), repos='https://cloud.r-project.org')"

# Ensure cache dirs always exist (first-run safe)
RUN mkdir -p ${RENV_PATHS_CACHE} ${PIP_CACHE_DIR} /root/.virtualenvs

WORKDIR /project

# Default command: render then publish
CMD ["/bin/sh","-c","quarto render && quarto publish"]
