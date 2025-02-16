# Workshop 1: dlt

- [Summary](#summary)
- [Homework answers](#homework-answers)

## Summary

This optional workshop introduced us to [dlt](https://dlthub.com/) for easier data loading from/to various sources (e.g. various hosted DBs, APIs, cloud services, etc).

The homework consisted on extracting data about the NYC Taxi dataset hosted by the DLT Team with a RESTful API into a DuckDB in-memory database for testing purposes. I completed it in the adjacent [notebook](./dlt-nytaxi-duckdb.ipynb).

**Bonus!** Since I work on a Linux machine, I try to make apps follow the XDG Base Directory specification. *dlt* creates a `~/.dlt` directory by default for storing pipelines' data. Fortunately, it can be overriden by using the environment variable `DLT_DATA_DIR=$XDG_DATA_HOME/dlt` and setting it into your shell's init file (*Fish* in my case) to comply with the spec. I intend to make a PR to consider the spec directly in the source code.

## Homework answers

### Q1. What is the most current version of dlt?

**A.** 1.6.1

### Q2. How many tables are loaded by the dlt pipeline?

**A.** 4 tables.

### Q3. What is the total number of records extracted by the pipeline?

**A.** 10,000 records.

### Q4. What is the average trip duration for all the records extracted and loaded?

**A.** 12.3049 minutes.
