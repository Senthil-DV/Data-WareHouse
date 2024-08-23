drop table dimdate cascade constraints;
CREATE TABLE DimDate (
    DateKey NUMBER,
    FullDate DATE,
    DayOfWeek NUMBER,
    DayName VARCHAR2(9),
    DayOfMonth NUMBER,
    DayOfYear NUMBER,
    WeekOfYear NUMBER,
    MonthName VARCHAR2(9),
    MonthOfYear NUMBER,
    Quarter NUMBER,
    YearNumber NUMBER,
    IsWeekday NUMBER(1),
    
    CONSTRAINT PK_DIMDATE PRIMARY KEY (DATEKEY)
);
CREATE OR REPLACE PROCEDURE Populate_DimDate
AS
BEGIN
    FOR i IN 0..9495 LOOP -- This will cover dates from 2005 to 2030
        INSERT INTO DimDate (
            DateKey,
            FullDate,
            DayOfWeek,
            DayName,
            DayOfMonth,
            DayOfYear,
            WeekOfYear,
            MonthName,
            MonthOfYear,
            Quarter,
            YearNumber,
            IsWeekday
        )
        VALUES (
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'YYYYMMDD')),
            DATE '2005-01-01' + i,
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'D')),
            RTRIM(TO_CHAR(DATE '2005-01-01' + i, 'Day')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'DD')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'DDD')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'WW')),
            RTRIM(TO_CHAR(DATE '2005-01-01' + i, 'Month')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'MM')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'Q')),
            TO_NUMBER(TO_CHAR(DATE '2005-01-01' + i, 'YYYY')),
            CASE WHEN TO_CHAR(DATE '2005-01-01' + i, 'D') IN ('1', '7') THEN 0 ELSE 1 END
        );
    END LOOP;
    COMMIT;
END;
/
EXEC Populate_DimDate;
CREATE INDEX idx_dimdate_fulldate ON DimDate(FullDate);

drop table Dim_Employee cascade constraints;
CREATE TABLE Dim_Employee (
   EmployeeKey NUMBER,
   EmployeeID NUMBER,
   FirstName VARCHAR2(50),
   LastName VARCHAR2(50),
   Email VARCHAR2(100),
   Phone VARCHAR2(20),
   HireDate DATE,
   TerminationDate DATE,
   CurrentFlag NUMBER(1),
   
   CONSTRAINT PK_DIMEMPLOYEE PRIMARY KEY (EmployeeKey),
   CONSTRAINT UK_DIMEMPLOYEE_EMAIL UNIQUE (EMAIL)
);

drop table Fact_Employee_Job cascade constraints;

