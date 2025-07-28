#!/bin/bash

# Azure Deployment Script for SDG Escape Room App
# This script deploys the Flask app to Azure Container Apps with PostgreSQL

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration Variables
RESOURCE_GROUP="sdg-escape-room-rg"
LOCATION="eastus"
CONTAINERAPPS_ENVIRONMENT="sdg-environment"
APP_NAME="sdg-escape-room"
DATABASE_SERVER="sdg-postgres-$(date +%s)"
DATABASE_NAME="sustain_app"
DATABASE_PASSWORD="SDGEscapeRoom123!"
SECRET_KEY="SDGEscapeRoomSecretKey2024!$(date +%s)"

# Docker image - UPDATE THIS WITH YOUR ACTUAL IMAGE
DOCKER_IMAGE="ghcr.io/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:latest"

echo "=========================================="
echo "SDG Escape Room - Azure Deployment Script"
echo "=========================================="
echo ""

print_status "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Name: $APP_NAME"
echo "  Database Server: $DATABASE_SERVER"
echo "  Container Environment: $CONTAINERAPPS_ENVIRONMENT"
echo ""

# Function to check if Azure CLI is logged in
check_azure_login() {
    print_status "Checking Azure CLI login status..."
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure CLI. Please run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI is logged in"
}

# Function to register required providers
register_providers() {
    print_status "Registering required Azure resource providers..."
    
    providers=("Microsoft.App" "Microsoft.OperationalInsights" "Microsoft.DBforPostgreSQL")
    
    for provider in "${providers[@]}"; do
        print_status "Registering $provider..."
        az provider register -n $provider --wait
        status=$(az provider show -n $provider --query "registrationState" -o tsv)
        if [ "$status" = "Registered" ]; then
            print_success "$provider is registered"
        else
            print_warning "$provider status: $status"
        fi
    done
}

# Function to create or verify resource group
setup_resource_group() {
    print_status "Setting up resource group..."
    
    if az group show --name $RESOURCE_GROUP &> /dev/null; then
        print_success "Resource group $RESOURCE_GROUP already exists"
    else
        print_status "Creating resource group $RESOURCE_GROUP..."
        az group create --name $RESOURCE_GROUP --location $LOCATION
        print_success "Resource group created"
    fi
}

# Function to create Container Apps environment
setup_container_environment() {
    print_status "Setting up Container Apps environment..."
    
    if az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "Container Apps environment already exists"
    else
        print_status "Creating Container Apps environment..."
        az containerapp env create \
            --name $CONTAINERAPPS_ENVIRONMENT \
            --resource-group $RESOURCE_GROUP \
            --location $LOCATION
        print_success "Container Apps environment created"
    fi
}

# Function to create PostgreSQL database
setup_database() {
    print_status "Setting up PostgreSQL database..."
    
    if az postgres flexible-server show --name $DATABASE_SERVER --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "PostgreSQL server already exists"
    else
        print_status "Creating PostgreSQL server (this may take 5-10 minutes)..."
        az postgres flexible-server create \
            --resource-group $RESOURCE_GROUP \
            --name $DATABASE_SERVER \
            --location $LOCATION \
            --admin-user postgres \
            --admin-password "$DATABASE_PASSWORD" \
            --sku-name Standard_B1ms \
            --tier Burstable \
            --public-access 0.0.0.0 \
            --storage-size 32 \
            --yes
        print_success "PostgreSQL server created"
    fi
    
    # Create database
    print_status "Creating database $DATABASE_NAME..."
    az postgres flexible-server db create \
        --resource-group $RESOURCE_GROUP \
        --server-name $DATABASE_SERVER \
        --database-name $DATABASE_NAME \
        || print_warning "Database may already exist"
    
    # Configure firewall
    print_status "Configuring database firewall..."
    az postgres flexible-server firewall-rule create \
        --resource-group $RESOURCE_GROUP \
        --name $DATABASE_SERVER \
        --rule-name AllowAzureServices \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0 \
        || print_warning "Firewall rule may already exist"
    
    print_success "Database setup completed"
}

