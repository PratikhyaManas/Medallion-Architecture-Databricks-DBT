# Databricks notebook source
# This notebook seeds raw data from CSV files into Databricks

dbutils.widgets.text("catalog", "streaming_dev")
catalog = dbutils.widgets.get("catalog")

print(f"Starting dbt seed for catalog: {catalog}")

# Install dbt if not already installed
import subprocess
import sys

try:
    import dbt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "dbt-databricks", "dbt-utils"])
    import dbt

try:
    # Run dbt seed command
    result = subprocess.run([
        "dbt", "seed",
        "--profiles-dir", "/root/.dbt",
        "--target", "dev",
        "--select", "raw_*"
    ], capture_output=True, text=True)
    
    print("STDOUT:")
    print(result.stdout)
    print("\nSTDERR:")
    print(result.stderr)
    print(f"\nReturn code: {result.returncode}")
    
    if result.returncode == 0:
        print("✅ dbt seed completed successfully")
    else:
        print("❌ dbt seed failed")
        dbutils.notebook.exit("dbt seed failed")
        
except Exception as e:
    print(f"❌ Error running dbt seed: {str(e)}")
    dbutils.notebook.exit(f"Error: {str(e)}")
