# AI Blog Generator - Database (PostgreSQL)

This container provides persistent storage for the application.

Defaults (Local Development)
- DB_NAME: ai_blog_generator_db
- Port: 5000

Quick Start
1. Start the database service on port 5000
   - Ensure the database `ai_blog_generator_db` exists
2. Provide connection details to the BackendAPIService via environment variables
3. Start BackendAPIService (connects to this DB)
4. Start FrontendWebApplication

Artifacts
- db_connection.txt: Should reflect connection to `ai_blog_generator_db` on port `5000`
- Any visualizer environment should use the same DB name and port

Notes
- Do not hardcode credentials in code; use environment variables
- Only the backend should connect to this database
