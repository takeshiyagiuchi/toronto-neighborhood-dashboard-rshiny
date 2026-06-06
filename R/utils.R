normalize_vec <- function(vec) {
  denom <- max(vec) - min(vec)
  if (denom == 0) {
    if (max(vec) == 0) {
      return(vec)
    }
    return(vec / max(vec))
  }
  return ((vec - min(vec)) / denom)
}