library(randomForest)
library(tidyverse)

load("knoedler_models.rda")
ensemble_model <- all_model_iterations[[1]]$rf

rectify_arguments <- function(a) {
  a %>%
    mutate_at(vars(area, k_share, n_purchase_partners, deflated_expense_amount, time_in_stock), as.numeric) %>%
    mutate_at(vars(is_jointly_owned, is_firsttime_seller, is_major_seller, is_firsttime_buyer, is_major_buyer, is_old_master, artist_is_alive), funs(factor(., levels = c("TRUE", "FALSE")))) %>%
    mutate(
      orientation = factor(orientation, levels = c("portrait", "landscape", "square")),
      genre = factor(genre, levels = c("Landscape", "Genre", "History", "Portrait", "Still Life", "abstract")),
      purchase_seller_type = factor(purchase_seller_type, levels = c("Artist", "Museum", "Dealer", "Collector")))
}

produce_prediction <- function(df) {
  pred <- predict(ensemble_model, newdata = df, type = "prob")
  list(gain = pred[1,1], loss = pred[1,2])
}

#* @serializer unboxedJSON
#* @get /predict
knoedler_predict <- function(
  area,
  orientation,
  is_jointly_owned,
  n_purchase_partners,
  k_share,
  genre,
  is_firsttime_seller,
  is_major_seller,
  is_firsttime_buyer,
  is_major_buyer,
  is_old_master,
  deflated_expense_amount,
  purchase_seller_type,
  artist_is_alive,
  time_in_stock) {

  raw_df <- data.frame(
    area = area,
    orientation = orientation,
    is_jointly_owned = is_jointly_owned,
    n_purchase_partners = n_purchase_partners,
    k_share = k_share,
    genre = genre,
    is_firsttime_seller = is_firsttime_seller,
    is_major_seller = is_major_seller,
    is_firsttime_buyer = is_firsttime_buyer,
    is_major_buyer = is_major_buyer,
    is_old_master = is_old_master,
    deflated_expense_amount = deflated_expense_amount,
    purchase_seller_type = purchase_seller_type,
    artist_is_alive = artist_is_alive,
    time_in_stock = time_in_stock
  )

  rectified_df <- rectify_arguments(raw_df)
  produce_prediction(rectified_df)
}
