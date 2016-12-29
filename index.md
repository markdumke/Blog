#  Implement a Recurrent Neural Network in R

This blog post is about how to implement a Recurrent Neural Network (RNN) in R.

## What is an RNN?
RNNs are neural network for sequence data. Therefore it is suited for text data. 
Some applications of RNNs include machine translation, speech recognition and generation,
sentiment analysis, text prediction and generation.

## Implementation
### Data
We will step-by-step explore how to build a simple RNN in R.
First we'll need some data. We will use Obama speeches. The data set can be found on my Github repository:
[Obama speeches data](https://github.com/markdumke/Deep-Learning-Seminar/blob/master/data/obama.txt)

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

dict <- make_dictionary(input)
print(dict)
```

More text...

```r
#' represent characters as one-hot vector, one entry is 1, all other 0
#' @param x : integer vector, the sequence of symbols
#' @inheritParams train_rnn
#' @return a matrix, the input coded as one-hot vector
make_one_hot_coding <- function(x, n_vocab) {
  n_seq <- length(x)
  one_hot <- matrix(0, nrow = n_vocab, ncol = n_seq)
  one_hot[cbind(x, seq(1, n_seq))] <- 1
  one_hot
}

#' function returning training data (x, y)
#' output sequence is just input sequence shifted one in time
#' @param x: integer vector as specified by dict$x_vec
#' @inheritParams train_rnn
#' @param minibatch: #currently not implemented
#' @return a list with two entries: 
#' x and y, each either an integer vector or a matrix in one_hot_coding
make_train_data <- function(x, one_hot, n_vocab, minibatch) {

  x_train <- x[1:(length(x) - 1)]
  y <- x[2:length(x)] 
  
  if(one_hot == TRUE){
    x_train <- make_one_hot_coding(x_train, n_vocab)
    y <- make_one_hot_coding(y, n_vocab)
  }
  list(x = x_train, y = y)
}

# train <- make_train_data(x = dict$x_vec, one_hot = TRUE, n_vocab = nrow(dict$dict))
train <- make_train_data(x = dict$x_vec, one_hot = FALSE)
x <- train$x
y <- train$y
```
Now we have the training data. Note that the labels y are just x shifted one.


### Forward Propagation


```r
#' Conmpute softmax function
#' @param x: a numeric vector
softmax <- function(x) {
  exp(x) / sum(exp(x))
}

#' Forward Propagation, compute hidden state and output for each time step
#' multiplication with one-hot vector is equal to indexing with integer
#' @inheritParams train_rnn
#' @return list with hidden states h and output o
rnn_forward <- function(x, weights, n_hidden, n_vocab, one_hot) {
  U <- weights$U
  V <- weights$V
  W <- weights$W
  b <- weights$b
  c <- weights$c
  n_seq <- ifelse(is.matrix(x) == TRUE, ncol(x), length(x))
  h <- matrix(0, nrow = n_hidden, ncol = n_seq) 
  o <- matrix(0, nrow = n_vocab, ncol = n_seq)
  if(one_hot == TRUE){
    h[, 1] <- tanh(as.vector(U %*% x[, 1] + b)) # initialize h[, 0] = 0
    if(n_seq > 1){
      for(t in seq(2, n_seq)) {
        h[, t] <- tanh(W %*% h[, t - 1] + U %*% x[, t] + b)
        o[, t] <- softmax(V %*% h[, t] + c)
      }
    }
  } else{
    h[, 1] <- tanh(U[, x[1]] + b)
    if(n_seq > 1){
      for(t in seq(2, n_seq)) {
        h[, t] <- tanh(W %*% h[, t - 1] + U[, x[t]] + b)
        o[, t] <- softmax(V %*% h[, t] + c)
      }
    }
  }
  o[, 1] <- softmax(V %*% h[, 1] + c)

  list(h = h, o = o)
}
```


The code can be found here: [Github](https://github.com/markdumke/Deep-Learning-Seminar)