# Function to deploy the container app
deploy_app() {
    print_status "Deploying Container App..."
    
    DB_HOST="$DATABASE_SERVER.postgres.database.azure.com"
    
    print_status "Using Docker image: $DOCKER_IMAGE"
    print_warning "Make sure this image exists and is accessible!"
    
    az containerapp create \
        --name $APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --environment $CONTAINERAPPS_ENVIRONMENT \
        --image $DOCKER_IMAGE \
        --target-port 5000 \
        --ingress external \
        --min-replicas 1 \
        --max-replicas 3 \
        --cpu 0.5 \
        --memory 1.0Gi \
        --env-vars \
            FLASK_APP=app.py \
            FLASK_ENV=production \
            SECRET_KEY="$SECRET_KEY" \
            DB_NAME=$DATABASE_NAME \
            DB_USER=postgres \
            DB_PASSWORD="$DATABASE_PASSWORD" \
            DB_HOST="$DB_HOST" \
            DB_PORT=5432
    
    print_success "Container App deployed"
}

# Function to get deployment info
get_deployment_info() {
    print_status "Getting deployment information..."
    
    # Get app URL
    APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
    
    # Get database connection string
    DB_CONNECTION_STRING="postgresql://postgres:$DATABASE_PASSWORD@$DATABASE_SERVER.postgres.database.azure.com:5432/$DATABASE_NAME"
    
    echo ""
    echo "=========================================="
    echo "DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "=========================================="
    echo ""
    echo "🌐 Application URL: https://$APP_URL"
    echo "🗄️  Database Server: $DATABASE_SERVER.postgres.database.azure.com"
    echo "🔐 Database Name: $DATABASE_NAME"
    echo "👤 Database User: postgres"
    echo "🏢 Resource Group: $RESOURCE_GROUP"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Visit your app at: https://$APP_URL"
    echo "2. Initialize the database with your schema.sql"
    echo "3. Insert admin user data"
    echo ""
    echo "🔧 Database Connection String:"
    echo "$DB_CONNECTION_STRING"
    echo ""
    echo "🗑️  To delete everything:"
    echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
    echo ""
}

# Function to deploy a test app (nginx) if Docker image is not ready
deploy_test_app() {
    print_status "Deploying test app (nginx) first..."
    
    az containerapp create \
        --name "$APP_NAME-test" \
        --resource-group $RESOURCE_GROUP \
        --environment $CONTAINERAPPS_ENVIRONMENT \
        --image nginx:latest \
        --target-port 80 \
        --ingress external \
        --min-replicas 1 \
        --max-replicas 2
    
    TEST_URL=$(az containerapp show --name "$APP_NAME-test" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
    print_success "Test app deployed at: https://$TEST_URL"
}

# Main execution
main() {
    echo "What would you like to do?"
    echo "1. Full deployment (Database + App)"
    echo "2. Test deployment (nginx only)"
    echo "3. Database only"
    echo "4. App only (requires existing database)"
    echo "5. Show current resources"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            print_status "Starting full deployment..."
            check_azure_login
            register_providers
            setup_resource_group
            setup_container_environment
            setup_database
            deploy_app
            get_deployment_info
            ;;
        2)
            print_status "Starting test deployment..."
            check_azure_login
            register_providers
            setup_resource_group
            setup_container_environment
            deploy_test_app
            ;;
        3)
            print_status "Setting up database only..."
            check_azure_login
            register_providers
            setup_resource_group
            setup_database
            ;;
        4)
            print_status "Deploying app only..."
            check_azure_login
            setup_resource_group
            deploy_app
            get_deployment_info
            ;;
        5)
            print_status "Current resources in $RESOURCE_GROUP:"
            az resource list --resource-group $RESOURCE_GROUP --output table 2>/dev/null || echo "Resource group not found or empty"
            ;;
        *)
            print_error "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
}

# Check if Docker image variable needs to be updated
if [[ "$DOCKER_IMAGE" == *"YOUR_GITHUB_USERNAME"* ]]; then
    print_warning "⚠️  IMPORTANT: Update the DOCKER_IMAGE variable in this script!"
    print_warning "   Current: $DOCKER_IMAGE"
    print_warning "   Replace with your actual GitHub Container Registry image"
    echo ""
fi

# Run main function
main