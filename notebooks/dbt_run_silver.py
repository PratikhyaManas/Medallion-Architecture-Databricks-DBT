# Databricks notebook source
# This notebook runs dbt models for the Silver layer

dbutils.widgets.text("catalog", "streaming_dev")
catalog = dbutils.widgets.get("catalog")

print(f"Starting dbt run for Silver layer in catalog: {catalog}")

import subprocess
import sys

try:
    import dbt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "dbt-databricks", "dbt-utils"])
    import dbt

try:
    # Run dbt run for silver layer
    result = subprocess.run([
        "dbt", "run",
        "--profiles-dir", "/root/.dbt",
        "--target", "dev",
        "--select", "020_silver"
    ], capture_output=True, text=True)
    
    print("STDOUT:")
    print(result.stdout)
    print("\nSTDERR:")
    print(result.stderr)
    print(f"\nReturn code: {result.returncode}")
    
    if result.returncode == 0:
        print("✅ Silver layer built successfully")
    else:
        print("❌ Silver layer build failed")
        dbutils.notebook.exit("Silver build failed")
        
except Exception as e:
    print(f"❌ Error running dbt: {str(e)}")
    dbutils.notebook.exit(f"Error: {str(e)}")
