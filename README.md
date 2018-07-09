# Knoedler API prototype

A prototype API service using the R package [plumber](https://www.rplumber.io) to wrap arbitray R code in a REST API.

The app will retrieve profit predictions as well as similar observations from a predictive model of the Knoedler transactions dataset.

## Installation

Requires an installation of R, and the following packages:

``` r
install.packages(c("plumbr", "randomForest", "tidyverse", "dummies", "distances"))
```

## Running

``` sh
R -e 'pr <- plumber::plumb("knoedler_api.R"); pr$run(port = 8888)'
```

## Queries

### Listing query parameters

``` sh
curl 'localhost:8888/arguments`
```

This will return a JSON document with the field names, variable types, and categories or numeric ranges for each query parameter in the model:

``` json
[
  {
    "label": "area",
    "type": "numeric",
    "range": {
      "min": 1.875,
      "max": 14664
    }
  },
  {
    "label": "orientation",
    "type": "factor",
    "values": [
      "landscape",
      "portrait",
      "square"
    ]
  },
  {
    "label": "is_jointly_owned",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "n_purchase_partners",
    "type": "integer",
    "range": {
      "min": 1,
      "max": 5
    }
  },
  {
    "label": "k_share",
    "type": "numeric",
    "range": {
      "min": -1,
      "max": 1
    }
  },
  {
    "label": "genre",
    "type": "factor",
    "values": [
      "Landscape",
      "Genre",
      "History",
      "Portrait",
      "Still Life",
      "abstract"
    ]
  },
  {
    "label": "is_firsttime_seller",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "is_major_seller",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "is_firsttime_buyer",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "is_major_buyer",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "is_old_master",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "deflated_expense_amount",
    "type": "numeric",
    "range": {
      "min": 0.814,
      "max": 356622.3647
    }
  },
  {
    "label": "purchase_seller_type",
    "type": "factor",
    "values": [
      "Artist",
      "Museum",
      "Dealer",
      "Collector"
    ]
  },
  {
    "label": "artist_is_alive",
    "type": "factor",
    "values": [
      "TRUE",
      "FALSE"
    ]
  },
  {
    "label": "time_in_stock",
    "type": "numeric",
    "range": {
      "min": 0,
      "max": 18628
    }
  }
]

```

### Getting predictions

You can `GET` predictions from the `/predict` path, passing variables as URL query parameters:

``` sh
curl 'localhost:8888/predict?area=350&orientation=portrait&is_jointly_owned=TRUE&n_purchase_partners=1&k_share=1&genre=Landscape&is_firsttime_seller=TRUE&is_major_seller=FALSE&is_firsttime_buyer=FALSE&is_major_buyer=TRUE&is_old_master=FALSE&deflated_expense_amount=2500&purchase_seller_type=Collector&artist_is_alive=TRUE&time_in_stock=250'
```

This will return a JSON document with the median value of class predictions from the ensemble model, as well as the upper and lower bounds of a 95% confidence interval.

``` json
[
  {
    "gain_low": 0.546,
    "loss_low": 0.2495,
    "gain_med": 0.635,
    "loss_med": 0.365,
    "gain_hig": 0.7505,
    "loss_hig": 0.454
  }
]
```

### Getting similar 

Passing the same query to `/similar` will return a list of IDs of similar historical sales from the Getty Provenance Index databases:

``` sh
curl 'localhost:8888/similar?area=350&orientation=portrait&is_jointly_owned=TRUE&n_purchase_partners=1&k_share=1&genre=Landscape&is_firsttime_seller=TRUE&is_major_seller=FALSE&is_firsttime_buyer=FALSE&is_major_buyer=TRUE&is_old_master=FALSE&deflated_expense_amount=2500&purchase_seller_type=Collector&artist_is_alive=TRUE&time_in_stock=250'
```

This returns a document with database ID and distances:

``` json
{
  "result": [
    {
      "id": 7918,
      "distance": 58.7623
    },
    {
      "id": 6826,
      "distance": 62.6183
    },
    {
      "id": 6220,
      "distance": 65.3447
    },
    {
      "id": 14608,
      "distance": 66.1718
    },
    {
      "id": 6351,
      "distance": 68.5778
    }
  ],
  "distance_quantiles": [
    {
      "percentile": 0,
      "value": 0
    },
    {
      "percentile": 0.25,
      "value": 669.6666
    },
    {
      "percentile": 0.5,
      "value": 1158.0585
    },
    {
      "percentile": 0.75,
      "value": 2590.8223
    },
    {
      "percentile": 1,
      "value": 356621.7715
    }
  ]
}
```

