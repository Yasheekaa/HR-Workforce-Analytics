# Power BI Dashboard Notes

File: `hr_analytics.pbix` (3 pages). The data comes from SQL Server (`localhost\SQLEXPRESS`, database `hr_analytics`),
tables `hr_data` and `recruitment_data`, loaded from `clean_data/` with the last section of the notebook.

| Page | What it shows |
| :--- | :--- |
| Workforce Overview | Active employees, average tenure, average rating, headcount by department, gender, age group, pay zone |
| Attrition & Retention | Attrition rate and count, survey score averages, attrition by department, gender, age group, performance, pay zone, tenure and training outcome |
| Recruitment Pipeline | Total applicants, offers, average desired salary and experience, applicants by status and education level |

## DAX measures

```dax
-- hr_data
Active Employees    = CALCULATE(COUNT(hr_data[EmpID]), hr_data[EmployeeStatus] = "Active")
Avg Tenure          = ROUND(AVERAGE(hr_data[Tenure_Years]), 1)
Avg Rating          = ROUND(AVERAGE(hr_data[Current Employee Rating]), 1)
Attrition Count     = SUM(hr_data[Attrition_Flag])
Attrition Rate      = DIVIDE(
                          CALCULATE(COUNTROWS(hr_data),
                              hr_data[EmployeeStatus] = "Voluntarily Terminated"
                              || hr_data[EmployeeStatus] = "Terminated for Cause"),
                          COUNTROWS(hr_data)) * 100
Avg Engagement      = AVERAGE(hr_data[Engagement Score])
Avg Satisfaction    = AVERAGE(hr_data[Satisfaction Score])
Avg WLB             = AVERAGE(hr_data[Work-Life Balance Score])
Training Pass Rate  = DIVIDE(
                          CALCULATE(COUNT(hr_data[Training Outcome]), hr_data[Training Outcome] = "Passed"),
                          COUNT(hr_data[Training Outcome])) * 100
Avg Training Cost   = AVERAGE(hr_data[Training Cost])
Avg Training Days   = AVERAGE(hr_data[Training Duration(Days)])
Voluntary Terminations = CALCULATE(COUNT(hr_data[EmpID]), hr_data[EmployeeStatus] = "Voluntarily Terminated")
Terminated for Cause   = CALCULATE(COUNT(hr_data[EmpID]), hr_data[EmployeeStatus] = "Terminated for Cause")

-- recruitment_data
Total Applicants    = COUNT(recruitment_data[Applicant ID])
Offered Count       = CALCULATE(COUNT(recruitment_data[Applicant ID]), recruitment_data[Status] = "Offered")
Rejected Count      = CALCULATE(COUNT(recruitment_data[Applicant ID]), recruitment_data[Status] = "Rejected")
Interview Count     = CALCULATE(COUNT(recruitment_data[Applicant ID]), recruitment_data[Status] = "Interviewing")
Avg Desired Salary  = AVERAGE(recruitment_data[Desired Salary])
Avg Experience      = AVERAGE(recruitment_data[Years of Experience])
Pipeline %          = DIVIDE(COUNT(recruitment_data[Applicant ID]),
                          CALCULATE(COUNT(recruitment_data[Applicant ID]), ALL(recruitment_data))) * 100
```

## Problems I found in version 1 (and how to fix them)

While reviewing the project I found these issues in the first version of the dashboard.
The screenshots in `screenshots/` are still from version 1.

| # | Problem | Why it happened | Fix |
| :- | :--- | :--- | :--- |
| 1 | The Attrition page showed **12.87%** attrition but **1K** terminated employees, the two numbers did not match | `Attrition_Flag` in the SQL table was made from `TerminationType`, which is filled for active employees too (about 51% "left"), while the Attrition Rate measure used `EmployeeStatus` | The notebook now makes `Attrition_Flag` from `EmployeeStatus` (387 leavers, 12.9%). Reload the tables and refresh |
| 2 | 707 employees were missing from every visual | Power Query had a step `Filtered Rows` that removed rows where `Age_Group` was null, and the old age bins stopped at 70 | New age groups cover everyone (18-30 ... 60+). Delete the `Filtered Rows` step in Power Query |
| 3 | `Offer Rate` and `Rejected Rate` always gave 0 | They filtered `recruitment_data[State]` (the US state column) instead of `[Status]` | Use the corrected measures below |
| 4 | Tenure vs Attrition line chart was wrong | Tenure was calculated from today's date, even for people who already left | Tenure now stops at `ExitDate` for leavers. Use the new `Tenure_Band` column on the axis |

Corrected measures:

```dax
Offer Rate =
DIVIDE(
    CALCULATE(COUNT(recruitment_data[Applicant ID]), recruitment_data[Status] = "Offered"),
    COUNT(recruitment_data[Applicant ID])
) * 100

Rejected Rate =
DIVIDE(
    CALCULATE(COUNT(recruitment_data[Applicant ID]), recruitment_data[Status] = "Rejected"),
    COUNT(recruitment_data[Applicant ID])
) * 100

-- simpler and matches Attrition Count now that the flag is correct
Attrition Rate = DIVIDE([Attrition Count], COUNTROWS(hr_data)) * 100
```

Expected numbers after the refresh (same as the notebook and `sql/hr_analytics.sql`):
3000 employees, 387 left, attrition rate 12.9%, highest department rates Software Engineering 17.4% and Production 15.9%.
