## Make a dictionary
Each unique character will be represented as a number.

```r
make_dictionary <- function(x) {
  x_char <- strsplit(x, NULL)[[1]]
  characters <- unique(names(table(x_char)))
  dictionary <- data.frame(characters, seq(1, length(characters)))
  colnames(dictionary) <- c("characters", "integers")
  x_vec <- rep(NA, length(x_char))
  for(i in seq_along(x_vec)) {
    x_vec[i] <- which(dictionary$characters == x_char[i])
  }
  list(x_vec = x_vec, x_char = x_char, dict = dictionary)
}
```

More text...