#  Implement a Recurrent Neural Network in R

This blog post is about how to implement a Recurrent Neural Network (RNN) in R.

RNNs are neural network for sequence data. Therefore it is suited for text data. 
Some applications of RNNs include machine translation, speech recognition and generation,
sentiment analysis, text prediction and generation.

We will step-by-step explore how to build a simple RNN in R.
First we'll need some data. We will use Obama speeches. The data set can be found on my Github repository:
[https://github.com/markdumke/Deep-Learning-Seminar/blob/master/data/obama.txt]

```r
fi   <- file("data/obama.txt", "r")
obama <- paste(readLines(fi), collapse="\n")
close(fi)
obama <- gsub(pattern = "\n", replacement = "", x = obama)
input <- strsplit(obama, NULL)[[1]][1:10000]  # use only first 10000 characters
input <- paste0(input, collapse = "")
```

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