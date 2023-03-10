# Usage: make
# make ARCH=arm64

ARCH ?= x86_64

ifeq ($(ARCH),arm64)
BOOTSTRAP ?= bootstrap_arm64.zip
else
BOOTSTRAP ?= bootstrap.zip
endif

all: run

run: start-localstack wait-localstack create-function wait-function-active invoke

start-localstack:
	docker compose down && docker compose up -d

wait-localstack:
	@echo -n Waiting for LocalStack startup
	@until curl -sfo /dev/null localhost:4566/_localstack/health; do echo ".\c"; sleep 1; done
	@echo
	@echo LocalStack is up and running

create-function:
	aws --endpoint http://localhost:4566 lambda create-function \
    --function-name test \
    --zip-file fileb://$$PWD/$(BOOTSTRAP) \
    --handler "bootstrap" \
    --runtime "provided.al2" \
    --role arn:aws:iam::000000000000:role/lambda-ex \
    --no-cli-pager \
    --region us-east-1 \
	--architectures $(ARCH)

wait-function-active:
	# Wait until function transitioned from Pending to Active state.
	# See https://aws.amazon.com/blogs/compute/coming-soon-expansion-of-aws-lambda-states-to-all-functions/
	aws --endpoint http://localhost:4566 lambda wait function-active-v2 \
		--function-name test

invoke:
	aws --endpoint http://localhost:4566 lambda invoke \
    --function-name test \
    --cli-binary-format raw-in-base64-out \
    --payload '{"test": true}' \
    --no-cli-pager \
    output.json

stop:
	docker compose down

.PHONY: run start-localstack wait-localstack create-function create-function-arm wait-function-active invoke stop
