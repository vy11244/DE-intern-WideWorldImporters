from airflow.models import Variable
import os 

SQL_PATH_FILE = "./include/sql/"
CSV_PATH_FILE = "./include/temp/"
JSON_PATH_FILE = "./include/json/"
DAG_PATH_FILE = "./include/dags/"
DEFAULT_LOG_PATH = "./include/log.txt"

DEFAULT_DELIMITER = "|"
LOGGING_TABLE_NAME = "METADATA.INTEGRATION.PL_LOGGING_TABLE"

LAKE_ADLS_VARIABLE_NAME = "LAKE_ADLS_CONN_ID"
SOURCE_MSSQL_VARIABLE_NAME = "SOURCE_MSSQL_CONN_ID"
BRONZE_SNOWFLAKE_VARIABLE_NAME = "BRONZE_SNOWFLAKE_CONN_ID"

AZURE_CONN_ID = Variable.get(LAKE_ADLS_VARIABLE_NAME)
MSSQL_CONN_ID = Variable.get(SOURCE_MSSQL_VARIABLE_NAME)
SNOWFLAKE_CONN_ID = Variable.get(BRONZE_SNOWFLAKE_VARIABLE_NAME)