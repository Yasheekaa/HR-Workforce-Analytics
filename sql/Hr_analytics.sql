-- Check HR Attrition Metrics
SELECT 
    COUNT(*) AS total_employees, 
    SUM(Attrition_Flag) AS total_terminated, 
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct 
FROM hr_data;

-- Check Recruitment Pipeline Summary
SELECT 
    Status, 
    COUNT(*) AS total_candidates 
FROM recruitment_data 
GROUP BY Status;

-- 1. Overall Attrition Rate
SELECT 
  COUNT(*) AS total_employees,
  SUM(Attrition_Flag) AS terminated,
  ROUND(SUM(Attrition_Flag)*100.0/COUNT(*), 2) AS attrition_rate_pct
FROM hr_data;

-- 2. Attrition by Department
SELECT DepartmentType,
  COUNT(*) AS total,
  SUM(Attrition_Flag) AS terminated,
  ROUND(SUM(Attrition_Flag)*100.0/COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY DepartmentType
ORDER BY rate_pct DESC;

-- 3. Attrition by Gender
SELECT GenderCode,
  COUNT(*) AS total,
  SUM(Attrition_Flag) AS terminated,
  ROUND(SUM(Attrition_Flag)*100.0/COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY GenderCode;

-- 4. Attrition by Performance Score
SELECT 
    [Performance Score],
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS terminated,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY [Performance Score]
ORDER BY rate_pct DESC;
-- 5. Attrition by Age Group
SELECT 
    Age_Group,
    COUNT(*) AS total,
    SUM(Attrition_Flag) AS terminated,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS rate_pct
FROM hr_data
WHERE Age_Group IS NOT NULL
GROUP BY Age_Group
ORDER BY Age_Group;

-- 6. Avg Engagement Score — Active vs Terminated
SELECT 
    EmployeeStatus,
    ROUND(AVG([Engagement Score]), 2) AS avg_engagement,
    ROUND(AVG([Satisfaction Score]), 2) AS avg_satisfaction,
    ROUND(AVG([Work-Life Balance Score]), 2) AS avg_wlb
FROM hr_data
GROUP BY EmployeeStatus;
-- 7. Training Outcome vs Attrition
SELECT [Training Outcome],
  COUNT(*) AS total,
  SUM(Attrition_Flag) AS terminated,
  ROUND(SUM(Attrition_Flag)*100.0/COUNT(*), 2) AS rate_pct
FROM hr_data
GROUP BY [Training Outcome];

-- 8. Recruitment Pipeline
SELECT Status,
  COUNT(*) AS applicants,
  ROUND(AVG([Years of Experience]), 1) AS avg_experience,
  ROUND(AVG([Desired Salary]), 2) AS avg_desired_salary
FROM recruitment_data
GROUP BY Status
ORDER BY applicants DESC;

-- 9. Attrition Rate by Tenure Length
-- Purpose: Identifies key risk years when employees are most likely to leave.
-- Business Context: Helps HR target retention efforts toward staff reaching critical tenure milestones.
SELECT 
    Tenure_Years,
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS terminated_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY Tenure_Years
ORDER BY Tenure_Years;



-- 10. Training Program Cost & Duration vs. Employee Retention
-- Purpose: Evaluates ROI on L&D programs to see if training investment correlates with lower turnover.
-- Business Context: Informs future budget allocation for training modules and vendor selections.
SELECT 
    [Training Program Name],
    COUNT(*) AS total_trainees,
    SUM(Attrition_Flag) AS terminated_count,
    ROUND(AVG([Training Cost]), 2) AS avg_training_cost_usd,
    ROUND(AVG([Training Duration(Days)]), 1) AS avg_duration_days,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY [Training Program Name]
ORDER BY attrition_rate_pct DESC;



-- 11. Attrition Breakdown by Pay Zone & Employment Type
-- Purpose: Analyzes turnover patterns across compensation zones and employment models (Contract vs. Full-Time).
-- Business Context: Highlights pay disparity issues or instability within specific employment categories.
SELECT 
    PayZone,
    EmployeeType,
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS terminated_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
GROUP BY PayZone, EmployeeType
ORDER BY PayZone, EmployeeType;



-- 12. Early Warning Analysis: Disengaged Employees at Risk
-- Purpose: Isolates staff with low survey scores (Engagement <= 2) and checks their performance ratings.
-- Business Context: Allows managers to intervene proactively before disengaged employees quit.
SELECT 
    [Performance Score],
    [Engagement Score],
    COUNT(*) AS total_employees,
    SUM(Attrition_Flag) AS terminated_count,
    ROUND(SUM(Attrition_Flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM hr_data
WHERE [Engagement Score] <= 2
GROUP BY [Performance Score], [Engagement Score]
ORDER BY attrition_rate_pct DESC;



-- 13. Recruitment Pipeline: Applicant Qualifications & Salary Expectations
-- Purpose: Compares candidate work experience and requested salaries across education levels.
-- Business Context: Helps Talent Acquisition build realistic salary bands for open requisitions.
SELECT 
    [Education Level],
    COUNT(*) AS total_applicants,
    ROUND(AVG([Years of Experience]), 1) AS avg_experience_years,
    ROUND(AVG([Desired Salary]), 2) AS avg_desired_salary
FROM recruitment_data
GROUP BY [Education Level]
ORDER BY avg_desired_salary DESC;



-- 14 Hiring Funnel Breakdown & Conversion
-- Purpose: Tracks candidate distribution across pipeline stages (Applied, Interviewing, Offered, etc.).
-- Business Context: Identifies recruitment bottlenecks and measures overall funnel efficiency.
SELECT 
    Status,
    COUNT(*) AS candidate_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM recruitment_data), 2) AS pct_of_pipeline
FROM recruitment_data
GROUP BY Status
ORDER BY candidate_count DESC;
