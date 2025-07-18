# BritEdge_WebApp_Flexible_Cloud_Deployment_Source_Code

## Tech Stack & Setup

This repository contains a sample Flask web application, "BritEdge Job Management," designed to allow you to explore flexible cloud deployment strategies. The application allows users to log in, create, track, and manage job entries (e.g., deliveries, engineering tasks). It's built to demonstrate database flexibility and possible containerisation for various cloud configurations.

## How to use this in the cloud?

* Run on a virtual machine with the inbuilt SQLite database
* Run on a virtual machine with a separate database instance (e.g. PostRes SQL or Cosmos DB NoSQL)
* Run on some App running service?
* Make a container and run instance(s) of a container?
* Maybe use Storage services if you wish to store static assets

### Key Technologies

* **Flask**: Lightweight Python web framework for the application's backend.
* **SQLAlchemy**: Python SQL toolkit and Object-Relational Mapper (ORM) for interacting with various SQL databases.
* **Flask-Login**: Provides user session management for authentication.
* **PostgreSQL**: A powerful, open-source object-relational database system, ideal for managed cloud databases (e.g., Azure Database for PostgreSQL).
* **SQLite**: A self-contained, file-based SQL database for local development and monolithic deployments.
* **Azure Cosmos DB (PostgreSQL API)**: Demonstrates connecting to Cosmos DB using its PostgreSQL-compatible API.
* **Docker**: Containerisation for consistent build and deployment across environments.
* **python-dotenv**: For loading environment variables from a `.env` file during local development.

### Repository Structure

```
britedge_app/
├── app.py             # Main Flask application, initialises extensions and creates DB tables
├── models.py          # Defines SQLAlchemy database models (User, Job)
├── routes.py          # Contains all Flask routes for user authentication and job management
├── config.py          # Application configuration, handles environment variables
├── requirements.txt   # Python dependencies
├── Dockerfile         # Container build instructions for Docker
├── .env               # Environment variables (DO NOT COMMIT THIS FILE!)
└── templates/         # HTML templates for the web interface
    ├── base.html
    ├── index.html
    ├── login.html
    ├── register.html
    ├── create_job.html
    └── job_detail.html
```

## Environment Variables

Sensitive configuration and database connection strings are managed via environment variables. For local development, these can be placed in a `.env` file, which is loaded using `python-dotenv`.

**Example `.env` file:**

```
SECRET_KEY='your_strong_random_secret_key_here'
# --- Choose one of the DATABASE_URL configurations below ---

# 1. SQLite (for self-contained monolith/local development)
# DATABASE_URL='sqlite:///site.db'

# 2. PostgreSQL (e.g., Azure Database for PostgreSQL)
# DATABASE_URL='postgresql://<user>:<password>@<host>:<port>/<database_name>'
# Example for Azure: DATABASE_URL='postgresql://youradmin@yourserver:yourpassword@yourserver.postgres.database.azure.com:5432/yourdatabase'

# 3. Azure Cosmos DB (PostgreSQL API)
# DATABASE_URL='postgresql://<cosmos_user>:<cosmos_password>@<cosmos_host>:<cosmos_port>/<cosmos_database_name>'
# This will look similar to a standard PostgreSQL connection string.
```

**Note:** The `.env` file should be excluded from version control using `.gitignore` to prevent sensitive information from being committed. When deploying to cloud environments, these variables should be configured as secure application settings or secrets within the cloud platform (e.g., Azure App Service Configuration, Kubernetes Secrets).



## Running Locally (Without Docker)

If you prefer to run the application directly on your machine without Docker:

1.  **Create a Python Virtual Environment (recommended):**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Set environment variables:**
    Create a `.env` file in the root directory (as shown in the "Environment Variables" section above) or set them directly in your shell.
    ```bash
    # Example for Linux/macOS:
    export SECRET_KEY='your_local_secret_key'
    export DATABASE_URL='sqlite:///site.db' # Or your PostgreSQL/Cosmos DB URL
    ```

4.  **Run the Flask application:**
    ```bash
    python app.py
    ```
    The application will be accessible at `http://127.0.0.1:8080` by default.

    **To run on a different port (e.g., 5000) locally:**
    You can modify the `if __name__ == '__main__':` block in `app.py` to specify the port:
    ```python
    if __name__ == '__main__':
        app.run(debug=True, port=5000) # Change 5000 to 8080
    ```
    Or, you can run it using the `flask run` command with the `--port` flag:
    ```bash
    flask run --port 5000
    ```


# Optional

## Building and Running with Docker

Ensure Docker is installed on your system.

1.  **Build the Docker image:**
    Navigate to the root of the `britedge_app` directory.
    ```bash
    docker build -t britedge-app .
    ```

2.  **Run the container:**
    You need to pass the environment variables to the container.

    * **Using SQLite (default, self-contained):**
        ```bash
        docker run -p 8080:8080 -e SECRET_KEY='your_docker_secret_key' britedge-app
        ```
        This will create a `site.db` file *inside the container*. For persistent data, you would need to use Docker volumes.

    * **Connecting to an external PostgreSQL or Azure Cosmos DB (PostgreSQL API):**
        ```bash
        docker run -p 8080:8080 \
            -e SECRET_KEY='your_docker_secret_key' \
            -e DATABASE_URL='postgresql://<user>:<password>@<host>:<port>/<database_name>' \
            britedge-app
        ```
        Replace the `DATABASE_URL` with your actual external database connection string.

The application will be accessible in your browser at `http://localhost:8080` when run via Docker.
