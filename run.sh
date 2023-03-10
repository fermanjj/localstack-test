#!/bin/zsh

docker compose down && docker compose up -d

sleep 10

aws --endpoint http://localhost:4566 lambda create-function \
    --function-name test \
    --zip-file fileb://$PWD/bootstrap.zip \
    --handler "bootstrap" \
    --runtime "provided.al2" \
    --role arn:aws:iam::000000000000:role/lambda-ex \
    --no-cli-pager \
    --region us-east-1

aws --endpoint http://localhost:4566 lambda invoke \
    --function-name test \
    --cli-binary-format raw-in-base64-out \
    --payload '{"test": true}' \
    --no-cli-pager \
    output.json