CREATE TABLE Fact_Employee_Job (
    EmployeeJobKey NUMBER,
    EmployeeKey NUMBER,
    JobID VARCHAR(10),
    DepartmentID NUMBER,
    LocationID NUMBER,
    StartDateKey NUMBER,
    EndDateKey NUMBER,
    Salary NUMBER(10,2),
    Commission NUMBER(5,2),
    TotalSalary NUMBER(10,2),
    IsCurrent NUMBER(1),
       TotalDuration NUMBER,  
    PreviousJobID VARCHAR2(10) ,
    CONSTRAINT pk_factempjob PRIMARY KEY (EmployeeJobKey),
    CONSTRAINT fk_factempjob_employee FOREIGN KEY (EmployeeKey) REFERENCES Dim_Employee(EmployeeKey),
    CONSTRAINT fk_factempjob_job FOREIGN KEY (Jobid) REFERENCES Dim_Jobs(jobid),
    CONSTRAINT fk_factempjob_department FOREIGN KEY (DepartmentID) REFERENCES Dim_Department(Departmentid),
    CONSTRAINT fk_factempjob_location FOREIGN KEY (LocationID) REFERENCES Dim_Location(locationid),
    CONSTRAINT fk_factempjob_startdate FOREIGN KEY (StartDateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT fk_factempjob_enddate FOREIGN KEY (EndDateKey) REFERENCES DimDate(DateKey)
    
);

DROP TABLE DIM_LOCATION CASCADE CONSTRAINTS;

CREATE TABLE Dim_Location (
    LocationID NUMBER,
    StreetAddress VARCHAR2(40),
    PostalCode VARCHAR2(12),
    City VARCHAR2(30),
    StateProvince VARCHAR2(25),
    CountryName VARCHAR2(60),
    RegionName VARCHAR2(25),
    
    CONSTRAINT PK_DIM_LOCATION PRIMARY KEY (LocationID)
);

DROP TABLE DIM_JOBS CASCADE CONSTRAINTS;

CREATE TABLE Dim_Jobs (
    JobID VARCHAR2(10),
    JobTitle VARCHAR2(35),
    Min_Salary NUMBER(10,2),
    Max_Salary NUMBER(10,2),
    
    CONSTRAINT PK_DIM_JOBS PRIMARY KEY (JOBID)
); 

drop table Dim_Department cascade constraints;

CREATE TABLE Dim_Department (
    DepartmentID NUMBER,
    DepartmentName VARCHAR2(30),
    ManagerFirstName VARCHAR2(50),
    ManagerLastName VARCHAR2(50),
    LocationID NUMBER,
    
    CONSTRAINT PK_DIM_DEPARTMENTS PRIMARY KEY (DepartmentID),
    CONSTRAINT fk_Dim_Department_LocationID FOREIGN KEY (LocationID) REFERENCES Dim_Location(LocationID)
);
--indexes
-- Indexes for Dim_Employee
CREATE INDEX idx_dimemployee_employeeid ON Dim_Employee(EmployeeID);
CREATE INDEX idx_dimemployee_lastname ON Dim_Employee(LastName);
CREATE INDEX idx_dimemployee_hiredate ON Dim_Employee(HireDate);

-- Indexes for Dim_Location
CREATE INDEX idx_dimlocation_city ON Dim_Location(City);
CREATE INDEX idx_dimlocation_countryname ON Dim_Location(CountryName);

-- Indexes for Dim_Jobs
CREATE INDEX idx_dimjobs_jobtitle ON Dim_Jobs(JobTitle);

-- Indexes for Dim_Department
CREATE INDEX idx_dimdepartment_departmentname ON Dim_Department(DepartmentName);
CREATE INDEX idx_dimdepartment_locationid ON Dim_Department(LocationID);

-- Indexes for Fact_Employee_Job
CREATE INDEX idx_factempjob_employeekey ON Fact_Employee_Job(EmployeeKey);
CREATE INDEX idx_factempjob_jobid ON Fact_Employee_Job(JobID);
CREATE INDEX idx_factempjob_departmentid ON Fact_Employee_Job(DepartmentID);
CREATE INDEX idx_factempjob_locationid ON Fact_Employee_Job(LocationID);
CREATE INDEX idx_factempjob_startdatekey ON Fact_Employee_Job(StartDateKey);
CREATE INDEX idx_factempjob_enddatekey ON Fact_Employee_Job(EndDateKey);
CREATE INDEX idx_factempjob_iscurrent ON Fact_Employee_Job(IsCurrent);
--Create Staging Tables
drop table STG_Employees cascade constraints;
CREATE TABLE STG_Employees (
    employee_id NUMBER,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    phone_number VARCHAR2(20),
    hire_date DATE,
    job_id VARCHAR2(10),
    salary NUMBER(8,2),
    commission_pct NUMBER(2,2),
    manager_id NUMBER,
    department_id NUMBER
);

SELECT * FROM STG_Employees;
drop table STG_Jobs cascade constraints;
CREATE TABLE STG_Jobs (
    job_id VARCHAR2(10),
    job_title VARCHAR2(35),
    min_salary NUMBER(8,2),
    max_salary NUMBER(8,2)
);

SELECT * FROM STG_Jobs;

drop table STG_Departments cascade constraints;

CREATE TABLE STG_Departments (
    department_id NUMBER,
    department_name VARCHAR2(30),
    manager_id NUMBER,
    location_id NUMBER
);

SELECT * FROM STG_Departments;

drop table STG_LocationHierarchy cascade constraints;

CREATE TABLE STG_LocationHierarchy (
    location_id NUMBER(4,0),
    street_address VARCHAR2(40 BYTE),
    postal_code VARCHAR2(12 BYTE),
    city VARCHAR2(30 BYTE),
    state_province VARCHAR2(25 BYTE),
    country_name VARCHAR2(60 BYTE),
    region_name VARCHAR2(25 BYTE)
);
select * from stg_locationhierarchy;

drop table STG_JobHistory cascade constraints;

CREATE TABLE STG_JobHistory (
    EmployeeID INT,
    StartDate DATE,
    EndDate DATE,
    JobID VARCHAR(10),
    DepartmentID INT
);
SELECT * FROM STG_JobHistory;

--procedures for extract
-- Procedure for Employees
CREATE OR REPLACE PROCEDURE EMPLOYEES_EXTRACT
AS
    RowCt NUMBER := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE STG_Employees';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO STG_Employees
    SELECT 
        employee_id, first_name, last_name, email, phone_number, 
        hire_date, job_id, salary, commission_pct, manager_id, department_id
    FROM HR.EMPLOYEES;
    
    RowCt := SQL%ROWCOUNT;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for Employees.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted into STG_Employees!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
END EMPLOYEES_EXTRACT;

EXEC EMPLOYEES_EXTRACT;

select * from stg_employees;
-- Procedure for Jobs
CREATE OR REPLACE PROCEDURE JOBS_EXTRACT
AS
    RowCt NUMBER := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE STG_Jobs';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO STG_Jobs
    SELECT job_id, job_title, min_salary, max_salary
    FROM HR.JOBS;
    
    RowCt := SQL%ROWCOUNT;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for Jobs.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted into STG_Jobs!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
END JOBS_EXTRACT;
/
SET SERVEROUT ON;

EXEC JOBS_EXTRACT;

select * from stg_jobs;
-- Procedure for Departments
CREATE OR REPLACE PROCEDURE DEPARTMENTS_EXTRACT
AS
    RowCt NUMBER := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE STG_Departments';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO STG_Departments
    SELECT department_id, department_name, manager_id, location_id
    FROM HR.DEPARTMENTS;
    
    RowCt := SQL%ROWCOUNT;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for Departments.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted into STG_Departments!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
END DEPARTMENTS_EXTRACT;
/

SET SERVEROUT ON;

EXEC DEPARTMENTS_EXTRACT;

select * from stg_departments;
-- Procedure for LocationHierarchy
CREATE OR REPLACE PROCEDURE LOCATIONHIERARCHY_EXTRACT
AS
    RowCt NUMBER := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE STG_LocationHierarchy';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO STG_LocationHierarchy
    SELECT 
        l.location_id, l.street_address, l.postal_code, l.city, l.state_province,
        c.country_name, r.region_name
    FROM 
        HR.LOCATIONS l
        JOIN HR.COUNTRIES c ON l.country_id = c.country_id
        JOIN HR.REGIONS r ON c.region_id = r.region_id;
    
    RowCt := SQL%ROWCOUNT;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for LocationHierarchy.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted into STG_LocationHierarchy!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
END LOCATIONHIERARCHY_EXTRACT;
/
EXEC LOCATIONHIERARCHY_EXTRACT;

select * from stg_locationhierarchy;
-- Procedure for JobHistory
CREATE OR REPLACE PROCEDURE JOBHISTORY_EXTRACT
AS
    RowCt NUMBER := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE STG_JobHistory';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO STG_JobHistory
    SELECT employee_id, start_date, end_date, job_id, department_id
    FROM HR.JOB_HISTORY;
    
    RowCt := SQL%ROWCOUNT;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for JobHistory.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted into STG_JobHistory!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
END JOBHISTORY_EXTRACT;
/
EXEC JOBHISTORY_EXTRACT;
select * from stg_jobhistory;
--preload tables
drop table PRELOAD_Employee cascade constraints;

CREATE TABLE PRELOAD_Employee (
   EmployeeKey NUMBER,
   EmployeeID NUMBER,
   FirstName VARCHAR2(50),
   LastName VARCHAR2(50),
   Email VARCHAR2(100),
   Phone VARCHAR2(20),
   HireDate DATE,
   TerminationDate DATE,
   CurrentFlag NUMBER(1)
);

drop table PRELOAD_Department cascade constraints;

CREATE TABLE PRELOAD_Department (
    DepartmentID NUMBER,
    DepartmentName VARCHAR2(30),
    ManagerFirstName VARCHAR2(50),
    ManagerLastName VARCHAR2(50),
    LocationID NUMBER
);
drop table PRELOAD_Location cascade constraints;
CREATE TABLE PRELOAD_Location (
    LocationID NUMBER,
    StreetAddress VARCHAR2(40),
    PostalCode VARCHAR2(12),
    City VARCHAR2(30),
    StateProvince VARCHAR2(25),
    CountryName VARCHAR2(60),
    RegionName VARCHAR2(25)
);

drop table PRELOAD_Jobs cascade constraints;

CREATE TABLE PRELOAD_Jobs (
      JobID VARCHAR2(10),
    JobTitle VARCHAR2(35),
    Min_Salary NUMBER(10,2),
    Max_Salary NUMBER(10,2)
   
);

drop table PRELOAD_Location cascade constraints;

CREATE TABLE PRELOAD_Location (
    LocationID NUMBER,
    StreetAddress VARCHAR2(40),
    PostalCode VARCHAR2(12),
    City VARCHAR2(30),
    StateProvince VARCHAR2(25),
    CountryName VARCHAR2(60),
    RegionName VARCHAR2(25)
);



DROP TABLE PRELOAD_Fact_Employee_Job CASCADE CONSTRAINTS;

CREATE TABLE PRELOAD_Fact_Employee_Job (
    EmployeeJobKey NUMBER,
    EmployeeKey NUMBER,
    JobID VARCHAR(10),
    DepartmentID NUMBER,
    LocationID NUMBER,
    StartDateKey NUMBER,
    EndDateKey NUMBER,
    Salary NUMBER(10,2),
    Commission NUMBER(5,2),
    TotalSalary NUMBER(10,2),
    IsCurrent NUMBER(1),
       TotalDuration NUMBER,  -- Added TotalDuration
    PreviousJobID VARCHAR2(10)  -- Added PreviousJobID
);

--TRANSFORM PROCEDURE
CREATE OR REPLACE PROCEDURE Locations_Transform
AS
  RowCt NUMBER(10) := 0;
  v_dim_count NUMBER(10) := 0;
  v_sql VARCHAR(255) := 'TRUNCATE TABLE PRELOAD_Location DROP STORAGE';
BEGIN
    --  Clear the PRELOAD_Location table
    EXECUTE IMMEDIATE v_sql;

    -- Check if Dim_Location is empty
    SELECT COUNT(*) INTO v_dim_count FROM Dim_Location;

    IF v_dim_count = 0 THEN
        -- Dim_Location is empty, insert all records from staging
        INSERT INTO PRELOAD_Location (
            LocationID, StreetAddress, PostalCode, City, StateProvince, CountryName, RegionName
        )
        SELECT 
            lh.location_id,
            lh.street_address,
            lh.postal_code,
            lh.city,
            lh.state_province,
            lh.country_name,
            lh.region_name
        FROM STG_LocationHierarchy lh;

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('Dim_Location was empty. ' || TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Location.');
    ELSE
        -- Dim_Location has data, handle new and existing records
        -- Insert new locations that don't exist in Dim_Location
        INSERT INTO PRELOAD_Location (
            LocationID, StreetAddress, PostalCode, City, StateProvince, CountryName, RegionName
        )
        SELECT 
            lh.location_id,
            lh.street_address,
            lh.postal_code,
            lh.city,
            lh.state_province,
            lh.country_name,
            lh.region_name
        FROM STG_LocationHierarchy lh
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Dim_Location dl
            WHERE lh.location_id = dl.LocationID
        );

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Location.');

        --  Insert existing locations from Dim_Location
        INSERT INTO PRELOAD_Location (
            LocationID, StreetAddress, PostalCode, City, StateProvince, CountryName, RegionName
        )
        SELECT 
            dl.LocationID,
            lh.street_address,
            lh.postal_code,
            lh.city,
            lh.state_province,
            lh.country_name,
            lh.region_name
        FROM STG_LocationHierarchy lh
        JOIN Dim_Location dl ON lh.location_id = dl.LocationID;

        RowCt := RowCt + SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(SQL%ROWCOUNT) || ' existing rows updated in PRELOAD_Location.');
    END IF;

    --  Report total number of rows processed
    IF RowCt = 0 THEN
       DBMS_OUTPUT.PUT_LINE('No records processed. Check source data in STG_LocationHierarchy.');
    ELSE
       DBMS_OUTPUT.PUT_LINE('Total ' || TO_CHAR(RowCt) || ' rows processed in PRELOAD_Location.');
    END IF;
    
    COMMIT;

