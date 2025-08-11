docker run --rm \
          -v /home/susan/Projects/Class/stat-computing-r-python:/project \
          -v /home/susan/Projects/Class/stat-computing-r-python/setup/renv:/project/renv \
          -v /home/susan/Projects/Class/stat-computing-r-python/setup/renv.lock:/project/renv.lock \
          -v ~/.local/share/renv:/root/.local/share/renv \
          -v ~/.cache/pip:/root/.cache/pip \
          local/quarto-reticulate:latest \
          Rscript -e "renv::diagnostics()" \
          Rscript -e "renv::status()" \
          Rscript -e "devtools::session_info()" \
          Rscript -e "reticulate::py_config()" \
          bash -c "
            cd /project && quarto render && quarto publish
          "
