import shutil
import os
from datetime import datetime
from src.config import ProjectConfig

def backup_raw_data(source_file_path):
    """Create a timestamped backup of raw data file"""
    config = ProjectConfig()
    
    if not os.path.exists(source_file_path):
        print(f"Source file not found: {source_file_path}")
        return False
    
    # Create backup directory if it doesn't exist
    os.makedirs(config.backup_dir, exist_ok=True)
    
    # Generate backup filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.basename(source_file_path)
    backup_filename = f"{timestamp}_{filename}"
    backup_path = os.path.join(config.backup_dir, backup_filename)
    
    try:
        # Copy file to backup location
        shutil.copy2(source_file_path, backup_path)
        print(f"Backup created: {backup_path}")
        
        # Also copy to raw data directory for ETL processing
        raw_data_path = os.path.join(config.raw_data_dir, filename)
        shutil.copy2(source_file_path, raw_data_path)
        print(f"Data copied to: {raw_data_path}")
        
        return True
        
    except Exception as e:
        print(f"Backup failed: {e}")
        return False

if __name__ == "__main__":
    # Replace with your actual source file path
    source_file = input("Enter the path to your raw data CSV file: ")
    backup_raw_data(source_file)