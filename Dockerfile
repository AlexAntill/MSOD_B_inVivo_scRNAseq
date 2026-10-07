FROM rocker/shiny:latest

# 1. Install system dependencies for bioinformatics, spatial data, and graphics
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    git \
    libxml2-dev \
    libmagick++-dev \
    libssl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libhdf5-dev \
    libgsl-dev \
    libgmp-dev \
    libglpk-dev \
    libcurl4-openssl-dev \
    libcairo2-dev \
    libxt-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libgeos-dev \
    libgdal-dev \
    libproj-dev \
    libv8-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Restore R packages
RUN Rscript -e 'install.packages("renv")'
COPY /renv.lock /srv/shiny-server/renv.lock

RUN Rscript -e '\
  options( \
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"), \
    renv.config.install.verbose = TRUE, \
    renv.config.test.packages = FALSE \
  ); \
  setwd("/srv/shiny-server/"); \
  renv::restore(); \
'

# 3. Copy app files
RUN rm -rf /srv/shiny-server/*
COPY /app/ /srv/shiny-server/

# 4. Configure permissions for SciLifeLab Serve non-root user (UID 999)
RUN if id shiny &>/dev/null && [ "$(id -u shiny)" -ne 999 ]; then \
        userdel -r shiny; \
        id -u 999 &>/dev/null && userdel -r "$(id -un 999)"; \
    fi; \
    useradd -u 999 -m -s /bin/bash shiny; \
    chown -R shiny:shiny /srv/shiny-server/ /var/lib/shiny-server/ /var/log/shiny-server/

USER shiny
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]