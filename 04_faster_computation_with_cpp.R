# Speeding up an EM algorithm with Rcpp
library(Rcpp)

# gaussian mixture modeling with EM
priorp <- 0.6
m1 <- 0
m2 <- 2.5
s1 <- 1
s2 <- 0.707

# generate some data with 2 classes
N <- 1000
cl <- rbinom(N, 1, priorp)
x <- cl*rnorm(N, m1, s1) + (1-cl)*rnorm(N, m2, s2)
plot(density(x))


# one iteration of EM algorithm
em_iter_r <- function(m, s, x) {
  N <- length(x)
  K <- length(m)
  
  # e-step
  d <- matrix(0.0, N, K)
  for (k in 1:K) {
    d[,k] <- dnorm(x, theta$m[k], theta$s[k])
  }
  postp <- t(apply(d, 1, function(x) x/sum(x)))
  
  # m-step
  for (k in 1:K) {
    m[k] <- weighted.mean(x, w = postp[,k])
    s[k] <- sqrt(weighted.mean((x - m[k])^2, w = postp[,k]))
  }
  
  return(list(m = m, s = s))
}

# run EM for 100 iterations
theta <- list(
  m = c(0, 2),
  s = c(0.5, 0.5)
)
for (i in 1:100) theta <- em_iter_r(theta$m, theta$s, x)
theta

# implementation in C++
cppFunction("
  void em_iter_cpp(NumericVector &mu, NumericVector &sigma, NumericVector &x) {
    const int N = x.length();
    const int K = mu.length();
    NumericMatrix post_prob(N, K);
    // e-step
    // density
    for (int k = 0; k < K; k++) {
      post_prob(_, k) = dnorm(x, mu[k], sigma[k]);
    }
    // normalize
    for (int n = 0; n < N; n++) {
      post_prob(n, _) = post_prob(n, _) / sum(post_prob(n, _));
    }
    // m-step
    for (int k = 0; k < K; k++) {
      NumericVector w = post_prob(_, k) / sum(post_prob(_, k));
      mu[k] = sum(x * w);
      sigma[k] = sqrt(sum((x - mu[k]) * (x - mu[k]) * w));
    }
  }
")

# cpp uses pass-by-reference, modifying m and s in-place
m <- c(0, 2)
s <- c(0.5, 0.5)
for (i in 1:100) em_iter_cpp(m, s, x)
list(m = m, s = s)


# compare speed
bench::mark(R = em_iter_r(m, s, x), Cpp = em_iter_cpp(m, s, x), check = FALSE)
