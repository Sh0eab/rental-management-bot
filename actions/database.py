import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv
import json

load_dotenv()

class DatabaseConnection:
    def __init__(self):
        self.host = os.getenv('DB_HOST', 'localhost')
        try:
            self.port = int(os.getenv('DB_PORT', 3306))
        except (ValueError, TypeError):
            self.port = 3306
        self.database = os.getenv('DB_NAME', 'rental_system')
        self.user = os.getenv('DB_USER', 'root')
        self.password = os.getenv('DB_PASSWORD', '')
        self.ssl_mode = os.getenv('DB_SSL_MODE', 'DISABLED')
        self.connection = None
        self.connection_failed = False

    def connect(self):
        try:
            connection_config = {
                'host': self.host,
                'port': self.port,
                'database': self.database,
                'user': self.user,
                'password': self.password,
                'autocommit': True
            }
            
            # Add SSL configuration for cloud databases like Aiven
            if self.ssl_mode and self.ssl_mode.upper() == 'REQUIRED':
                connection_config['ssl_disabled'] = False
                connection_config['ssl_verify_cert'] = True
                connection_config['ssl_verify_identity'] = True
            
            self.connection = mysql.connector.connect(**connection_config)
            print("Database connected successfully")
            return True
        except Error as e:
            print(f"Error connecting to database: {e}")
            return False

    def disconnect(self):
        if self.connection and self.connection.is_connected():
            self.connection.close()

    def search_properties(self, location=None, budget=None, preferences=None):
        if not self.connection or not self.connection.is_connected():
            if not self.connect():
                return []

        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Base query
            query = """
            SELECT p.*, u.full_name as owner_name, u.phone as owner_phone
            FROM properties p
            JOIN users u ON p.owner_id = u.id
            WHERE p.is_available = TRUE
            """
            params = []

            # Add location filter
            if location:
                query += " AND (p.area_name LIKE %s OR p.neighborhood LIKE %s)"
                location_param = f"%{location}%"
                params.extend([location_param, location_param])

            # Add budget filter
            if budget:
                query += " AND p.rent_amount <= %s"
                params.append(float(budget) * 1.1)  # 10% tolerance

            # Add preferences filter (simplified for XAMPP compatibility)
            if preferences and isinstance(preferences, list):
                for pref in preferences:
                    if pref.lower() in ['furnished', 'ac', 'wifi', 'parking', 'security']:
                        # Use JSON_SEARCH instead of JSON_CONTAINS for better XAMPP compatibility
                        query += f" AND JSON_SEARCH(p.amenities, 'one', '{pref}') IS NOT NULL"

            query += " ORDER BY p.rent_amount LIMIT 10"
            
            cursor.execute(query, params)
            results = cursor.fetchall()
            
            # Process JSON fields and handle XAMPP format
            for result in results:
                try:
                    if result['amenities']:
                        if isinstance(result['amenities'], str):
                            result['amenities'] = json.loads(result['amenities'])
                    if result['images']:
                        if isinstance(result['images'], str):
                            result['images'] = json.loads(result['images'])
                except (json.JSONDecodeError, TypeError):
                    # Fallback for XAMPP MySQL compatibility
                    result['amenities'] = result.get('amenities', [])
                    result['images'] = result.get('images', [])
            
            cursor.close()
            return results

        except Error as e:
            print(f"Error searching properties: {e}")
            return []

    def get_property_details(self, property_id):
        if not self.connection or not self.connection.is_connected():
            if not self.connect():
                return None

        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Get property with nearby places and transportation
            query = """
            SELECT p.*, u.full_name as owner_name, u.phone as owner_phone
            FROM properties p
            JOIN users u ON p.owner_id = u.id
            WHERE p.id = %s
            """
            
            cursor.execute(query, (property_id,))
            property_data = cursor.fetchone()
            
            if property_data:
                # Process JSON fields
                if property_data['amenities']:
                    property_data['amenities'] = json.loads(property_data['amenities'])
                if property_data['images']:
                    property_data['images'] = json.loads(property_data['images'])
                
                # Get nearby places
                cursor.execute("""
                    SELECT place_name, place_type, distance_meters 
                    FROM nearby_places 
                    WHERE property_id = %s
                """, (property_id,))
                property_data['nearby_places'] = cursor.fetchall()
                
                # Get transportation options
                cursor.execute("""
                    SELECT transport_type, details 
                    FROM transportation 
                    WHERE property_id = %s
                """, (property_id,))
                property_data['transportation'] = cursor.fetchall()
            
            cursor.close()
            return property_data

        except Error as e:
            print(f"Error getting property details: {e}")
            return None

    def log_conversation(self, user_id, session_id, user_message, bot_response, intent, confidence, entities):
        if not self.connection or not self.connection.is_connected():
            if not self.connect():
                return

        try:
            cursor = self.connection.cursor()
            query = """
            INSERT INTO bot_conversations 
            (user_id, session_id, user_message, bot_response, intent, confidence, entities)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(query, (user_id, session_id, user_message, bot_response, intent, confidence, json.dumps(entities)))
            cursor.close()
        except Error as e:
            print(f"Error logging conversation: {e}")

    def log_search_analytics(self, user_id, location, budget, preferences, results_count):
        if not self.connection or not self.connection.is_connected():
            if not self.connect():
                return

        try:
            cursor = self.connection.cursor()
            query = """
            INSERT INTO search_analytics 
            (user_id, search_location, search_budget, search_preferences, results_count)
            VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(query, (user_id, location, budget, json.dumps(preferences) if preferences else None, results_count))
            cursor.close()
        except Error as e:
            print(f"Error logging search analytics: {e}")

# Global database instance
db = DatabaseConnection()