EXCEPTION
    -- Handle any errors that might occur during execution
    WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
       DBMS_OUTPUT.PUT_LINE('SQL: ' || v_sql);
END Locations_Transform;

/
execute Locations_Transform;
select * from preload_location;

CREATE OR REPLACE PROCEDURE Jobs_Transform
AS
  RowCt NUMBER(10) := 0;
  v_dim_count NUMBER(10) := 0;
  v_sql VARCHAR(255) := 'TRUNCATE TABLE PRELOAD_Jobs DROP STORAGE';
BEGIN
    
    EXECUTE IMMEDIATE v_sql;

  
    SELECT COUNT(*) INTO v_dim_count FROM Dim_Jobs;

    IF v_dim_count = 0 THEN
        -- Dim_Jobs is empty, insert all records from staging
        INSERT INTO PRELOAD_Jobs (
            JobID, JobTitle, Min_Salary, Max_Salary
        )
        SELECT 
            j.job_id,
            j.job_title,
            j.min_salary,
            j.max_salary
        FROM STG_Jobs j;

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('Dim_Jobs was empty. ' || TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Jobs.');
    ELSE
        -- Dim_Jobs has data, handle new and existing records
        -- Step 2: Insert new jobs that don't exist in Dim_Jobs
        INSERT INTO PRELOAD_Jobs (
            JobID, JobTitle, Min_Salary, Max_Salary
        )
        SELECT 
            j.job_id,
            j.job_title,
            j.min_salary,
            j.max_salary
        FROM STG_Jobs j
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Dim_Jobs dj
            WHERE j.job_id = dj.JobID
        );

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Jobs.');

        -- Step 3: Insert existing jobs from Dim_Jobs
        INSERT INTO PRELOAD_Jobs (
            JobID, JobTitle, Min_Salary, Max_Salary
        )
        SELECT 
            dj.JobID,
            j.job_title,
            j.min_salary,
            j.max_salary
        FROM STG_Jobs j
        JOIN Dim_Jobs dj ON j.job_id = dj.JobID;

        RowCt := RowCt + SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(SQL%ROWCOUNT) || ' existing rows updated in PRELOAD_Jobs.');
    END IF;

    -- Step 4: Report total number of rows processed
    IF RowCt = 0 THEN
       DBMS_OUTPUT.PUT_LINE('No records processed. Check source data in STG_Jobs.');
    ELSE
       DBMS_OUTPUT.PUT_LINE('Total ' || TO_CHAR(RowCt) || ' rows processed in PRELOAD_Jobs.');
    END IF;
    
    COMMIT;

