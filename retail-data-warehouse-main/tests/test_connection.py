import sys
import os
import psycopg2

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.config import get_db_connection_string


#from src.config import get_db_connection_string

def test_database_connection():
    """Test database connection and basic functionality"""
    try:
        # Attempt connection
        conn = psycopg2.connect(get_db_connection_string())
        cursor = conn.cursor()
        
        # Test basic query
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()
        print(f"Connected to: {db_version[0]}")
        
        # Test schema creation
        cursor.execute("""
            SELECT schema_name 
            FROM information_schema.schemata 
            WHERE schema_name IN ('staging', 'analytics', 'utils');
        """)
        schemas = cursor.fetchall()
        print(f"Found {len(schemas)} expected schemas")
        
        # Clean up
        cursor.close()
        conn.close()
        print("Database connection test PASSED")
        return True
        
    except Exception as e:
        print(f"Database connection test FAILED: {e}")
        return False

if __name__ == "__main__":
    test_database_connection()