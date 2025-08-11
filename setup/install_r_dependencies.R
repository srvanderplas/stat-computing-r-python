if(!"renv" %in% installed.packages()) install.packages("renv", ask = F)

Sys.setenv(
  RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE",
  RENV_PATHS_RENV = "renv",
  RENV_PATHS_LOCKFILE = "renv.lock"
)
library(renv)

renv::restore()
