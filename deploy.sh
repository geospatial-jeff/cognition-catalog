
################################
# Deploy cognition-datasources #
################################


# Install library
echo "Installing Cognition-Datasources."
git clone https://github.com/geospatial-jeff/cognition-datasources.git
(cd cognition-datasources && python setup.py develop)

# Load drivers from `config.yml`
echo "Loading datasource drivers."
datasources="$(cat config.yml | shyaml get-values cognition-datasources.drivers)"
load_drivers="cognition-datasources load"
while read -r line; do
    echo "$line"
    load_drivers+=" -d "$line""
done <<< "$datasources"
echo "$load_drivers"
eval $load_drivers

# Build deployment package
echo "Building deployment package."
docker build . -t cognition-datasources:latest
docker run --rm -v $PWD:/home/cognition-datasources -it cognition-datasources:latest package-service.sh

echo "Deploying to AWS."
sls deploy -v