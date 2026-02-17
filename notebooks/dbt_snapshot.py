# Databricks notebook source
# This notebook runs dbt snapshots for SCD Type-2 tracking

dbutils.widgets.text("catalog", "streaming_dev")
catalog = dbutils.widgets.get("catalog")

print(f"Starting dbt snapshot in catalog: {catalog}")

import subprocess
import sys

try:
    import dbt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "dbt-databricks", "dbt-utils"])
    import dbt

try:
    # Run dbt snapshot
    result = subprocess.run([
        "dbt", "snapshot",
        "--profiles-dir", "/root/.dbt",
        "--target", "dev"
    ], capture_output=True, text=True)
    
    print("STDOUT:")
    print(result.stdout)
    print("\nSTDERR:")
    print(result.stderr)
    print(f"\nReturn code: {result.returncode}")
    
    if result.returncode == 0:
        print("✅ Snapshots created successfully")
    else:
        print("❌ Snapshot creation failed")
        dbutils.notebook.exit("Snapshot failed")
        
except Exception as e:
    print(f"❌ Error running dbt snapshot: {str(e)}")
    dbutils.notebook.exit(f"Error: {str(e)}")