EXCEPTION
    -- Step 5: Handle any errors that might occur during execution
    WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
       DBMS_OUTPUT.PUT_LINE('SQL: ' || v_sql);
END Jobs_Transform;
/
execute Jobs_Transform;

select * from preload_jobs;

CREATE OR REPLACE PROCEDURE Department_Transform
AS
  RowCt NUMBER(10) := 0;
  v_dim_count NUMBER(10) := 0;
  v_sql VARCHAR2(255) := 'TRUNCATE TABLE PRELOAD_Department DROP STORAGE';
BEGIN
    --  Clear the PRELOAD_Department table
    EXECUTE IMMEDIATE v_sql;

    -- Check if Dim_Department is empty
    SELECT COUNT(*) INTO v_dim_count FROM Dim_Department;

    IF v_dim_count = 0 THEN
        -- Dim_Department is empty, insert all records from staging
        INSERT INTO PRELOAD_Department (
            DepartmentID, DepartmentName, ManagerFirstName, ManagerLastName, LocationID
        )
        SELECT 
            d.department_id,
            d.department_name,
            e.first_name,
            e.last_name,
            d.location_id
        FROM STG_Departments d
        LEFT JOIN STG_Employees e ON d.manager_id = e.employee_id;

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('Dim_Department was empty. ' || TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Department.');
    ELSE
        -- Dim_Department has data, handle new and existing records
        -- Insert new departments that don't exist in Dim_Department
        INSERT INTO PRELOAD_Department (
            DepartmentID, DepartmentName, ManagerFirstName, ManagerLastName, LocationID
        )
        SELECT 
            d.department_id,
            d.department_name,
            e.first_name,
            e.last_name,
            d.location_id
        FROM STG_Departments d
        LEFT JOIN STG_Employees e ON d.manager_id = e.employee_id
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Dim_Department dd
            WHERE d.department_id = dd.DepartmentID
        );

        RowCt := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' new rows inserted into PRELOAD_Department.');

        --  Insert existing departments from Dim_Department
        INSERT INTO PRELOAD_Department (
            DepartmentID, DepartmentName, ManagerFirstName, ManagerLastName, LocationID
        )
        SELECT 
            dd.DepartmentID,
            d.department_name,
            e.first_name,
            e.last_name,
            d.location_id
        FROM STG_Departments d
        JOIN Dim_Department dd ON d.department_id = dd.DepartmentID
        LEFT JOIN STG_Employees e ON d.manager_id = e.employee_id;

        RowCt := RowCt + SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(SQL%ROWCOUNT) || ' existing rows updated in PRELOAD_Department.');
    END IF;

    -- Report total number of rows processed
    IF RowCt = 0 THEN
       DBMS_OUTPUT.PUT_LINE('No records processed. Check source data in STG_Departments.');
    ELSE
       DBMS_OUTPUT.PUT_LINE('Total ' || TO_CHAR(RowCt) || ' rows processed in PRELOAD_Department.');
    END IF;
    
    COMMIT;

