import argparse
import os
from time import time

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, MetaData

load_dotenv()


class DBArgs:
    def __init__(self, file: str, table: str, overwrite: bool):
        self.file = file
        self.table = table
        self.overwrite = overwrite
        self.db_user = self._parse_envvar("POSTGRES_USER")
        self.db_pass = self._parse_envvar("POSTGRES_PASSWORD")
        self.db_name = self._parse_envvar("POSTGRES_DB")
        self.db_host = self._parse_envvar("POSTGRES_HOST")
        self.db_port = self._parse_envvar("POSTGRES_PORT")

    def _parse_envvar(self, var_name: str) -> str:
        value = os.getenv(var_name)
        if not value:
            missing_var_msg = "Environment variable {} not provided or empty"
            raise EnvironmentError(missing_var_msg.format(var_name))
        return value


def main(args: DBArgs):
    # Establish connection with the DB
    DB_URI = f"postgresql+psycopg2://{args.db_user}:{args.db_pass}@{args.db_host}:{args.db_port}/{args.db_name}"
    engine = create_engine(DB_URI)

    # Check if the table already exists
    metadata = MetaData()
    metadata.reflect(bind=engine)

    if args.table in metadata.tables and not args.overwrite:
        print(
            f"Table '{args.table}' already exists. Use --overwrite to replace the data"
        )
        return

    # Import the data
    print(f"Reading data from '{args.file}'...")
    CHUNK_SIZE = 100_000
    df = pd.read_csv(args.file, compression="infer", chunksize=CHUNK_SIZE)

    # Write to the PostgreSQL table
    print("Writing data...")
    with engine.begin() as conn:
        for i, part in enumerate(df):
            action = "replace" if i == 0 else "append"

            start = time()
            part.to_sql(args.table, if_exists=action, con=conn)
            end = time()

            duration = end - start
            print(f"Written {part.shape[0]} rows... (took {duration:.4f} secs)")

    print("Writing successful.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example script for command-line argument parsing"
    )

    parser.add_argument(
        "--file",
        type=str,
        required=True,
        help="File to import into the DB. Can be CSV or Parquet, compressed or not.",
    )
    parser.add_argument(
        "--table",
        type=str,
        required=True,
        help="Name of the table to write the ingested data.",
    )
    parser.add_argument(
        "--overwrite",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Force overwriting the data if present on table",
    )

    args = parser.parse_args()
    args = DBArgs(file=args.file, table=args.table, overwrite=args.overwrite)
    main(args)
