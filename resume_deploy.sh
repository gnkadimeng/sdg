#!/bin/bash

# Resume Azure Deployment Script for SDG Escape Room App
# This script can continue from where the previous deployment left off

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

# Configuration Variables (based on your successful deployment)
RESOURCE_GROUP="sdg-escape-room-rg"
LOCATION="centralus"
CONTAINERAPPS_ENVIRONMENT="sdg-environment-centralus"
APP_NAME="sdg-escape-room"
DATABASE_SERVER="sdg-postgres-1753727019"  # Your existing database
DATABASE_NAME="sustain_app"
DATABASE_PASSWORD="SDGEscapeRoom123!"
SECRET_KEY="SDGEscapeRoomSecretKey2024!$(date +%s)"

# Docker image options
DOCKER_IMAGE_CUSTOM="ghcr.io/gnkadimeng/sdg:latest"
DOCKER_IMAGE_TEST="nginx:latest"

echo "=========================================="
echo "SDG Escape Room - Resume Deployment Script"
echo "=========================================="
echo ""

print_status "Current Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Name: $APP_NAME"
echo "  Database Server: $DATABASE_SERVER"
echo "  Container Environment: $CONTAINERAPPS_ENVIRONMENT"
echo ""

# Function to check current deployment status
check_deployment_status() {
    print_status "Checking current deployment status..."
    
    # Check resource group
    if az group show --name $RESOURCE_GROUP &> /dev/null; then
        print_success "✅ Resource group exists"
    else
        print_error "❌ Resource group not found"
        return 1
    fi
    
    # Check Container Apps environment
    if az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "✅ Container Apps environment exists"
        ENV_DOMAIN=$(az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --query "properties.defaultDomain" -o tsv)
        echo "    Domain: $ENV_DOMAIN"
    else
        print_error "❌ Container Apps environment not found"
    fi
    
    # Check PostgreSQL server
    if az postgres flexible-server show --name $DATABASE_SERVER --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "✅ PostgreSQL server exists"
        DB_HOST=$(az postgres flexible-server show --name $DATABASE_SERVER --resource-group $RESOURCE_GROUP --query "fullyQualifiedDomainName" -o tsv)
        echo "    Host: $DB_HOST"
    else
        print_error "❌ PostgreSQL server not found"
    fi
    
    # Check if app exists
    if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "✅ Container app exists"
        APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
        echo "    URL: https://$APP_URL"
    else
        print_warning "⚠️  Container app not deployed yet"
    fi
    
    # Check if test app exists
    if az containerapp show --name "$APP_NAME-test" --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_success "✅ Test app exists"
        TEST_URL=$(az containerapp show --name "$APP_NAME-test" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
        echo "    Test URL: https://$TEST_URL"
    else
        print_warning "⚠️  Test app not deployed yet"
    fi
    
    echo ""
}

# Function to deploy test app (nginx)
deploy_test_app() {
    print_status "Deploying test app (nginx)..."
    
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
    echo ""
    echo "🌐 Visit https://$TEST_URL to verify your Container Apps setup works!"
    echo ""
}

# Function to check if Docker image exists
check_docker_image() {
    print_status "Checking if Docker image exists..."
    
    DOCKER_IMAGE="ghcr.io/gnkadimeng/sdg:latest"
    
    print_status "Checking image: $DOCKER_IMAGE"
    
    # Try to pull the image to check if it exists
    if docker pull $DOCKER_IMAGE &> /dev/null; then
        print_success "✅ Docker image exists and is accessible"
        return 0
    else
        print_warning "⚠️  Docker image not found or not accessible"
        echo ""
        echo "To build and push your Docker image:"
        echo "1. Make sure GitHub Actions workflow is configured in your repo"
        echo "2. Push changes to trigger the workflow: git push origin main"
        echo "3. Check workflow status at: https://github.com/gnkadimeng/sdg/actions"
        echo "4. Ensure your repository has GITHUB_TOKEN permissions for packages"
        echo ""
        return 1
    fi
}

# Function to setup GitHub Container Registry access
setup_github_registry() {
    print_status "Setting up GitHub Container Registry access..."
    echo ""
    echo "To make your Docker image accessible:"
    echo ""
    echo "1. Go to: https://github.com/gnkadimeng/sdg/settings/actions"
    echo "2. Ensure 'Actions permissions' allow GitHub Actions to run"
    echo "3. Go to: https://github.com/gnkadimeng/sdg/settings/packages"
    echo "4. Make sure package visibility is set correctly"
    echo ""
    echo "5. Push to main branch to trigger GitHub Actions:"
    echo "   git add ."
    echo "   git commit -m \"Trigger Docker build\""
    echo "   git push origin main"
    echo ""
    echo "6. Monitor the build at: https://github.com/gnkadimeng/sdg/actions"
    echo ""
}
deploy_real_app() {
    read -p "Enter your Docker image URL (e.g., ghcr.io/username/repo:latest): " DOCKER_IMAGE
    
    if [[ -z "$DOCKER_IMAGE" ]]; then
        print_error "No Docker image provided"
        return 1
    fi
    
    print_status "Deploying real app with image: $DOCKER_IMAGE"
    
    DB_HOST="$DATABASE_SERVER.postgres.database.azure.com"
    
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
    
    APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
    print_success "Real app deployed at: https://$APP_URL"
}

# Function to initialize database schema
init_database() {
    print_status "Initializing database schema..."
    
    DB_CONNECTION_STRING="postgresql://postgres:$DATABASE_PASSWORD@$DATABASE_SERVER.postgres.database.azure.com:5432/$DATABASE_NAME"
    
    print_status "Database connection string:"
    echo "$DB_CONNECTION_STRING"
    echo ""
    
    print_warning "To initialize your database schema, you can:"
    echo "1. Connect using psql: psql '$DB_CONNECTION_STRING'"
    echo "2. Run your schema.sql file"
    echo "3. Insert admin user data"
    echo ""
    echo "Example commands:"
    echo "  psql '$DB_CONNECTION_STRING' -f schema.sql"
    echo "  psql '$DB_CONNECTION_STRING' -c \"INSERT INTO admins...\""
    echo ""
}

# Function to update existing app
update_app() {
    print_status "Updating existing container app..."
    
    if ! az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_error "Container app $APP_NAME not found. Deploy it first."
        return 1
    fi
    
    read -p "Enter new Docker image URL: " NEW_DOCKER_IMAGE
    
    if [[ -z "$NEW_DOCKER_IMAGE" ]]; then
        print_error "No Docker image provided"
        return 1
    fi
    
    az containerapp update \
        --name $APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --image $NEW_DOCKER_IMAGE
    
    print_success "App updated with new image: $NEW_DOCKER_IMAGE"
}

# Function to clean up failed deployments
cleanup_failed() {
    print_status "Cleaning up failed container apps..."
    
    # Try to delete the failed app if it exists
    if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        print_status "Deleting failed container app..."
        az containerapp delete --name $APP_NAME --resource-group $RESOURCE_GROUP --yes
        print_success "Failed container app deleted"
    fi
}

# Function to show deployment info
show_deployment_info() {
    print_status "Current deployment information..."
    
    DB_CONNECTION_STRING="postgresql://postgres:$DATABASE_PASSWORD@$DATABASE_SERVER.postgres.database.azure.com:5432/$DATABASE_NAME"
    
    echo ""
    echo "=========================================="
    echo "DEPLOYMENT INFORMATION"
    echo "=========================================="
    echo ""
    echo "🗄️  Database:"
    echo "   Server: $DATABASE_SERVER.postgres.database.azure.com"
    echo "   Database: $DATABASE_NAME"
    echo "   User: postgres"
    echo "   Connection: $DB_CONNECTION_STRING"
    echo ""
    
    # Check apps
    if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
        echo "🌐 Main App: https://$APP_URL"
    fi
    
    if az containerapp show --name "$APP_NAME-test" --resource-group $RESOURCE_GROUP &> /dev/null; then
        TEST_URL=$(az containerapp show --name "$APP_NAME-test" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
        echo "🧪 Test App: https://$TEST_URL"
    fi
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Deploy/update your container app with correct Docker image"
    echo "2. Initialize database schema"
    echo "3. Insert admin user data"
    echo ""
    echo "🗑️  To delete everything:"
    echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
    echo ""
}

# Main menu function
main() {
    check_deployment_status
    
    echo "What would you like to do?"
    echo "1. Deploy test app (nginx) - Verify Container Apps works"
    echo "2. Deploy real app - With your Docker image (ghcr.io/gnkadimeng/sdg:latest)"
    echo "3. Update existing app - Change Docker image"
    echo "4. Initialize database schema"
    echo "5. Clean up failed deployments"
    echo "6. Show deployment info"
    echo "7. Show current status"
    echo "8. Check Docker image availability"
    echo "9. Setup GitHub Container Registry"
    echo ""
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1)
            deploy_test_app
            ;;
        2)
            # First check if there's a failed deployment and clean it up
            if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
                APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
                if [[ -z "$APP_URL" || "$APP_URL" == "null" ]]; then
                    print_warning "Found existing failed deployment. Cleaning up first..."
                    az containerapp delete --name $APP_NAME --resource-group $RESOURCE_GROUP --yes
                    print_success "Cleaned up failed deployment"
                fi
            fi
            
            if check_docker_image; then
                DOCKER_IMAGE="ghcr.io/gnkadimeng/sdg:latest"
                deploy_real_app_with_image "$DOCKER_IMAGE"
            else
                print_error "Docker image not available. Try option 8 or 9 first."
            fi
            ;;
        3)
            update_app
            ;;
        4)
            init_database
            ;;
        5)
            cleanup_failed
            ;;
        6)
            show_deployment_info
            ;;
        7)
            check_deployment_status
            ;;
        8)
            check_docker_image
            ;;
        9)
            setup_github_registry
            ;;
        *)
            print_error "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
}

# Run main function
main