EXCEPTION
    -- Handle any errors that might occur during execution
    WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
       DBMS_OUTPUT.PUT_LINE('SQL: ' || v_sql);
END Department_Transform;
/
execute Department_Transform;

select * from preload_Department;
select * from stg_employees;
CREATE SEQUENCE Seq_EmployeeKey
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;
CREATE OR REPLACE PROCEDURE Employee_Transform
AS
  v_row_count NUMBER := 0;
BEGIN
    -- Clear the PRELOAD_Employee table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PRELOAD_Employee';

    -- Insert records from STG_Employees into PRELOAD_Employee
    INSERT INTO PRELOAD_Employee (
        EmployeeKey, EmployeeID, FirstName, LastName, Email, Phone, HireDate, CurrentFlag
    )
    SELECT 
        Seq_EmployeeKey.NEXTVAL,
        EMPLOYEE_ID,
        FIRST_NAME,
        LAST_NAME,
        EMAIL,
        PHONE_NUMBER,
        HIRE_DATE,
        1  -- Assume all employees are current
    FROM STG_Employees;

    v_row_count := SQL%ROWCOUNT;

    -- Update TerminationDate based on STG_JobHistory
    UPDATE PRELOAD_Employee pe
    SET TerminationDate = (
        SELECT MAX(EndDate)
        FROM STG_JobHistory jh
        WHERE jh.EmployeeID = pe.EmployeeID
    )
    WHERE EXISTS (
        SELECT 1
        FROM STG_JobHistory jh
        WHERE jh.EmployeeID = pe.EmployeeID
    );

    -- Update CurrentFlag based on TerminationDate
    UPDATE PRELOAD_Employee
    SET CurrentFlag = 0
    WHERE TerminationDate IS NOT NULL AND TerminationDate < TRUNC(SYSDATE);

    -- Report on the number of rows processed
    DBMS_OUTPUT.PUT_LINE('Total ' || TO_CHAR(v_row_count) || ' rows processed in PRELOAD_Employee.');

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END Employee_Transform;
/


