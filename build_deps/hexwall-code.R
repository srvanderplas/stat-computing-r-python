# Dependencies
library(magick)
library(purrr)

# path:             The path to a folder of hexagon stickers
# sticker_row_size: The number of stickers in the longest row
# sticker_width:    The width of each sticker in pixels
# remove_small:     Should hexagons smaller than the sticker_width be removed?
# coords:           A data.frame of coordinates defining the placement of hexagons
# scale_coords:     Should the coordinates be scaled to the hexagon size?
# remove_size:      Should hexagons of an abnormal size be removed?
# sort_mode:        How should the files be sorted?
# background_color: The colour of the background canvas
# n_stickers:       The number of hexagons to produce. Recycled in file order.
hexwall <- function(path, sticker_row_size = 16, sticker_width = 500, remove_small = TRUE, total_stickers = NULL, remove_size = TRUE,
                    coords = NULL, scale_coords = TRUE, sort_mode = c("filename", "random", "color", "colour"),
                    background_color = "white", n_stickers = NULL){
  sort_mode <- match.arg(sort_mode)

  # Load stickers
  sticker_files <- list.files(path)
  if(is.null(n_stickers)) n_stickers <- length(sticker_files)
  sticker_files <- rep_len(sticker_files, n_stickers)
  stickers <- file.path(path, sticker_files) %>%
    map(function(path){
      switch(tools::file_ext(path),
             svg = image_read_svg(path),
             pdf = image_read_pdf(path),
             image_read(path))
    }) %>%
    map(image_transparent, "white") %>%
    map(image_trim) %>%
    set_names(sticker_files)

  # Low resolution stickers
  low_res <- stickers %>%
    map_lgl(~ remove_small && image_info(.x)$width < (sticker_width-1)/2 && image_info(.x)$format != "svg")
  which(low_res)

  stickers <- stickers %>%
    map(image_scale, sticker_width)

  # Incorrectly sized stickers
  bad_size <- stickers %>%
    map_lgl(~ remove_size && with(image_info(.x), height < (median(height)-2) | height > (median(height) + 2)))
  which(bad_size)

  # Remove bad stickers
  sticker_rm <- low_res | bad_size
  stickers <- stickers[!sticker_rm]

  if(any(sticker_rm)){
    message(sprintf("Automatically removed %i incompatible stickers: %s",
                    sum(sticker_rm), paste0(names(sticker_rm[sticker_rm]), collapse = ", ")))
  }

  if(is.null(total_stickers)){
    if(!is.null(coords)){
      total_stickers <- NROW(coords)
    }
    else{
      total_stickers <- length(stickers)
    }
  }

  # Coerce sticker sizes
  sticker_height <- stickers %>%
    map(image_info) %>%
    map_dbl("height") %>%
    median
  stickers <- stickers %>%
    map(image_resize, paste0(sticker_width, "x", sticker_height, "!"))

  # Repeat stickers sorted by file name
  stickers <- rep_len(stickers, total_stickers)

  if(sort_mode == "random"){
    # Randomly arrange stickers
    stickers <- sample(c(stickers, sample(stickers, total_stickers - length(stickers), replace = TRUE)))
  }
  else if(sort_mode %in% c("color", "colour")){
    # Sort stickers by colour
    sticker_col <- stickers %>%
      map(image_resize, "1x1!") %>%
      map(image_data) %>%
      map(~paste0("#", paste0(.[,,1], collapse=""))) %>%
      map(colorspace::hex2RGB) %>%
      map(as, "HSV") %>%
      map_dbl(~.@coords[,1]) %>%
      sort(index.return = TRUE) %>%
      .$ix

    stickers <- stickers[sticker_col]
  }

  if(is.null(coords)){
    # Arrange rows of stickers into images
    sticker_col_size <- ceiling(length(stickers)/(sticker_row_size-0.5))
    row_lens <- rep(c(sticker_row_size,sticker_row_size-1), length.out=sticker_col_size)
    row_lens[length(row_lens)] <- row_lens[length(row_lens)]  - (length(stickers) - sum(row_lens))
    sticker_rows <- map2(row_lens, cumsum(row_lens),
                         ~ seq(.y-.x+1, by = 1, length.out = .x)) %>%
      map(~ stickers[.x] %>%
            invoke(c, .) %>%
            image_append)

    # Add stickers to canvas
    canvas <- image_blank(sticker_row_size*sticker_width,
                          sticker_height + (sticker_col_size-1)*sticker_height/1.33526, "white")
    reduce2(sticker_rows, seq_along(sticker_rows),
            ~ image_composite(
              ..1, ..2,
              offset = paste0("+", ((..3-1)%%2)*sticker_width/2, "+", round((..3-1)*sticker_height/1.33526))
            ),
            .init = canvas)
  }
  else{
    sticker_pos <- coords
    if(scale_coords){
      sticker_pos <- sticker_pos %>%
        as_tibble %>%
        mutate_all(function(x){
          x <- x-min(x)
          dx <- diff(sort(abs(x)))
          x / min(dx[dx!=0])
        }) %>%
        mutate(y = y / min(diff(y)[diff(y)!=0])) %>%
        mutate(x = x*sticker_width/2,
               y = abs(y-max(y))*sticker_height/1.33526)
    }

    # Add stickers to canvas
    canvas <- image_blank(max(sticker_pos$x) + sticker_width,
                          max(sticker_pos$y) + sticker_height, background_color)
    reduce2(stickers, sticker_pos%>%split(1:NROW(.)),
            ~ image_composite(
              ..1, ..2,
              offset = paste0("+", ..3$x, "+", ..3$y)
            ),
            .init = canvas)
  }
}