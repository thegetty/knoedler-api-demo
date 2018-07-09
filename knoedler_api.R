library(randomForest)
library(dplyr)
library(purrr)
library(dummies)
library(distances)

load("knoedler_models.rda")
ensemble_model <- map(all_model_iterations, "rf")

sample_data <- distinct(map_df(all_model_iterations, "train_x"))

dummy_data <- dummy.data.frame(as.data.frame(sample_data), sep = "_", drop = FALSE) %>% data.matrix()

range_list <- function(x, ...) {
  r <- range(x, ...)

  list(
    min = r[1],
    max = r[2]
  )
}

produce_schema <- function(df) {
  df %>%
    imap(function(x, y) list(label = y, type = class(x))) %>%
    unname() %>%
    modify_if(map_lgl(., function(p) p[["type"]] == "factor"), function(x) c(x, list(values = levels(sample_data[[x[["label"]]]])))) %>%     modify_if(map_lgl(., function(p) p[["type"]] %in% c("numeric", "integer")), function(x) c(x, list(range = range_list(sample_data[[x[["label"]]]]))))
}

data_schema <- produce_schema(sample_data)
acceptable_names <- names(sample_data)

na_mode <- function(a, na_fun = na.roughfix) {
  a %>%
    bind_rows(sample_data) %>%
    na_fun() %>%
    slice(1)
}

# Take basic string input and construct a data frame that matches the expected data for Knoedler
rectify_arguments <- function(a) {

  raw_df <- as_tibble(a)

  missing_args <- setdiff(acceptable_names, names(raw_df))
  surplus_args <- setdiff(names(raw_df), acceptable_names)

  if (length(missing_args) > 0 | length(surplus_args > 0))
      stop("Missing arguments: ", paste0("'", missing_args, "'", collapse = ", "), "\\nUnused arguments: ", paste0("'", surplus_args, "'", collapse = ", "))

  res <- raw_df %>%
    mutate_at(vars(area, k_share, n_purchase_partners, deflated_expense_amount, time_in_stock), as.numeric) %>%
    mutate_at(vars(is_jointly_owned, is_firsttime_seller, is_major_seller, is_firsttime_buyer, is_major_buyer, is_old_master, artist_is_alive), funs(factor(as.logical(.), levels = c("TRUE", "FALSE")))) %>%
    mutate(
      orientation = factor(orientation, levels = c("portrait", "landscape", "square")),
      genre = factor(genre, levels = c("Landscape", "Genre", "History", "Portrait", "Still Life", "abstract")),
      purchase_seller_type = factor(purchase_seller_type, levels = c("Artist", "Museum", "Dealer", "Collector")))

  res
}

produce_prediction <- function(df) {
  map(ensemble_model, predict, newdata = df, type = "prob") %>%
    map_df(as.data.frame) %>%
    summarize_all(funs(low = quantile(., 0.05), med = quantile(., 0.50), hig = quantile(., 0.95)))
}

#* @serializer unboxedJSON
#* @get /predict
function(res, req, ...) {
  raw_args <- list(...)
  rectified_df <- rectify_arguments(raw_args)
  produce_prediction(rectified_df)
}

produce_similar <- function(df) {
  input_dummy <- dummy.data.frame(as.data.frame(df), sep = "_", drop = FALSE) %>% data.matrix()

  combined_info <- rbind(dummy_data, input_dummy)
  new_index <- nrow(dummy_data) + 1

  norm_dist <- distances(combined_info)
  ref_distances <- nearest_neighbor_search(norm_dist, k = 6, query_indices = new_index, search_indices = seq_len(nrow(dummy_data)))[,1]

  ref_distances
}

#* @serializer unboxedJSON
#* @get /similar
function(res, req, ...) {
  raw_args <- list(...)
  rectified_df <- rectify_arguments(raw_args)
  produce_similar(rectified_df)
}

#* @serializer unboxedJSON
#* @get /arguments
function() {
  data_schema
}