execute Employee_Transform;

select * from preload_employee;

CREATE SEQUENCE seq_employeejobkey
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE OR REPLACE PROCEDURE Fact_Employee_Job_Transform
AS
  RowCt NUMBER(10) := 0;
  v_sql VARCHAR(255) := 'TRUNCATE TABLE PRELOAD_Fact_Employee_Job DROP STORAGE';
BEGIN
    -- Step 1: Clear the PRELOAD_Fact_Employee_Job table
    EXECUTE IMMEDIATE v_sql;

    -- Step 2: Insert records into PRELOAD_Fact_Employee_Job
    INSERT INTO PRELOAD_Fact_Employee_Job (
        EmployeeJobKey, EmployeeKey, JobID, DepartmentID, Locationid,
        StartDateKey, EndDateKey, Salary, Commission, TotalSalary,
        IsCurrent, PreviousJobID
    )
    WITH RankedJobs AS (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY e.employee_id ORDER BY 
                COALESCE(jh.StartDate, e.hire_date)) AS job_rank,
            e.employee_id,
            COALESCE(jh.JobID, e.job_id) AS job_id,
            COALESCE(jh.DepartmentID, e.department_id) AS department_id,
            d.location_id,
            COALESCE(jh.StartDate, e.hire_date) AS start_date,
            jh.EndDate AS end_date,
            e.salary,
            e.commission_pct,
            LAG(COALESCE(jh.JobID, e.job_id)) OVER (PARTITION BY e.employee_id ORDER BY 
                COALESCE(jh.StartDate, e.hire_date)) AS prev_job_id
        FROM STG_Employees e
        LEFT JOIN STG_JobHistory jh ON e.employee_id = jh.EmployeeID
        LEFT JOIN STG_Departments d ON COALESCE(jh.DepartmentID, e.department_id) = d.department_id
    )
    SELECT 
        seq_employeejobkey.NEXTVAL AS EmployeeJobKey,
        pe.EmployeeKey,
        pj.jobid,
        pd.Departmentid,
        pl.locationid,
        TO_NUMBER(TO_CHAR(rj.start_date, 'YYYYMMDD')) AS StartDateKey,
        CASE 
            WHEN rj.end_date IS NOT NULL THEN TO_NUMBER(TO_CHAR(rj.end_date, 'YYYYMMDD'))
            ELSE NULL
        END AS EndDateKey,
        rj.salary AS Salary,
        NVL(rj.commission_pct, 0) AS Commission,
        rj.salary * (1 + NVL(rj.commission_pct, 0)) AS TotalSalary,
        CASE WHEN rj.end_date IS NULL THEN 1 ELSE 0 END AS IsCurrent,
        rj.prev_job_id AS PreviousJobID
    FROM RankedJobs rj
    JOIN PRELOAD_Employee pe ON rj.employee_id = pe.EmployeeID
    JOIN PRELOAD_Jobs pj ON rj.job_id = pj.JobID
    JOIN PRELOAD_Department pd ON rj.department_id = pd.DepartmentID
    JOIN PRELOAD_Location pl ON rj.location_id = pl.LocationID;

    RowCt := SQL%ROWCOUNT;

    -- Step 3: Report on the number of rows processed
    IF RowCt = 0 THEN
       DBMS_OUTPUT.PUT_LINE('No records processed. Check source data in STG_Employees and related tables.');
    ELSE
       DBMS_OUTPUT.PUT_LINE('Total ' || TO_CHAR(RowCt) || ' rows processed in PRELOAD_Fact_Employee_Job.');
    END IF;

    COMMIT;

EXCEPTION
    -- Step 4: Handle any errors that might occur during execution
    WHEN OTHERS THEN
       ROLLBACK;
       DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
       DBMS_OUTPUT.PUT_LINE('SQL: ' || v_sql);
END Fact_Employee_Job_Transform;
/


execute Fact_Employee_Job_Transform;

select * from PRELOAD_Fact_Employee_Job order by employeekey;

--Procedures for Load
CREATE OR REPLACE PROCEDURE Employee_Load
AS
  v_inserted NUMBER := 0;
  v_updated NUMBER := 0;
