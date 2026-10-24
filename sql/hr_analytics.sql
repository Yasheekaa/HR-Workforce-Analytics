/* =========================================================
   HR Workforce Analytics - SQL Analysis
   Database : hr_analytics (SQL Server Express / SSMS)
   Tables   : hr_data           -> clean_data/cleaned_hr_data.csv
              recruitment_data  -> clean_data/cleaned_recruitment.csv
   The tables are loaded with the last section of eda/eda_analysis.ipynb
   Author   : Yashika Singh
   ========================================================= */

USE hr_analytics;
GO


/* ---------------------------------------------------------
   PART 0 : DATA CHECKS (run these first after loading)
   --------------------------------------------------------- */

-- 0.1 Row count of both tables (should be 3000 each)
SELECT 'hr_data' AS table_name, COUNT(*) AS total_rows FROM hr_data
UNION ALL
SELECT 'recruitment_data', COUNT(*) FROM recruitment_data;

-- 0.2 Duplicate employee ids (should return nothing)
SELECT EmpID, COUNT(*) AS times_found
FROM hr_data
GROUP BY EmpID
HAVING COUNT(*) > 1;

-- 0.3 Missing values in the important columns
SELECT
    SUM(CASE WHEN StartDate IS NULL THEN 1 ELSE 0 END)          AS missing_start_date,
    SUM(CASE WHEN DepartmentType IS NULL THEN 1 ELSE 0 END)     AS missing_department,
    SUM(CASE WHEN [Engagement Score] IS NULL THEN 1 ELSE 0 END) AS missing_engagement,
    SUM(CASE WHEN [Training Outcome] IS NULL THEN 1 ELSE 0 END) AS missing_training
FROM hr_data;

-- 0.4 Check that Attrition_Flag matches EmployeeStatus
-- (only Voluntarily Terminated and Terminated for Cause should have flag = 1)
SELECT EmployeeStatus, Attrition_Flag, COUNT(*) AS employees
FROM hr_data
GROUP BY EmployeeStatus, Attrition_Flag
ORDER BY Attrition_Flag DESC, employees DESC;


/* ---------------------------------------------------------
   PART 1 : ATTRITION KPIs
   --------------------------------------------------------- */

-- 1. Overall Attrition Rate
SELECT
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS total_left,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data;

-- 2. Attrition by Department (with rank)
SELECT
    DepartmentType,
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct,
    RANK() OVER (ORDER BY SUM(Attrition_Flag) * 100.0 / COUNT(*) DESC) AS rate_rank
FROM hr_data
GROUP BY DepartmentType
ORDER BY rate_rank;

-- 3. Attrition by Gender
SELECT
    GenderCode,
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY GenderCode;

-- 4. Attrition by Performance Score
SELECT
    [Performance Score],
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY [Performance Score]
ORDER BY rate_pct DESC;

-- 5. Attrition by Age Group
-- (every employee has an age group now, the old 20-70 bins left 707 people as NULL)
SELECT
    Age_Group,
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY Age_Group
ORDER BY Age_Group;

-- 6. Average survey scores: employees who left vs stayed
SELECT
    CASE WHEN Attrition_Flag = 1 THEN 'Left' ELSE 'Stayed' END AS employee_group,
    COUNT(*) AS employees,
    ROUND(AVG(CAST([Engagement Score] AS FLOAT)), 2)        AS avg_engagement,
    ROUND(AVG(CAST([Satisfaction Score] AS FLOAT)), 2)      AS avg_satisfaction,
    ROUND(AVG(CAST([Work-Life Balance Score] AS FLOAT)), 2) AS avg_wlb
FROM hr_data
GROUP BY CASE WHEN Attrition_Flag = 1 THEN 'Left' ELSE 'Stayed' END;

-- 7. Training Outcome vs Attrition
SELECT
    [Training Outcome],
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY [Training Outcome]
ORDER BY rate_pct DESC;

-- 8. Attrition by Tenure Band
-- Purpose: shows in which year of service people leave the most.
-- Tenure_Band is created in the notebook (<1 yr, 1-2 yrs, 2-3 yrs, 3-4 yrs, 4+ yrs)
SELECT
    Tenure_Band,
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(Tenure_Years), 2) AS avg_tenure_years
FROM hr_data
GROUP BY Tenure_Band
ORDER BY avg_tenure_years;

-- 9. Training Program Cost & Duration vs Attrition
-- Purpose: checks if the more expensive programs keep people for longer.
SELECT
    [Training Program Name],
    COUNT(*) AS total_trainees,
    SUM(Attrition_Flag) AS left_count,
    ROUND(AVG([Training Cost]), 2) AS avg_training_cost_usd,
    ROUND(AVG(CAST([Training Duration(Days)] AS FLOAT)), 1) AS avg_duration_days,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY [Training Program Name]
ORDER BY attrition_rate_pct DESC;

-- 10. Attrition by Pay Zone & Employment Type
SELECT
    PayZone,
    EmployeeType,
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY PayZone, EmployeeType
ORDER BY PayZone, EmployeeType;

