#!/bin/bash

R -e 'pr <- plumber::plumb("knoedler_api.R"); pr$run(port = 8888)'