BEGIN
    -- Insert new records
    INSERT INTO Dim_Employee (
        EmployeeKey, EmployeeID, FirstName, LastName, Email, Phone, HireDate, TerminationDate, CurrentFlag
    )
    SELECT 
        p.EmployeeKey, p.EmployeeID, p.FirstName, p.LastName, p.Email, p.Phone, p.HireDate, p.TerminationDate, p.CurrentFlag
    FROM PRELOAD_Employee p
    WHERE p.EmployeeKey NOT IN (SELECT EmployeeKey FROM Dim_Employee);
    
    v_inserted := SQL%ROWCOUNT;

    -- Update existing records
    UPDATE Dim_Employee d
    SET 
        (d.FirstName, d.LastName, d.Email, d.Phone, d.HireDate, d.TerminationDate, d.CurrentFlag) =
        (SELECT p.FirstName, p.LastName, p.Email, p.Phone, p.HireDate, p.TerminationDate, p.CurrentFlag
         FROM PRELOAD_Employee p
         WHERE p.EmployeeKey = d.EmployeeKey)
    WHERE d.EmployeeKey IN (SELECT EmployeeKey FROM PRELOAD_Employee);
    
    v_updated := SQL%ROWCOUNT;

    DBMS_OUTPUT.PUT_LINE('Inserted ' || v_inserted || ' new records.');
    DBMS_OUTPUT.PUT_LINE('Updated ' || v_updated || ' existing records.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END Employee_Load;

execute Employee_Load;
CREATE OR REPLACE PROCEDURE Load_Dim_Location
AS
    v_rows_inserted NUMBER := 0;
    v_rows_updated NUMBER := 0;
BEGIN
    -- Insert new records
    INSERT INTO Dim_Location (LocationID, StreetAddress, PostalCode, City, StateProvince, CountryName, RegionName)
    SELECT p.LocationID, p.StreetAddress, p.PostalCode, p.City, p.StateProvince, p.CountryName, p.RegionName
    FROM PRELOAD_Location p
    WHERE p.LocationID NOT IN (SELECT LocationID FROM Dim_Location);

    v_rows_inserted := SQL%ROWCOUNT;

    -- Update existing records
    UPDATE Dim_Location d
    SET (StreetAddress, PostalCode, City, StateProvince, CountryName, RegionName) = 
        (SELECT 
            NVL(p.StreetAddress, d.StreetAddress),
            NVL(p.PostalCode, d.PostalCode),
            NVL(p.City, d.City),
            NVL(p.StateProvince, d.StateProvince),
            NVL(p.CountryName, d.CountryName),
            NVL(p.RegionName, d.RegionName)
         FROM PRELOAD_Location p
         WHERE p.LocationID = d.LocationID)
    WHERE EXISTS (SELECT 1 FROM PRELOAD_Location p WHERE p.LocationID = d.LocationID);

    v_rows_updated := SQL%ROWCOUNT;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Rows inserted into Dim_Location: ' || v_rows_inserted);
    DBMS_OUTPUT.PUT_LINE('Rows updated in Dim_Location: ' || v_rows_updated);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in Load_Dim_Location: ' || SQLERRM);
        RAISE;
END Load_Dim_Location;

/

execute Load_Dim_Location;

select * from dim_location order by locationid;
select * from dim_employee;

CREATE OR REPLACE PROCEDURE Load_Dim_Department
AS
    v_rows_inserted NUMBER := 0;
    v_rows_updated NUMBER := 0;
BEGIN
    -- Insert new records
    INSERT INTO Dim_Department (DepartmentID, DepartmentName, ManagerFirstName, ManagerLastName, LocationID)
    SELECT p.DepartmentID, p.DepartmentName, p.ManagerFirstName, p.ManagerLastName, p.LocationID
    FROM PRELOAD_Department p
    WHERE p.DepartmentID NOT IN (SELECT DepartmentID FROM Dim_Department);

    v_rows_inserted := SQL%ROWCOUNT;

    -- Update existing records
    UPDATE Dim_Department d
    SET (DepartmentName, ManagerFirstName, ManagerLastName, LocationID) = 
        (SELECT p.DepartmentName, p.ManagerFirstName, p.ManagerLastName, p.LocationID
         FROM PRELOAD_Department p
         WHERE p.DepartmentID = d.DepartmentID)
    WHERE EXISTS (
        SELECT 1
        FROM PRELOAD_Department p
        WHERE p.DepartmentID = d.DepartmentID
        AND (p.DepartmentName != d.DepartmentName OR (p.DepartmentName IS NULL AND d.DepartmentName IS NOT NULL))
        OR (p.ManagerFirstName != d.ManagerFirstName OR (p.ManagerFirstName IS NULL AND d.ManagerFirstName IS NOT NULL))
        OR (p.ManagerLastName != d.ManagerLastName OR (p.ManagerLastName IS NULL AND d.ManagerLastName IS NOT NULL))
        OR (p.LocationID != d.LocationID OR (p.LocationID IS NULL AND d.LocationID IS NOT NULL))
    );

    v_rows_updated := SQL%ROWCOUNT;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Rows inserted: ' || v_rows_inserted);
    DBMS_OUTPUT.PUT_LINE('Rows updated: ' || v_rows_updated);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in Load_Dim_Department: ' || SQLERRM);
        RAISE;
END Load_Dim_Department;

SET SERVEROUTPUT ON;

execute Load_Dim_Department;

select * from DIM_department;

select * from Dim_Department order by departmentid;



CREATE OR REPLACE PROCEDURE Load_Dim_Job
AS
    v_rows_inserted NUMBER := 0;
    v_rows_updated NUMBER := 0;
BEGIN
    -- Insert new records
    INSERT INTO Dim_Jobs (JobID, JobTitle, Min_Salary, Max_Salary)
    SELECT p.JobID, p.JobTitle, p.Min_Salary, p.Max_Salary
    FROM PRELOAD_Jobs p
    WHERE p.JobID NOT IN (SELECT JobID FROM Dim_Jobs);

    v_rows_inserted := SQL%ROWCOUNT;

    -- Update existing records
    UPDATE Dim_Jobs d
    SET JobTitle = (SELECT NVL(p.JobTitle, d.JobTitle) FROM PRELOAD_Jobs p WHERE p.JobID = d.JobID),
        Min_Salary = (SELECT NVL(p.Min_Salary, d.Min_Salary) FROM PRELOAD_Jobs p WHERE p.JobID = d.JobID),
        Max_Salary = (SELECT NVL(p.Max_Salary, d.Max_Salary) FROM PRELOAD_Jobs p WHERE p.JobID = d.JobID)
    WHERE EXISTS (SELECT 1 FROM PRELOAD_Jobs p WHERE p.JobID = d.JobID);

    v_rows_updated := SQL%ROWCOUNT;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Rows inserted into Dim_Job: ' || v_rows_inserted);
    DBMS_OUTPUT.PUT_LINE('Rows updated in Dim_Job: ' || v_rows_updated);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in Load_Dim_Job: ' || SQLERRM);
        RAISE;
END Load_Dim_Job;
/

execute Load_Dim_Job;

select * from dim_jobs;
SELECT * FROM PRELOAD_Fact_Employee_Job;
SELECT EmployeeKey 
FROM PRELOAD_Fact_Employee_Job
WHERE EmployeeKey NOT IN (SELECT EmployeeKey FROM Dim_Employee);
CREATE OR REPLACE PROCEDURE Load_Fact_Employee_Job
AS
    v_rows_inserted NUMBER := 0;
    v_rows_skipped NUMBER := 0;
BEGIN
    -- Insert records from PRELOAD table into Fact table, handling null EndDateKey
    INSERT INTO Fact_Employee_Job (
        EmployeeJobKey, EmployeeKey, JobID, DepartmentID, LocationID,
        StartDateKey, EndDateKey, Salary, Commission, TotalSalary,
        IsCurrent, TotalDuration, PreviousJobID
    )
    SELECT 
        p.EmployeeJobKey, p.EmployeeKey, p.JobID, p.DepartmentID, p.LocationID,
        p.StartDateKey, p.EndDateKey, p.Salary, p.Commission, p.TotalSalary,
        p.IsCurrent, p.TotalDuration, p.PreviousJobID
    FROM PRELOAD_Fact_Employee_Job p
    WHERE EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.StartDateKey)
      AND (p.EndDateKey IS NULL OR EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.EndDateKey));

    v_rows_inserted := SQL%ROWCOUNT;

    -- Count skipped rows
    SELECT COUNT(*)
    INTO v_rows_skipped
    FROM PRELOAD_Fact_Employee_Job p
    WHERE NOT EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.StartDateKey)
       OR (p.EndDateKey IS NOT NULL AND NOT EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.EndDateKey));

    -- Commit the transaction
    COMMIT;

    -- Log the results
    DBMS_OUTPUT.PUT_LINE('Rows inserted into Fact_Employee_Job: ' || v_rows_inserted);
    DBMS_OUTPUT.PUT_LINE('Rows skipped due to missing date keys: ' || v_rows_skipped);

    -- Log details of skipped rows
    FOR r IN (
        SELECT p.EmployeeJobKey, p.StartDateKey, p.EndDateKey
        FROM PRELOAD_Fact_Employee_Job p
        WHERE NOT EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.StartDateKey)
           OR (p.EndDateKey IS NOT NULL AND NOT EXISTS (SELECT 1 FROM DimDate d WHERE d.DateKey = p.EndDateKey))
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Skipped EmployeeJobKey: ' || r.EmployeeJobKey || 
                             ', StartDateKey: ' || r.StartDateKey || 
                             ', EndDateKey: ' || NVL(TO_CHAR(r.EndDateKey), 'NULL'));
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        -- Roll back the transaction on error
        ROLLBACK;
        -- Log the error
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Re-raise the error
        RAISE;
END Load_Fact_Employee_Job;
/


execute Load_Fact_Employee_Job;
select * from fact_employee_job;


