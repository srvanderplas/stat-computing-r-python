# At the top
ARG RENV_CACHE=/root/.local/share/renv
ARG PIP_CACHE=/root/.cache/pip

# Base image
FROM rocker/verse:latest

# Set environment variables so renv/pip use them
ENV RENV_PATHS_CACHE=${RENV_CACHE}
ENV PIP_CACHE_DIR=${PIP_CACHE}

# Install Python
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev\
    && rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev \
      libxmlsec1-dev libffi-dev liblzma-dev \
      libtesseract-dev libpoppler-cpp-dev tesseract-ocr \
      libleptonica-dev libpng-dev libjpeg-dev libtiff-dev imagemagick \
      gdal-bin libgdal-dev libsecret-1-dev \
      default-jdk openjdk-11-jdk \
      libglpk-dev libudunits2-dev \
      gnupg software-properties-common

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
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

# Environment variables
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/"
ENV PATH=/root/.pyenv/bin:$PATH
ENV VENV_PATH="/root/.virtualenvs/venv"
ENV REQ_FILE="/project/setup/requirements.txt"
ENV DEBIAN_FRONTEND=noninteractive

# Make sure these exist
# RUN mkdir -p ${RENV_CACHE} ${PIP_CACHE}

# Install tinytex system-wide (for LaTeX support)
RUN Rscript -e "install.packages('tinytex'); tinytex::install_tinytex(force=T)"

# Install minimal R packages for system-level support
RUN Rscript -e "install.packages(c('digest','devtools','renv','reticulate'))"

# Copy renv.lock and renv directory for layer caching, install R dependencies via renv
COPY renv.lock /project/renv.lock
COPY renv /project/renv
RUN R -e "renv::restore(lockfile = '/project/renv.lock', prompt = FALSE)"

# Copy Python requirements file if exists (cached separately)
COPY setup/requirements.txt ${REQ_FILE}
RUN python3 -m venv ${VENV_PATH} \
    source "${VENV_PATH}/bin/activate" \
    python3 -m pip install -r ${REQ_FILE}

# Copy the rest of the project
COPY . /project
WORKDIR /project

# Verify Environment
RUN Rscript -e "renv::status()" \
    Rscript -e "renv::diagnostics()" \
    Rscript -e "devtools::session_info()" \
    Rscript -e "reticulate::py_config()" \
    ls()

# Default command
CMD ["/bin/sh", "-c", "quarto render && quarto publish"]
