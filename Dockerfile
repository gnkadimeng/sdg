# Use the official Python image
FROM python:3.13.3

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements first to install dependencies (improves caching)
COPY requirements.txt .

# Install the required Python packages
RUN pip3 install -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port Flask will run on
EXPOSE 5000

# Define the default command to run the app
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
