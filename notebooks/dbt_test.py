# Databricks notebook source
# This notebook runs dbt tests on specified layer

dbutils.widgets.text("catalog", "streaming_dev")
dbutils.widgets.text("select", "*")

catalog = dbutils.widgets.get("catalog")
select = dbutils.widgets.get("select")

print(f"Starting dbt test for {select} in catalog: {catalog}")

import subprocess
import sys

try:
    import dbt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "dbt-databricks", "dbt-utils"])
    import dbt

try:
    # Run dbt test
    result = subprocess.run([
        "dbt", "test",
        "--profiles-dir", "/root/.dbt",
        "--target", "dev",
        "--select", select
    ], capture_output=True, text=True)
    
    print("STDOUT:")
    print(result.stdout)
    print("\nSTDERR:")
    print(result.stderr)
    print(f"\nReturn code: {result.returncode}")
    
    if result.returncode == 0:
        print(f"✅ All tests passed for {select}")
    else:
        print(f"❌ Some tests failed for {select}")
        dbutils.notebook.exit(f"Tests failed for {select}")
        
except Exception as e:
    print(f"❌ Error running dbt test: {str(e)}")
    dbutils.notebook.exit(f"Error: {str(e)}")
