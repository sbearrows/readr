#' Write a data frame to a delimited file
#'
#' The `write_*()` family of functions are an improvement to analogous function such
#' as [write.csv()] because they are approximately twice as fast. Unlike [write.csv()],
#' these functions do not include row names as a column in the written file.
#' A generic function, `output_column()`, is applied to each variable
#' to coerce columns to suitable output.
#'
#' @section Output:
#' Factors are coerced to character. Doubles are formatted to a decimal string
#' using the grisu3 algorithm. `POSIXct` values are formatted as ISO8601 with a
#' UTC timezone *Note: `POSIXct` objects in local or non-UTC timezones will be
#' converted to UTC time before writing.*
#'
#' All columns are encoded as UTF-8. `write_excel_csv()` and `write_excel_csv2()` also include a
#' \href{https://en.wikipedia.org/wiki/Byte_order_mark}{UTF-8 Byte order mark}
#' which indicates to Excel the csv is UTF-8 encoded.
#'
#' `write_excel_csv2()` and `write_csv2` were created to allow users with
#' different locale settings to save .csv files using their default settings
#' (e.g. `;` as the column separator and `,` as the decimal separator).
#' This is common in some European countries.
#'
#' Values are only quoted if they contain a comma, quote or newline.
#'
#' The `write_*()` functions will automatically compress outputs if an appropriate extension is given.
#' Three extensions are currently supported: `.gz` for gzip compression, `.bz2` for bzip2 compression and
#' `.xz` for lzma compression.  See the examples for more information.
#'
#' @param x A data frame or tibble to write to disk.
#' @param file File or connection to write to.
#' @param append If `FALSE`, will overwrite existing file. If `TRUE`,
#'   will append to existing file. In both cases, if the file does not exist a new
#'   file is created.
#' @param col_names If `FALSE`, column names will not be included at the top of the file. If `TRUE`,
#' column names will be included. If not specified, `col_names` will take the opposite value given to `append`.
#' @param delim Delimiter used to separate values. Defaults to `" "` for `write_delim()`, `","` for `write_excel_csv()` and
#' `";"` for `write_excel_csv2()`. Must be a single character.
#' @param na String used for missing values. Defaults to NA. Missing values
#'   will never be quoted; strings with the same value as `na` will
#'   always be quoted.
#' @param quote_escape `r lifecycle::badge("deprecated")` Use the `escape`
#'   argument instead.
#' @param eol The end of line character to use. Most commonly either `"\n"` for
#'   Unix style newlines, or `"\r\n"` for Windows style newlines.
#' @param path `r lifecycle::badge("deprecated")` Use the `file` argument
#'   instead.
#' @return `write_*()` returns the input `x` invisibly.
#' @inheritParams vroom::vroom_write
#' @inheritParams read_delim
#' @references Florian Loitsch, Printing Floating-Point Numbers Quickly and
#' Accurately with Integers, PLDI '10,
#' <http://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf>
#' @export
#' @examples
#' \dontshow{
#' .old_wd <- setwd(tempdir())
#' }
#' # If only a file name is specified, write_()* will write
#' # the file to the current working directory.
#' write_csv(mtcars, "mtcars.csv")
#' write_tsv(mtcars, "mtcars.tsv")
#'
#' # If you add an extension to the file name, write_()* will
#' # automatically compress the output.
#' write_tsv(mtcars, "mtcars.tsv.gz")
#' write_tsv(mtcars, "mtcars.tsv.bz2")
#' write_tsv(mtcars, "mtcars.tsv.xz")
#' \dontshow{
#' setwd(.old_wd)
#' }
write_delim <- function(x, file, delim = " ", na = "NA", append = FALSE,
                        col_names = !append,
                        quote = c("needed", "all", "none"),
                        escape = c("double", "backslash", "none"),
                        eol = "\n",
                        num_threads = readr_threads(),
                        progress = show_progress(),
                        path = deprecated(),
                        quote_escape = deprecated()) {
  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_delim(path = )", "write_delim(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  stopifnot(is.data.frame(x))
  check_column_types(x)

  x_out <- x
  x[] <- lapply(x, output_column)
  if (edition_first()) {
    stream_delim(x, file,
      delim = delim, col_names = col_names, append = append,
      na = na, quote_escape = escape, eol = eol
    )
    return(invisible(x_out))
  }
  vroom::vroom_write(x, file,
    delim = delim, col_names = col_names, append = append,
    na = na, eol = eol, quote = quote, escape = escape, num_threads = num_threads,
    progress = progress
  )

  invisible(x_out)
}

#' @rdname write_delim
#' @export
write_csv <- function(x, file, na = "NA", append = FALSE, col_names = !append,
                      quote = c("needed", "all", "none"),
                      escape = c("double", "backslash", "none"),
                      eol = "\n",
                      num_threads = readr_threads(),
                      progress = show_progress(),
                      path = deprecated(),
                      quote_escape = deprecated()) {

  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_csv(path = )", "write_csv(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  write_delim(x, file,
    delim = ",", na = na, append = append,
    col_names = col_names, quote = quote, escape = escape, eol = eol, num_threads = num_threads,
    progress = progress
  )
}

#' @rdname write_delim
#' @export
write_csv2 <- function(x, file, na = "NA", append = FALSE, col_names = !append,
                       quote = c("needed", "all", "none"),
                       escape = c("double", "backslash", "none"),
                       eol = "\n",
                       num_threads = readr_threads(),
                       progress = show_progress(),
                       path = deprecated(),
                       quote_escape = deprecated()) {
  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_csv2(path = )", "write_csv2(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  x_out <- x
  x <- change_decimal_separator(x, decimal_mark = ",")
  write_delim(x, file,
    delim = ";", na = na, append = append,
    col_names = col_names, quote = quote, escape = escape, eol = eol, num_threads = num_threads,
    progress = progress
  )

  invisible(x_out)
}

#' @rdname write_delim
#' @export
write_excel_csv <- function(x, file, na = "NA", append = FALSE,
                            col_names = !append, delim = ",",
                            quote = "all",
                            escape = c("double", "backslash", "none"),
                            eol = "\n",
                            num_threads = readr_threads(),
                            progress = show_progress(),
                            path = deprecated(),
                            quote_escape = deprecated()) {
  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_excel_csv(path = )", "write_excel_csv(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  stopifnot(is.data.frame(x))
  check_column_types(x)

  x_out <- x
  datetime_cols <- vapply(x, inherits, logical(1), "POSIXt")
  x[datetime_cols] <- lapply(x[datetime_cols], format, "%Y/%m/%d %H:%M:%S")

  x[] <- lapply(x, output_column)
  if (edition_first()) {
    stream_delim(x, file, delim,
      col_names = col_names, append = append,
      na = na, bom = !append, quote_escape = escape, eol = eol
    )
    return(invisible(x_out))
  }
  vroom::vroom_write(x, file, delim,
    col_names = col_names, append = append,
    na = na, bom = !append,
    quote = quote, escape = escape,
    eol = eol, num_threads = num_threads,
    progress = progress
  )

  invisible(x_out)
}

#' @rdname write_delim
#' @export
write_excel_csv2 <- function(x, file, na = "NA", append = FALSE,
                             col_names = !append, delim = ";",
                             quote = "all",
                             escape = c("double", "backslash", "none"),
                             eol = "\n",
                             num_threads = readr_threads(),
                             progress = show_progress(),
                             path = deprecated(),
                             quote_escape = deprecated()) {
  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_excel_csv2(path = )", "write_excel_csv2(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  stopifnot(is.data.frame(x))
  check_column_types(x)

  x_out <- x
  x <- change_decimal_separator(x, decimal_mark = ",")

  datetime_cols <- vapply(x, inherits, logical(1), "POSIXt")
  x[datetime_cols] <- lapply(x[datetime_cols], format, "%Y/%m/%d %H:%M:%S")

  x[] <- lapply(x, output_column)
  write_excel_csv(x, file, na, append, col_names, delim,
    quote = quote,
    escape = escape,
    eol = eol, num_threads = num_threads,
    progress = progress
  )

  invisible(x_out)
}

#' @rdname write_delim
#' @export
write_tsv <- function(x, file, na = "NA", append = FALSE, col_names = !append,
                      quote = "none",
                      escape = c("double", "backslash", "none"),
                      eol = "\n",
                      num_threads = readr_threads(),
                      progress = show_progress(),
                      path = deprecated(),
                      quote_escape = deprecated()) {
  if (is_present(path)) {
    deprecate_warn("1.4.0", "write_tsv(path = )", "write_tsv(file = )")
    file <- path
  }

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }


  write_delim(x, file,
    delim = "\t", na = na, append = append,
    col_names = col_names, quote = quote, escape = escape, eol = eol,
    num_threads = num_threads, progress = progress
  )
}

#' Convert a data frame to a delimited string
#'
#' These functions are equivalent to [write_csv()] etc., but instead
#' of writing to disk, they return a string.
#'
#' @return A string.
#' @inheritSection write_delim Output
#' @inheritParams write_delim
#' @param x A data frame.
#' @inherit write_delim references
#' @examples
#' # format_()* functions are useful for testing and reprexes
#' cat(format_csv(mtcars))
#' cat(format_tsv(mtcars))
#' cat(format_delim(mtcars, ";"))
#'
#' # Specifying missing values
#' df <- data.frame(x = c(1, NA, 3))
#' format_csv(df, na = "missing")
#'
#' # Quotes are automatically added as needed
#' df <- data.frame(x = c("a ", '"', ",", "\n"))
#' cat(format_csv(df))
#' @export
format_delim <- function(x, delim, na = "NA", append = FALSE,
                         col_names = !append,
                         quote = c("needed", "all", "none"),
                         escape = c("double", "backslash", "none"),
                         eol = "\n",
                         quote_escape = deprecated()) {
  stopifnot(is.data.frame(x))
  check_column_types(x)

  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  x[] <- lapply(x, output_column)
  if (edition_first()) {
    res <- stream_delim(df = x, file = NULL, delim = delim, col_names = col_names, append = append, na = na, quote_escape = escape, eol = eol)
    Encoding(res) <- "UTF-8"
    return(res)
  }
  res <- vroom::vroom_format(x, delim = delim, eol = eol, col_names = col_names, na = na, quote = quote, escape = escape)
  Encoding(res) <- "UTF-8"
  res
}

#' @export
#' @rdname format_delim
format_csv <- function(x, na = "NA", append = FALSE, col_names = !append,
  quote = c("needed", "all", "none"),
  escape = c("double", "backslash", "none"),
  eol = "\n",
  quote_escape = deprecated()) {
  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  format_delim(x, delim = ",", na = na, append = append, col_names = col_names, eol = eol, quote = quote, escape = escape)
}

#' @export
#' @rdname format_delim
format_csv2 <- function(x, na = "NA", append = FALSE, col_names = !append,
  quote = c("needed", "all", "none"),
  escape = c("double", "backslash", "none"),
  eol = "\n",
  quote_escape = deprecated()) {
  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  x <- change_decimal_separator(x, decimal_mark = ",")
  format_delim(x, delim = ";", na = na, append = append, col_names = col_names, eol = eol, quote = quote, escape = escape)
}

#' @export
#' @rdname format_delim
format_tsv <- function(x, na = "NA", append = FALSE, col_names = !append,
  quote = c("needed", "all", "none"),
  escape = c("double", "backslash", "none"),
  eol = "\n",
  quote_escape = deprecated()) {
  if (is_present(quote_escape)) {
    deprecate_soft("2.0.0", "write_delim(quote_escape = )", "write_delim(escape = )")
    escape <- quote_escape
  }

  format_delim(x, delim = "\t", na = na, append = append, col_names = col_names, eol = eol, quote = quote, escape = escape)
}

#' Preprocess column for output
#'
#' This is a generic function that applied to each column before it is saved
#' to disk. It provides a hook for S3 classes that need special handling.
#'
#' @keywords internal
#' @param x A vector
#' @export
#' @examples
#' # Most columns are not altered, but POSIXct are converted to ISO8601.
#' x <- parse_datetime("2016-01-01")
#' str(output_column(x))
output_column <- function(x, name) {
  UseMethod("output_column")
}

#' @export
output_column.default <- function(x, name) {
  if (!is.object(x) || "AsIs" %in% class(x)) {
    return(x)
  }

  as.character(x)
}

#' @export
output_column.double <- function(x, name) {
  x
}

#' @export
output_column.POSIXt <- function(x, name) {
  format(x, "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC", justify = "none")
}

stream_delim <- function(df, file, append = FALSE, bom = FALSE, ..., quote_escape, eol) {
  quote_escape <- standardise_escape(quote_escape)

  file <- standardise_path(file, input = FALSE)

  if (is.null(file)) {
    out_file <- tempfile()
    con <- file(out_file, "wb")
    on.exit(
      {
        try(close(con), silent = TRUE)
        unlink(out_file)
      },
      add = TRUE
    )

    stream_delim_(df, con, ..., bom = bom, quote_escape = quote_escape, eol = eol)
    close(con)
    return(read_file(out_file))
  }

  if (inherits(file, "connection") && !isOpen(file)) {
    on.exit(close(file), add = TRUE)
    if (isTRUE(append)) {
      open(file, "ab")
    } else {
      open(file, "wb")
    }
  }
  stream_delim_(df, file, ..., bom = bom, quote_escape = quote_escape, eol = eol)
}

change_decimal_separator <- function(x, decimal_mark = ",") {
  stopifnot(is.data.frame(x))
  numeric_cols <- vapply(x, is.numeric, logical(1))

  format_seps <- function(x, decimal_mark) {
    nas <- is.na(x)
    x <- format(x, decimal.mark = decimal_mark, trim = TRUE, digits = 15)
    x[nas] <- NA_character_
    x
  }

  x[numeric_cols] <- lapply(x[numeric_cols], format_seps, decimal_mark)

  x
}

standardise_escape <- function(x) {
  if (identical(x, FALSE)) {
    x <- "none"
  }

  escape_types <- c("double" = 1L, "backslash" = 2L, "none" = 3L)
  escape <- match.arg(tolower(x), names(escape_types))

  escape_types[escape]
}

check_column_types <- function(x) {
  is_bad_column <- vapply(x, function(xx) !is.null(dim(xx)), logical(1))
  if (any(is_bad_column)) {
    cli_block(type = rlang::abort, {
      cli::cli_text("`x` must not contain list or matrix columns:")
      cli::cli_alert_danger("invalid columns at index(s): {paste0(which(is_bad_column), collapse = '\n')}")
    })
  }
}
