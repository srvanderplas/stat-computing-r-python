# Build with docker buildx build -t book-image .

#### Stage 1: Linux, R, python, LaTeX, Java ####################################
FROM rocker/tidyverse:4.5 AS bookbase

ENV DEBIAN_FRONTEND=noninteractive
ENV RENV_PATHS_CACHE=/root/.local/share/renv
ENV PIP_CACHE_DIR=/root/.cache/pip
ENV RETICULATE_PYTHON_ENV=venv

# --- Layer 1: OS deps (cacheable with BuildKit) and GH CLI
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    # python
      python3 python3-pip python3-venv python3-dev \
    # curl/xml
      libcurl4-openssl-dev libssl-dev libxml2-dev  curl gnupg ca-certificates \
    # java
      default-jdk default-jre r-cran-rjava \
    # odbc
      unixodbc unixodbc-dev \
    # s2
      libabsl-dev cmake \
    # tesseract
      libtesseract-dev libpoppler-cpp-dev tesseract-ocr \
    # graphics
      libleptonica-dev libpng-dev libjpeg-dev libtiff-dev imagemagick \
    # gdal
      gdal-bin libgdal-dev \
    # secrets
      libsecret-1-dev \
    # units
      libglpk-dev libudunits2-dev \
    # R pkgs
    && install2.r --error --deps TRUE \
      RJDBC odbc devtools digest tinytex quarto rmarkdown yaml rstudioapi renv reticulate \
    # GH CLI
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    # Quarto CLI
    && curl -fsSL https://quarto.org/download/latest/quarto-linux-amd64.deb -o /tmp/quarto.deb \
    && apt-get update \
    && apt-get install -y  --no-install-recommends /tmp/quarto.deb \
    && rm -f /tmp/quarto.deb \
    && rm -rf /var/lib/apt/lists/* \
    # Tinytex
    && Rscript -e "tinytex::install_tinytex(force=T)" \
    # Ensure cache dirs exist
    && mkdir -p ${RENV_PATHS_CACHE} ${PIP_CACHE_DIR} /root/.virtualenvs


ENV JAVA_HOME=/usr/lib/jvm/default-java/
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${JAVA_HOME}/lib/server"

#### Stage 2: Python packages ##################################################
FROM bookbase AS bookpy

# Install python packages into venv
# Copy requirements from project root to tmp
COPY setup/requirements.txt /tmp/requirements.txt

# Add venv to path
ENV VENV_PATH=/opt/venv
# Register venv globally for R/reticulate and Quarto
ENV PATH="$VENV_PATH/bin:$PATH"
ENV RETICULATE_PYTHON=$VENV_PATH/bin/python
ENV QUARTO_PYTHON=$VENV_PATH/bin/python

#echo "=== Checking pip cache path ===" \
#    && ls -lah ${PIP_CACHE_DIR} || echo "pip cache dir not found" \
#    && echo "=== Restoring Python packages into baked-in venv ===" \

# Create venv
RUN python3 -m $RETICULATE_PYTHON_ENV $VENV_PATH \
    # Make sure pip is up to date and install common build tools
    && $VENV_PATH/bin/pip install --upgrade pip setuptools wheel ipykernel \
    && $VENV_PATH/bin/python -m ipykernel install --prefix=/usr/local --name=$RETICULATE_PYTHON_ENV --display-name "(${RETICULATE_PYTHON_ENV})" \
    && $VENV_PATH/bin/pip install --cache-dir ${PIP_CACHE_DIR} -r /tmp/requirements.txt

#### Stage 3: R packages #######################################################
FROM bookbase AS bookr

# Install R packages from renv cache
# Copy renv lockfile from project root to tmp
COPY renv.lock /tmp/renv.lock
COPY .Rprofile /tmp/.Rprofile
# install R packages
RUN Rscript -e "renv::restore(lockfile = '/tmp/renv.lock', prompt = FALSE)"

#echo "=== Checking renv cache path ===" \
#     && ls -lah ${RENV_PATHS_CACHE} || echo "renv cache dir not found" \
# # Check packages in cache
#     && echo "=== Package count in renv cache after restore ===" \
#     && Rscript -e \'cat(length(list.files(Sys.getenv("RENV_PATHS_CACHE"), recursive=TRUE)), "packages in cache\n")\'



#### Stage 4: R +  Py + Base ###################################################
FROM bookbase AS bookbuild

ENV JAVA_HOME=/usr/lib/jvm/default-java/
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${JAVA_HOME}/lib/server"
# Add venv to path
ENV VENV_PATH=/opt/venv
# Register venv globally for R/reticulate and Quarto
ENV PATH="$VENV_PATH/bin:$PATH"
ENV RETICULATE_PYTHON=$VENV_PATH/bin/python
ENV QUARTO_PYTHON=$VENV_PATH/bin/python

COPY --from=bookpy $VENV_PATH $VENV_PATH
COPY --from=bookpy $PIP_CACHE_DIR $PIP_CACHE_DIR
COPY --from=bookr $RENV_PATHS_CACHE $RENV_PATHS_CACHE
COPY renv.lock /tmp/renv.lock


WORKDIR /project

# Default command: render and publish
CMD ["/bin/sh","-c","quarto publish  --no-browser --no-prompt"]
