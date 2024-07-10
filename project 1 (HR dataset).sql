CREATE DATABASE projects;

USE projects;

SELECT * FROM hr;

ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

DESCRIBE hr;

SELECT birthdate FROM hr;

SET sql_safe_updates=0;

UPDATE hr
SET birthdate = CASE
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

SELECT birthdate FROM hr;

-- modify column data type from text to date
ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

SELECT birthdate from hr;

UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- DISABLE STRICT MODE
SET @@global.sql_mode = 'NO_ENGINE_SUBSTITUTION';
SET @@session.sql_mode = 'NO_ENGINE_SUBSTITUTION';


UPDATE hr
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL ;

UPDATE hr
SET termdate='0000-00-00' WHERE termdate is NULL;


SELECT termdate FROM hr;

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- Step 1: Identify problematic rows
SELECT * FROM hr WHERE termdate = '';

-- Step 2: Update empty strings to NULL
UPDATE hr SET termdate = NULL WHERE termdate = '';

-- Step 3: Modify the column type
ALTER TABLE hr MODIFY COLUMN termdate DATE;

ALTER TABLE hr ADD COLUMN age INT;

SELECT birthdate, age FROM hr;

-- calculate age
UPDATE hr
SET age = timestampdiff(YEAR, birthdate, CURDATE());

SELECT 
	MIN(age) AS youngest,
    MAX(age) AS oldest
FROM hr;

-- check range <0 >18
SELECT COUNT(*) FROM hr WHERE age <18;
SELECT COUNT(*) FROM hr WHERE age >=18;

SELECT termdate FROM hr;
-- ^ termdate contains missing value, need to replace with valid, as in NULL
UPDATE hr
	SET termdate = '0000-00-00' WHERE termdate=NULL;

select termdate FROM hr;

-- QUESTIONS 
-- 1. What is the gender breakdown of employees in the company ?
SELECT gender, count(*) AS count 
FROM hr 
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, COUNT(*) AS COUNT
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY race 
ORDER BY COUNT DESC;
-- 3. What is the age distribution of employees in the company?
SELECT 
	min(age) AS youngest,
    max(age) AS oldest
FROM hr 
WHERE age >=18 AND termdate='0000-00-00';


SELECT 
	CASE 
		 WHEN age>=18 AND age <=24 THEN '18-24'
		 WHEN age>=25 AND age <=34 THEN '25-34'
		 WHEN age>=35 AND age <=44 THEN '35-44'
		 WHEN age>=45 AND age <=54 THEN '45-54'
		 WHEN age>=55 AND age <=64 THEN '55-64'
		 ELSE '65+'
     END AS age_group,
     count(*) AS COUNT
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY age_group
ORDER BY age_group;

SELECT 
	CASE 
		 WHEN age>=18 AND age <=24 THEN '18-24'
		 WHEN age>=25 AND age <=34 THEN '25-34'
		 WHEN age>=35 AND age <=44 THEN '35-44'
		 WHEN age>=45 AND age <=54 THEN '45-54'
		 WHEN age>=55 AND age <=64 THEN '55-64'
		 ELSE '65+'
     END AS age_group, gender,
     count(*) AS COUNT
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY age_group,gender
ORDER BY age_group,gender;

-- 4. How many employees work at headquarters versus remote locations?
SELECT location, COUNT(*) AS COUNT
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY location;

-- 5. What is the average length of employment for employees who have been terminated?
SELECT 
  ROUND(AVG(DATEDIFF(termdate, hire_date)) / 365,0) AS avg_length_employment
FROM hr
WHERE termdate <= CURDATE() 
  AND termdate <> '0000-00-00' 
  AND age >= 18;

-- 6. How does the gender distribution vary across departments and job titles?
SELECT department, gender, count(*) AS count
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY department, gender
ORDER BY department;

-- 7. What is the distribution of job titles across the company?
SELECT jobtitle, count(*) AS count
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- 8. Which department has the highest turnover rate?
SELECT department,
total_count,
terminated_count, 
terminated_count/total_count AS termination_rate
FROM (
	SELECT department, count(*) AS total_count,
	SUM(CASE WHEN termdate <> '0000-00-00' AND termdate<=curdate() THEN 1 ELSE 0 END) AS terminated_count
    FROM hr
    WHERE age>=18
    GROUP BY department
    ) as subquery
ORDER BY termination_rate DESC;

-- 9. What is the distribution of employees across locations by city and state?
SELECT location_state, COUNT(*) AS count
FROM hr
WHERE age >=18 AND termdate='0000-00-00'
GROUP BY location_state
ORDER BY count DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?
SELECT 
  year,
  hires,
  terminations,
  hires-terminations AS net_change,
  round((hires-terminations)/hires*100,2) AS net_change_percent
FROM(
	SELECT 
    YEAR(hire_date) AS YEAR,
    count(*) AS hires,
    SUM(CASE WHEN termdate<> '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminations
	FROM hr
    WHERE age>=18
    GROUP BY YEAR (hire_date)
    ) AS subquery
ORDER BY year ASC;
-- 11. What is the tenure distribution for each department?
SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM hr
WHERE termdate <= curdate() AND TERMDATE<>'0000-00-00' AND age>=18
GROUP BY department;
