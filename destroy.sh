#!/bin/bash

cd terraform

terraform apply --destroy -input=false -auto-approve
