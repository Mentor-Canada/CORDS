gcloud auth configure-docker
docker tag $1 gcr.io/matteproject/$1
docker push gcr.io/matteproject/$1