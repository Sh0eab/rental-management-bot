
Before starting, make sure you have:

- **Python 3.8+** installed and added to PATH
- **XAMPP** installed (with MySQL component)
- **Git** (if you haven't already cloned the repository)

## Step-by-Step Setup

### 1. Install Python Dependencies

Open PowerShell or Command Prompt in the project directory and run:

```bash
pip install -r requirements.txt
```

If you want to use a virtual environment (recommended):

```bash
# Create virtual environment
python -m venv venv

# Activate it (Windows)
venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

### 2. Setup XAMPP Database

#### 2.1 Start XAMPP
1. Open XAMPP Control Panel
2. Start the **Apache** and **MySQL** services
3. Click on **Admin** button next to MySQL to open phpMyAdmin

#### 2.2 Create Database
1. In phpMyAdmin, click **Databases** tab
2. Create a new database named: `rasa_db`
3. Select the database from the left sidebar

#### 2.3 Import Database Schema
1. Click **Import** tab in phpMyAdmin
2. Click **Choose file** and select `xampp_database_setup.sql` from the project folder
3. Click **Go** to import the database structure and sample data

#### 2.4 Verify Database Setup
After importing, you should see these tables in the `rasa_db` database:
- `users` (5 sample records)
- `properties` (6 sample properties)
- `nearby_places` (location data)
- `transportation` (transport options)
- `search_analytics` (for analytics)
- `bot_conversations` (for conversation logging)

### 3. Configure Database Connection

The project is already configured to use XAMPP's default MySQL settings:
- Host: `localhost`
- Port: `3306`
- Database: `rasa_db`
- Username: `root`
- Password: (empty by default in XAMPP)

If you've set a password for MySQL root user, update the `.env` file:

```env
DB_PASSWORD=your_mysql_password
```

### 4. Train the Rasa Model

Before running the chatbot, train the model:

```bash
rasa train
```

This will create a model in the `models/` folder.

### Option 1: 

 Terminal 1 - Start Actions Server:
```bash
.\start-actions.ps1
```
Or manually:
```bash
python -m rasa_sdk --actions actions --port 5055 --host 0.0.0.0 --auto-reload
```

#### Terminal 2 - Start Rasa Server:
```bash
.\start-rasa.ps1
```
Or manually:
```bash
rasa run --enable-api --cors "*" --port 5005 --host 0.0.0.0 --endpoints endpoints.yml --credentials credentials.yml --debug
```


Once both servers are running:

- **Chat Interface**: http://localhost:5005/static/chat.html
- **API Endpoint**: http://localhost:5005/webhooks/rest/webhook
- **Server Status**: http://localhost:5005/




   - Make sure XAMPP MySQL is running
   - Verify database `rasa_db` exists
   - Check if you've imported `xampp_database_setup.sql`

2.
   - Make sure actions server is running first
   - Check if port 5055 is available
   - Restart the actions server

   - Run `rasa train` to train a new model
   - Check if `models/` folder has .tar.gz files


   - Install Python 3.8+ and add to PATH
   - Restart terminal/PowerShell after installation


   - Try: `pip install --upgrade pip`
   - Use: `pip install -r requirements.txt --no-cache-dir`



- Use `--auto-reload` flag with actions server for automatic reloading during development
- Check logs in both terminal windows for debugging
- Use `rasa shell` for quick command-line testing
- Monitor database queries in XAMPP MySQL logs


The database comes with sample data including:
- 5 property owners
- 6 properties across different areas of Dhaka and Chittagong
- Location and transportation data
- Various price ranges and property types



After successful setup, you can:
1. Modify training data in `data/` folder
2. Add new actions in `actions/actions.py`
3. Customize the web interface in `static/`
4. Add more sample properties to the database
5. Deploy to a cloud service when ready


If you encounter issues:
1. Check the terminal output for error messages
2. Verify all prerequisites are installed
3. Ensure XAMPP MySQL is running
4. Try retraining the model: `rasa train`
5. Restart both servers
