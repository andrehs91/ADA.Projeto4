# ------------------------------------------------------------------------------

docker build -f ADA.Consumer/Dockerfile -t andrehs/ada.consumer .
docker push andrehs/ada.consumer

# ------------------------------------------------------------------------------

docker build -f ADA.Producer/Dockerfile -t andrehs/ada.producer .
docker push andrehs/ada.producer

# ------------------------------------------------------------------------------

docker run --rm --name rabbitmq -d -p 5672:5672 -p 15672:15672 rabbitmq:3.13-management
docker run --rm --name redis -d -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
docker run --rm --name minio -d -p 9000:9000 -p 9001:9001 quay.io/minio/minio server /data --console-address ":9001"

# ------------------------------------------------------------------------------

terraform init
terraform validate
terraform workspace new dev
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
terraform destroy -var-file="dev.tfvars"

# ------------------------------------------------------------------------------