-- 11. Engagement level buckets vs Attrition
-- Purpose: groups the 1-5 score into Low / Medium / High to check if low engagement means more exits.
-- Result: the rate is almost the same in every bucket, so engagement alone is not a good warning sign here.
SELECT
    CASE
        WHEN [Engagement Score] <= 2 THEN '1. Low (1-2)'
        WHEN [Engagement Score] = 3 THEN '2. Medium (3)'
        ELSE '3. High (4-5)'
    END AS engagement_level,
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY
    CASE
        WHEN [Engagement Score] <= 2 THEN '1. Low (1-2)'
        WHEN [Engagement Score] = 3 THEN '2. Medium (3)'
        ELSE '3. High (4-5)'
    END
ORDER BY engagement_level;

-- 12. Low engagement employees by Performance Score
-- Purpose: finds good performers who are disengaged, so managers can talk to them early.
SELECT
    [Performance Score],
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
WHERE [Engagement Score] <= 2
GROUP BY [Performance Score]
ORDER BY attrition_rate_pct DESC;

-- 13. Top 5 job titles by attrition rate (only titles with 20+ employees)
WITH title_stats AS (
    SELECT
        Title,
        COUNT(*) AS total_employees,
        SUM(Attrition_Flag) AS left_count,
        ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
    FROM hr_data
    GROUP BY Title
    HAVING COUNT(*) >= 20
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY attrition_rate_pct DESC) AS rate_rank
    FROM title_stats
)
SELECT Title, total_employees, left_count, attrition_rate_pct, rate_rank
FROM ranked
WHERE rate_rank <= 5
ORDER BY rate_rank;

-- 14. Hires vs exits per year with running net change
-- Purpose: shows if the company is growing or if exits are catching up with hiring.
WITH hires AS (
    SELECT YEAR(StartDate) AS year_no, COUNT(*) AS hires
    FROM hr_data
    GROUP BY YEAR(StartDate)
),
exits AS (
    SELECT YEAR(ExitDate) AS year_no, COUNT(*) AS exits
    FROM hr_data
    WHERE Attrition_Flag = 1
    GROUP BY YEAR(ExitDate)
)
SELECT
    h.year_no,
    h.hires,
    COALESCE(e.exits, 0) AS exits,
    h.hires - COALESCE(e.exits, 0) AS net_change,
    SUM(h.hires - COALESCE(e.exits, 0)) OVER (ORDER BY h.year_no) AS running_net_change
FROM hires h
LEFT JOIN exits e ON h.year_no = e.year_no
ORDER BY h.year_no;


/* ---------------------------------------------------------
   PART 2 : RECRUITMENT
   --------------------------------------------------------- */

-- 15. Hiring Funnel Breakdown (share of each status)
SELECT
    Status,
    COUNT(*) AS candidate_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recruitment_data), 2) AS pct_of_pipeline
FROM recruitment_data
GROUP BY Status
ORDER BY candidate_count DESC;

-- 16. Experience and desired salary by Status
SELECT
    Status,
    COUNT(*) AS applicants,
    ROUND(AVG(CAST([Years of Experience] AS FLOAT)), 1) AS avg_experience,
    ROUND(AVG([Desired Salary]), 2) AS avg_desired_salary
FROM recruitment_data
GROUP BY Status
ORDER BY applicants DESC;

-- 17. Offer rate by Education Level
-- Note: the Offer Rate measure in Power BI was filtering on [State] (US state) instead of [Status],
-- I used this query to get the correct numbers.
SELECT
    [Education Level],
    COUNT(*) AS total_applicants,
    SUM(CASE WHEN Status = 'Offered' THEN 1 ELSE 0 END) AS offered,
    ROUND(SUM(CASE WHEN Status = 'Offered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS offer_rate_pct,
    ROUND(AVG(CAST([Years of Experience] AS FLOAT)), 1) AS avg_experience_years,
    ROUND(AVG([Desired Salary]), 2) AS avg_desired_salary
FROM recruitment_data
GROUP BY [Education Level]
ORDER BY offer_rate_pct DESC;

-- 18. Applications per month
SELECT
    YEAR([Application Date]) AS app_year,
    MONTH([Application Date]) AS app_month,
    COUNT(*) AS applications,
    SUM(CASE WHEN Status = 'Offered' THEN 1 ELSE 0 END) AS offers
FROM recruitment_data
GROUP BY YEAR([Application Date]), MONTH([Application Date])
ORDER BY app_year, app_month;


/* ---------------------------------------------------------
   PART 3 : VIEW FOR POWER BI
   One row per department, so the dashboard does not need to repeat the same logic.
   --------------------------------------------------------- */
GO
DROP VIEW IF EXISTS vw_department_summary;
GO
CREATE VIEW vw_department_summary AS
SELECT
    DepartmentType,
    COUNT(*) AS headcount,
    SUM(CASE WHEN Attrition_Flag = 0 THEN 1 ELSE 0 END) AS still_working,
    SUM(Attrition_Flag) AS left_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(Tenure_Years), 2) AS avg_tenure_years,
    ROUND(AVG(CAST([Engagement Score] AS FLOAT)), 2) AS avg_engagement
FROM hr_data
GROUP BY DepartmentType;
GO

SELECT * FROM vw_department_summary ORDER BY attrition_rate_pct DESC;
