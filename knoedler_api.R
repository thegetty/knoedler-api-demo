library(randomForest)
library(tidyverse)

load("knoedler_models.rda")
ensemble_model <- map(all_model_iterations, "rf")

sample_data <- all_model_iterations[[1]]$train_data


produce_schema <- function(df) {
  df %>%
    imap(function(x, y) list(label = y, type = class(x))) %>%
    unname() %>%
    modify_if(map_lgl(., function(p) p[["type"]] == "factor"), function(x) c(x, list(values = levels(sample_data[[x[["label"]]]])))) %>%     modify_if(map_lgl(., function(p) p[["type"]] %in% c("numeric", "integer")), function(x) c(x, list(range = range(sample_data[[x[["label"]]]]))))
}

data_schema <- produce_schema(sample_data)

acceptable_names <- c("area", "orientation", "is_jointly_owned", "n_purchase_partners", "k_share", "genre", "is_firsttime_seller", "is_major_seller", "is_firsttime_buyer", "is_major_buyer", "is_old_master", "deflated_expense_amount", "purchase_seller_type", "artist_is_alive", "time_in_stock")

# Take basic string input and construct a data frame that matches the expected data for Knoedler
rectify_arguments <- function(a) {

  raw_df <- data.frame(list(...))

  stopifnot(all(sort(names(a)) == sort(acceptable_names)))

  a %>%
    mutate_at(vars(area, k_share, n_purchase_partners, deflated_expense_amount, time_in_stock), as.numeric) %>%
    mutate_at(vars(is_jointly_owned, is_firsttime_seller, is_major_seller, is_firsttime_buyer, is_major_buyer, is_old_master, artist_is_alive), funs(factor(as.logical(.), levels = c("TRUE", "FALSE")))) %>%
    mutate(
      orientation = factor(orientation, levels = c("portrait", "landscape", "square")),
      genre = factor(genre, levels = c("Landscape", "Genre", "History", "Portrait", "Still Life", "abstract")),
      purchase_seller_type = factor(purchase_seller_type, levels = c("Artist", "Museum", "Dealer", "Collector"))) %>%
    na_mode()
}

na_mode <- function(a, na_fun = na.roughfix) {
  a %>%
    bind_rows(original_data) %>%
    na_fun() %>%
    slice(1)
}

produce_prediction <- function(df) {
  preds <- map(ensemble_model, predict, newdata = df, type = "prob") %>%
    map_df(as.data.frame)

  preds %>%
    summarize_all(funs(low = quantile(., 0.05), med = quantile(., 0.50), hig = quantile(., 0.95)))
}

#* @serializer unboxedJSON
#* @get /predict
knoedler_predict <- function(...) {

  rectified_df <- rectify_arguments(...)

  produce_prediction(rectified_df)
}

#* @serializer unboxedJSON
#* @get /similar
knoedler_similar <- function(...) {

}

#* @serializer unboxedJSON
#* @get /arguments
knoedler_arguments <- function() {
  data_schema
}
