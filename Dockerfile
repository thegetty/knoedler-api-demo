FROM trestletech/plumber
RUN R -e 'install.packages(c("dplyr", "purrr", "randomForest", "dummies", "distances"))'
COPY knoedler_models.rda .
COPY knoedler_api.R .
CMD ["/knoedler_api.R"]
