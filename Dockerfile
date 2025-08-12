# At the top
ARG RENV_CACHE=/root/.local/share/renv
ARG PIP_CACHE=/root/.cache/pip

# Make sure these exist
RUN mkdir -p ${RENV_CACHE} ${PIP_CACHE}

# Set environment variables so renv/pip use them
ENV RENV_PATHS_CACHE=${RENV_CACHE}
ENV PIP_CACHE_DIR=${PIP_CACHE}

# Base image with R
FROM rocker/verse:latest

ENV DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/ \
    PATH=/root/.pyenv/bin:$PATH \
    PYENV_PATHS_ROOT=/root/.pyenv \
    PYENV_PATHS_VENV=/root/.virtualenvs/venv \
    PYENV_PATHS_RETICULATE=/root/.local/share/r-reticulate

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev \
      libxmlsec1-dev libffi-dev liblzma-dev \
      libtesseract-dev libpoppler-cpp-dev tesseract-ocr \
      libleptonica-dev libpng-dev libjpeg-dev libtiff-dev imagemagick \
      gdal-bin libgdal-dev libsecret-1-dev default-jdk openjdk-11-jdk \
      libglpk-dev libudunits2-dev python3 python3-venv python3-pip python3-dev \
      gnupg software-properties-common && \
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install Quarto CLI separately
RUN curl -fsSL https://quarto.org/download/latest/quarto-linux-amd64.deb -o quarto.deb && \
    apt-get update && apt-get install -y ./quarto.deb && \
    rm quarto.deb

# Install tinytex system-wide (for LaTeX support)
RUN Rscript -e "install.packages('tinytex'); tinytex::install_tinytex(force=T)"

# Install minimal R packages for system-level support
RUN Rscript -e "install.packages(c('digest','devtools','renv','reticulate'))"


# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh


WORKDIR /project

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
