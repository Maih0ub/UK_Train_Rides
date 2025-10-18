# 🚆 UK Train Rides Data Analysis Project

## 📌 Overview
This project analyzes **UK Train Rides dataset** using **SQL** and **Python (Pandas, Matplotlib)** to extract insights about train usage patterns, busiest routes, seasonal trends, and ticket behavior.

The analysis focuses on turning raw train data into meaningful insights through cleaning, visualization, and querying techniques.

---

## 🎯 Objectives
- Perform data cleaning and transformation using **Python & Pandas**.  
- Explore the dataset using **SQL queries**.  
- Visualize trends and insights using **Matplotlib**.  
- Identify the **busiest stations**, **peak travel times**, and **yearly patterns**.  
- Present a clean, reproducible analytical workflow.

---

## 🧰 Tools & Technologies
| Category | Tools Used |
|-----------|-------------|
| Data Source | CSV file (`UK Train Rides new.csv`) |
| Query Language | SQL |
| Data Analysis | Python, Pandas |
| Visualization | Matplotlib |
| Environment | VS Code / Jupyter Notebook / Google Colab |
| Version Control | Git & GitHub |

---

## 📊 Key Analysis Steps
1. **Data Cleaning**  
   - Handle missing and duplicate values.  
   - Convert date/time columns to correct formats.  
   - Normalize text columns (stations, routes, etc.).

2. **Exploratory Data Analysis (EDA)**  
   - Descriptive statistics (mean, median, mode).  
   - Frequency analysis of routes and stations.  
   - Time-based trends (monthly, daily, yearly).

3. **SQL Queries**  
   - Extract insights like busiest routes and total rides per month.  
   - Filter and aggregate data efficiently.

4. **Visualization**  
   - Line charts for time trends.  
   - Bar charts for station comparisons.  
   - Pie charts for category distributions.

---

## 🧠 Insights (Examples)
- 🚉 Top 5 busiest stations in the UK.  
- 📅 Peak months for train usage.  
- 💷 Relationship between route distance and ticket cost.  
- ⏰ Average ride duration by day of the week.

---

## 📂 Project Structure
```bash
UK_Train_Rides_Analysis/
│
├── data/
│   └── UK Train Rides new.csv
│
├── notebooks/
│   └── analysis.ipynb
│
├── sql/
│   └── train_queries.sql
│
├── visualizations/
│   ├── busiest_routes.png
│   └── monthly_trends.png
│
├── README.md
└── requirements.txt
