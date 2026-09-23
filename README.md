# CRM Sales Opportunities Analysis
Business analysis of CRM sales opportunities using SQL, Python and statistical analysis.

## Business Question

Given a large number of opportunities in the CRM, how should sales management improve opportunity conversion and prioritize its sales efforts?

## Project Overview

This project analyzes a CRM sales opportunities dataset
to identify factors associated with opportunity win rates.

The analysis combines SQL-based exploration with Python
and statistical modeling.

## Tools

- PostgreSQL
- SQL
- Python
- Pandas
- Statsmodels

## Data

The analysis uses the CRM Sales Opportunities dataset.

The dataset is not included in this repository. To reproduce the analysis, download the original dataset from [dataset source](https://www.kaggle.com/datasets/nilkamalsaha/crm-sales-opportunities-on-google-sheets) and place the CSV files in a folder named Sales Dataset/ in the project root.

The expected structure is:

```text
CRM_Sales_Analysis/
├── Sales Dataset/
│   ├── accounts.csv
│   ├── products.csv
│   ├── sales_pipeline.csv
│   └── sales_teams.csv
├── CRM_Sales_Report.ipynb
├── CRM_Sales_Analysis_Python.ipynb
└── sql/
    └── CRM_Sales_Analysis_SQL.sql
```

## Analysis Approach

1. Data preparation
2. Descriptive analysis
3. Win-rate analysis
4. Segmentation and drill-down
5. Logistic regression
6. Business interpretation

## Key Findings

- Timing matters: Q1 showed substantially higher conversion than other quarters.
- Context matters: Sales-cycle length was associated with conversion, but the relationship varied by quarter.
- Geography varies: Win rates differed meaningfully across customer office locations, though the causes are unclear.

## Project Structure

```text
Project Structure
CRM_Sales_Analysis/
├── Sales Dataset/                      # Downloaded separately
├── CRM_Sales_Report.ipynb              # Final analysis report
├── CRM_Sales_Analysis_Python.ipynb     # Python analysis
└── sql/
    └── CRM_Sales_Analysis_SQL.sql      # SQL analysis
```

## Full Analysis

The final report and supporting technical analysis are provided above.
