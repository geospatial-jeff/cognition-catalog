################################
# Setting up #
################################
# Clone libraries
git clone https://github.com/geospatial-jeff/cognition-datasources.git
git clone https://github.com/sat-utils/sat-api-deployment.git

# Update deployment configurations
python config_loader.py

############################
# Deploy cognition-catalog #
############################
echo "Deploying cognition-catalog."
(cd catalog && sls deploy -v)

################################
# Deploy cognition-datasources #
################################

# Install library
echo "Installing Cognition-Datasources."
(cd cognition-datasources && python setup.py develop)

# Load drivers from `config.yml`
echo "Loading datasource drivers."
datasources="$(cat config.yml | shyaml get-values cognition-datasources.drivers)"
load_drivers="cognition-datasources load"
while read -r line; do
    load_drivers+=" -d "$line""
done <<< "$datasources"

eval $load_drivers

# Build deployment package
echo "Building deployment package."
(cd cognition-datasources && \
    docker build . -t cognition-datasources:latest && \
    docker run --rm -v $PWD:/home/cognition-datasources -it cognition-datasources:latest package-service.sh && \
    echo "Deploying to AWS." && \
    sls deploy -v)

cd_endpoint="$(echo "$(cd cognition-datasources && sls info)" | sed 1d | shyaml get-value endpoints)"
cd_endpoint="${cd_endpoint:7}"

##################
# Deploy sat-api #
##################
echo "Deploying sat-api."
(cd sat-api-deployment && \
    yarn && \
    ./node_modules/.bin/kes cf deploy --region us-east-1 --template .kes/template --showOutputs >> kes_output)

satapi_endpoint="$(tail -1 sat-api-deployment/kes_output | head -1)"

##########################
# Deployment information #
##########################
echo "Deployment Information:"
echo Cognition-Datasources endpoint: "${cd_endpoint::-11}"
echo Sat-API endpoint: "${satapi_endpoint/stage/dev}"


