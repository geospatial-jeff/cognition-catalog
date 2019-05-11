##############
# Setting up #
##############
# Install cognition-catalog CLI
python setup.py develop

# Clone libraries
git clone https://github.com/geospatial-jeff/cognition-datasources.git
git clone https://github.com/sat-utils/sat-api-deployment.git

# Update deployment configurations
cognition-catalog load_user_config

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

# Create deployment bucket for sat-api.
aws s3api create-bucket --bucket "$(cat config.yml | shyaml get-value sat-api.bucket)" --region us-east-1

echo "Deploying sat-api."
(cd sat-api-deployment && \
    yarn && \
    ./node_modules/.bin/kes cf deploy --region us-east-1 --template .kes/template --showOutputs >> kes_output)

satapi_endpoint="$(tail -1 sat-api-deployment/kes_output | head -1)"

############################
# Deploy cognition-catalog #
############################
cognition-catalog add_environment_variable catalog/serverless.yml --key CD_ENDPOINT --value "${cd_endpoint::-11}"
cognition-catalog add_environment_variable catalog/serverless.yml --key SATAPI_ENDPOINT --value "${satapi_endpoint/stage/dev}"

echo "Deploying cognition-catalog."
(cd catalog && sls deploy -v)

##########################
# Deployment information #
##########################
echo "Deployment Information:"
echo Cognition-Datasources endpoint: "${cd_endpoint::-11}"
echo Sat-API endpoint: "${satapi_endpoint/stage/dev}"