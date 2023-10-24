SELECT * FROM "HR";
DELETE FROM "HR";
/* DATA CLEANING*/

/*A. DATA CLEANING*/

/*1. Change date format*/

/*—birthdate*/

UPDATE "HR"
SET birthdate = CASE
WHEN birthdate LIKE '%/%'THEN TO_DATE(birthdate, 'MM/DD/YYYY')
WHEN birthdate LIKE '%-%'THEN TO_DATE(birthdate, 'MM/DD/YY')
END;
TO_CHAR(to_date(birthdate, 'MM/DD/YYYY'),'19YY-MM-DD')

/*Alter data structure*/
ALTER TABLE “HR” ALTER COLUMN birthdate TYPE DATE 
using to_date(birthdate, 'YYYY-MM-DD');

/*—hire_date*/

UPDATE "HR"
SET hire_date = CASE
WHEN  hire_date  LIKE '%/%'THEN TO_DATE(hire_date, 'MM/DD/YYYY')
WHEN  hire_date  LIKE '%-%'THEN TO_DATE(hire_date, 'MM/DD/YY')
END;
TO_CHAR(to_date(hire_date, 'MM/DD/YYYY'),'19YY-MM-DD')

/*Alter data structure*/
ALTER TABLE “HR” ALTER COLUMN hire_date TYPE DATE 
using to_date(hire_date, 'YYYY-MM-DD');


/*—termdate*/
UPDATE "HR"
SET termdate = TO_DATE(termdate, 'YYYY-MM-DD')  

/*Alter data structure*/
ALTER TABLE "HR" ALTER COLUMN termdate TYPE DATE 
using to_date(termdate, 'YYYY-MM-DD');


/*2. Calculate Age*/

ALTER TABLE "HR"
ADD COLUMN age INT;

UPDATE "HR"
SET age =  EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate))
;

/*There are some rows with negative age, figure out how many rows are there*/
SELECT COUNT(*)
FROM "HR"
WHERE AGE <= 0;

/* Modify the rows with negative row*/
UPDATE "HR"
SET new_birthdate = CASE
WHEN age < 0 THEN TO_DATE(TO_CHAR(birthdate - interval '100 years', 'YYYY-MM-DD'),'YYYY-MM-DD')
ELSE birthdate
END;

UPDATE "HR"
SET AGE = CASE 
WHEN age < 0
THEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, new_birthdate))
ELSE EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate))
END;


/*B. Answer questions*/
/*
1. What is the gender breakdown of employees in the company?
2. What is the race/ethnicity breakdown of employees in the company?
3. What is the age distribution of employees in the company?
4. How many employees work at headquarters versus remote locations?
5. What is the average length of employment for employees who have been terminated?
6. How does the gender distribution vary across departments and job titles?
7. What is the distribution of job titles across the company?
8. Which department has the highest turnover rate?
9. What is the distribution of employees across locations by state?
10. How has the company's employee count changed over time based on hire and term dates?
11. What is the tenure distribution for each department?
*/


/*1. What is the gender breakdown of employees in the company?*/
/* For the employees currently in the company*/

SELECT gender, COUNT(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY gender;


/* 2.What is the race/ethnicity breakdown of employees in the company?*/

SELECT race, COUNT(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY race
ORDER BY COUNT(*) DESC;

/*3. What is the age distribution of employees in the company?*/
SELECT CASE
WHEN age <= 24 THEN '18-24'
WHEN age <= 34 THEN '25-34'
WHEN age <= 44 THEN '35-44'
WHEN age <= 54 THEN '45-54'
WHEN age <= 64 THEN '55-64'
ELSE '65+'
END AS age_distribution, gender,COUNT(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY age_distribution, gender
ORDER BY age_distribution, gender ;


/* 4. How many employees work at headquarters versus remote locations?*/
SELECT age, COUNT(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY age
ORDER BY age DESC;

/* 5. What is the average length of employment for employees who have been terminated?*/
SELECT ROUND(AVG(termdate - hire_date)/365,0)
FROM "HR"
WHERE (termdate - CURRENT_DATE) < 0 AND (termdate IS NOT NULL);


/*6.How does the gender distribution vary across departments and job titles?*/

SELECT department, jobtitle, gender, count(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;


/*7.How does the gender distribution vary across departments and job titles?*/

SELECT jobtitle, count(*)
FROM "HR"
WHERE (termdate is null) OR (termdate - CURRENT_DATE) > 0
GROUP BY jobtitle
ORDER BY jobtitle DESC;

/*8. Which department has the highest turnover rate?*/
SELECT department,
total_count,
terminated_count,
ROUND(terminated_count / total_count, 3) AS terminated_rate
FROM (
SELECT department,
CAST(COUNT(*) AS NUMERIC) AS total_count,
CAST( SUM(CASE WHEN (termdate IS NOT null) OR (termdate - CURRENT_DATE) < 0 THEN 1 ELSE 0 END) AS NUMERIC) AS terminated_count
FROM "HR"
GROUP BY department
) AS subquery
ORDER BY terminated_rate DESC;


/* 9.What is the distribution of employees across locations by state? */

SELECT location_state, location_city, COUNT(*)
FROM "HR"
WHERE termdate IS NULL OR (termdate - CURRENT_DATE >0)
GROUP BY location_state, location_city
ORDER BY COUNT(*) DESC;



/*10. How has the company's employee count changed over time based on hire and term dates?*/
/* Using Temp Table */

CREATE TABLE employ_change(
	year NUMERIC(10,3),
	hires NUMERIC(10,3),
	terminations NUMERIC(10,3),
	net_change NUMERIC(10,3),
	net_change_percent NUMERIC(10,3)
);

INSERT INTO employ_change(year,hires, terminations, net_change, net_change_percent)
SELECT EXTRACT(year from hire_date) AS year
,COUNT(*) AS hires
,SUM(CASE WHEN (termdate IS NOT NULL) AND (termdate - CURRENT_DATE < 0 ) THEN 1 ELSE 0 END)  AS terminations
,(COUNT(*) - SUM(CASE WHEN (termdate IS NOT NULL) AND (termdate - CURRENT_DATE < 0 ) THEN 1 ELSE 0 END)) AS net_change
, 0.0 AS net_change_percent
FROM "HR"
GROUP BY year;

UPDATE employ_change
SET net_change_percent = (net_change/hires) * 100;

SELECT * 
FROM employ_change
ORDER BY year ASC;

/* 11. What is the tenure distribution for each department? */

SELECT department, ROUND(AVG((termdate - hire_date)/365),0)AS avg_tenure
FROM "HR"
WHERE termdate IS NOT NULL OR (termdate - CURRENT_DATE < 0) 
GROUP BY department
ORDER BY avg_tenure DESC;












































