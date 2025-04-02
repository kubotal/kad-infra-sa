#!/bin/bash

kubectl -n kubocd create secret generic ca-odp --from-file=ca.crt
kubectl -n default create secret generic ca-odp --from-file=ca.crt

