PhoenixAnalytics.Repo.execute_unsafe("INSTALL httpfs;")
PhoenixAnalytics.Repo.execute_unsafe("LOAD httpfs;")

PhoenixAnalytics.Repo.execute_unsafe("INSTALL aws;")
PhoenixAnalytics.Repo.execute_unsafe("LOAD aws;")

PhoenixAnalytics.Repo.execute_unsafe("INSTALL parquet;")
PhoenixAnalytics.Repo.execute_unsafe("LOAD parquet;")

PhoenixAnalytics.Repo.execute_unsafe("SET s3_region='us-east-1';")
PhoenixAnalytics.Repo.execute_unsafe("SET s3_url_style='path';")
PhoenixAnalytics.Repo.execute_unsafe("SET s3_endpoint='127.0.0.1:9000';")
PhoenixAnalytics.Repo.execute_unsafe("SET s3_use_ssl = false;")
PhoenixAnalytics.Repo.execute_unsafe("SET s3_access_key_id='mBcDR5Wy1JlZyTFEIccf' ;")

PhoenixAnalytics.Repo.execute_unsafe(
  "SET s3_secret_access_key='ndr2cAKIpNSv3sk1inBPfnILzEk56UpciM4HFiUG';"
)

# query = "COPY requests TO 's3://test/analytics.parquet';"
# {:ok, ref} = PhoenixAnalytics.Repo.execute_unsafe(query)
# Duckdbex.fetch_all(ref) |> IO.inspect()

query = "SELECT count(*) FROM 's3://test/analytics.parquet' WHERE method = 'GET';"
{:ok, ref} = PhoenixAnalytics.Repo.execute_unsafe(query)
Duckdbex.fetch_all(ref) |> IO.inspect()
