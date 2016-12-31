---
layout: default
comments: true
title: Implement a Recurrent Neural Network in R
date: <%= Time.now.strftime('%Y-%m-%d %H:%M:%S %z') %>
---

This blog post is about how to implement a Recurrent Neural Network (RNN) in R.

## What is an RNN?
An RNN is a neural network for sequential data. Therefore it is suited for text data. 
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
#' split input into characters and give each character an unique integer id
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
make_one_hot_coding <- function(x, n_vocab) {
  n_seq <- length(x)
  one_hot <- matrix(0, nrow = n_vocab, ncol = n_seq)
  one_hot[cbind(x, seq(1, n_seq))] <- 1
  one_hot
}

#' function returning training data (x, y)
#' output sequence is just input sequence shifted one in time
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

Next we need to initialize all weights to small random numbers.

```r
#' Initialize weights to small random numbers
intialize_weights <- function(seed, n_hidden, n_vocab) {
  set.seed(seed)
  U <- matrix(runif(n_hidden * n_vocab, - 0.1, 0.1), ncol = n_vocab)
  V <- matrix(runif(n_hidden * n_vocab, - 0.1, 0.1), ncol = n_hidden)
  W <- matrix(runif(n_hidden * n_hidden, - 0.1, 0.1), ncol = n_hidden)
  b <- runif(n_hidden, - 0.1, 0.1)
  c <- runif(n_vocab, - 0.1, 0.1)
  list(U = U, V = V, W = W, b = b, c = c)
}

weights <- intialize_weights(seed = 281116, n_hidden = 10, n_vocab = nrow(dict$dict))
```


### Forward Propagation


```r
#' Compute softmax function
softmax <- function(x) {
  exp(x) / sum(exp(x))
}

#' Forward Propagation, compute hidden state and output for each time step
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
## Backpropagation
Now we have to compute the gradients with respect to all parameters.

```r
#' Computing gradients
calculate_gradients <- function(o, h, x, y, weights, one_hot, n_vocab) {
  n_hidden <- nrow(h)
  n_seq <- ifelse(is.matrix(x) == TRUE, ncol(x), length(x))
  V <- weights$V
  W <- weights$W
  
  if(one_hot == TRUE){
    grad_o <- o - y
  } else {
    grad_o <- o
    ind <- matrix(c(y, seq_along(y)), ncol = 2)
    grad_o[ind] <- grad_o[ind] - 1
  }
  
  grad_c <- rep(0, n_vocab)
  grad_b <- rep(0, n_hidden)
  grad_W <- matrix(0, nrow = n_hidden, ncol = n_hidden)
  grad_V <- matrix(0, nrow = n_vocab, ncol = n_hidden)
  grad_U <- matrix(0, nrow = n_hidden, ncol = n_vocab)
  grad_h <- matrix(0, nrow = n_hidden, ncol = n_seq)
  grad_h[, n_seq] <- t(V) %*% grad_o[, n_seq]
    
  for(t in seq((n_seq - 1), 1)) {
    grad_h[, t] <- t(W) %*% grad_h[, t + 1] * (1 - h[, t + 1]^2) + t(V) %*% grad_o[, t]
  }
  
  if(n_seq > 1){
    for(t in seq(n_seq, 1)) {
      grad_U <- grad_U # + diag(1 - h[, t]^2) %*% grad_h[, t] %*% t(x[, t])
      grad_V <- grad_V + grad_o[, t] %*% t(h[, t])
      grad_b <- grad_b # + diag(1 - h[, t]^2) %*% grad_h[, t]
      grad_c <- grad_c + grad_o[, t]
    }  
    for(t in seq(n_seq, 2)) {
    grad_W <- grad_W + diag(1 - h[, t]^2) %*% grad_h[, t] %*% t(h[, t - 1]) # false?, loss not decreasing
    }
  }
  
  list(U = grad_U, V = grad_V, W = grad_W, b = grad_b, c = grad_c)
}

#' Cross entropy loss for multinoulli distribution
loss <- function(o, y, one_hot, n_vocab) {
  if(one_hot == FALSE){
    y <- make_one_hot_coding(y, n_vocab)
  }
  - 1 / ncol(o) * sum(diag(t(y) %*% log(o)))
}

# Gradient Descent update
sgd_update <- function(learning_rate, weights, gradients) {
  weights$U <- weights$U - learning_rate * gradients$U
  weights$V <- weights$V - learning_rate * gradients$V
  weights$W <- weights$W - learning_rate * gradients$W
  weights$b <- weights$b - learning_rate * gradients$b
  weights$c <- weights$c - learning_rate * gradients$c
  weights
}

#' Back propagation through time
rnn_backward <- function(learning_rate, o, h, x, y, weights, one_hot, n_vocab) {
  loss <- loss(o, y, one_hot, n_vocab)
  gradients <- calculate_gradients(o, h, x, y, weights, one_hot, n_vocab)
  
  weights <- sgd_update(learning_rate, weights, gradients)
  list(loss = loss, weights = weights)
}
```
The code can be found here: [Github](https://github.com/markdumke/Deep-Learning-Seminar)

<hr>
# More posts:
[Recurrent Neural Network architectures](https://markdumke.github.io/2016/12/29/recurrent-neural-network-architectures.html)

{% include disqus.html %}
