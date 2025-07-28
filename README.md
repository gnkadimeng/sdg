# SDG Gaming App

This project is a Flask-based application that uses PostgreSQL for data storage and Docker for containerization. The repository includes a `docker-compose.yml` for local development.

## Local Development

1. Ensure Docker and Docker Compose are installed.
2. Copy `.env` to configure your development settings. The default values will work with `docker-compose`.
3. Run `docker compose up` and visit [http://localhost:5050](http://localhost:5050).

## Deploying to Microsoft Azure

Azure App Service supports multi-container deployments using a Docker Compose file. Below is a high-level workflow to deploy this application.

### 1. Create Azure Resources

```bash
# Log in
az login

# Set variables
RESOURCE_GROUP="sdg-rg"
LOCATION="eastus"
PLAN="sdg-plan"
APP="sdg-app"
REGISTRY="sdgregistry"

# Resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# App Service plan (Linux)
az appservice plan create \
  --name $PLAN \
  --resource-group $RESOURCE_GROUP \
  --is-linux

# Create a web app with Docker Compose support
az webapp create \
  --name $APP \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN \
  --multicontainer-config-type compose \
  --multicontainer-config-file docker-compose.yml
```

### 2. Configure Environment Variables

Set the same environment variables used in `.env` within the web app:

```bash
az webapp config appsettings set \
  --name $APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    SECRET_KEY=<your-secret> \
    DB_NAME=sustain_app \
    DB_USER=postgres \
    DB_PASSWORD=postgres \
    DB_HOST=db \
    DB_PORT=5432
```

### 3. Deploy Containers

App Service will automatically pull the images defined in your `docker-compose.yml`. If you push your images to a registry other than Docker Hub, configure that registry with:

```bash
az webapp config container set \
  --name $APP \
  --resource-group $RESOURCE_GROUP \
  --docker-registry-server-url <registry-url> \
  --docker-registry-server-user <username> \
  --docker-registry-server-password <password>
```

After configuration, restart the web app:

```bash
az webapp restart --name $APP --resource-group $RESOURCE_GROUP
```

### 4. Access the Application

Once the web app restarts, navigate to `https://$APP.azurewebsites.net` to see your deployed site.

Refer to [Azure App Service documentation](https://learn.microsoft.com/azure/app-service/) for advanced settings such as using Azure Database for PostgreSQL instead of the containerized database.


