# ai-blog-generator-app-24754-25862

This repository contains a multi-container AI Blog Generator App. This README highlights the Database container setup and how to work with it locally.

Database Container (PostgreSQL)
- Database name: ai_blog_generator_db
- Port: 5000
- Default user: appuser
- Default password: dbuser123
- Schema file: Database/schema.sql
- Migrations folder: Database/migrations/

What the startup script does
- Initializes PostgreSQL data directory (if required)
- Starts PostgreSQL on port 5000
- Creates database ai_blog_generator_db and user appuser (with password dbuser123) if they do not exist
- Applies Database/schema.sql (and any SQL files under Database/migrations/)
- Generates helper files:
  - Database/db_connection.txt: one-liner to connect with psql
  - Database/db_visualizer/postgres.env: env vars for the simple DB visualizer

How to start the database
- Run: bash Database/startup.sh
- Ensure that port 5000 is available on your machine

How to connect
- Using psql:
  - psql -h localhost -U appuser -d ai_blog_generator_db -p 5000
- Or use the saved connection string:
  - cat Database/db_connection.txt

Simple DB Visualizer
- This repo includes a minimal Node.js database viewer (supports PostgreSQL, MySQL, SQLite, MongoDB)
- To use for PostgreSQL:
  1) source Database/db_visualizer/postgres.env
  2) node Database/db_visualizer/server.js
  - The viewer will run at http://localhost:3000

Backup and Restore
- Backup: bash Database/backup_db.sh
  - Produces database_backup.sql when PostgreSQL is running on port 5000
- Restore: bash Database/restore_db.sh
  - Restores from database_backup.sql

Notes
- The BackendAPIService should be configured to connect to:
  - postgresql://appuser:dbuser123@localhost:5000/ai_blog_generator_db
- Ensure your backend ORM migrations align with the schema in Database/schema.sql
