-- ============================================================================
-- Laboratory Work #3 - DML Operations
-- File: lab3_advanced_dml.sql
-- ============================================================================

-- ============================================================================
-- Part A: Database and Table Setup
-- ============================================================================

-- 1. Create database and tables
-- Выполните отдельно при необходимости:
-- CREATE DATABASE advanced_lab;
-- \c advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- ============================================================================
-- Part B: Advanced INSERT Operations
-- ============================================================================

-- 2. INSERT with column specification
-- Вставка данных с указанием только определенных колонок
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (DEFAULT, 'John', 'Doe', 'IT');

-- 3. INSERT with DEFAULT values
-- Вставка строки, где salary и status используют значения по умолчанию
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Jane', 'Smith', 'HR', DEFAULT, '2023-05-10', DEFAULT);

-- 4. INSERT multiple rows in single statement
-- Вставка 3 отделов в одном операторе INSERT с несколькими блоками VALUES
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 120000, 1),
    ('HR', 60000, 2),
    ('Sales', 90000, NULL);

-- 5. INSERT with expressions
-- Вставка сотрудника, где hire_date — текущая дата, а зарплата вычисляется выражением
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Alice', 'Brown', 'IT', 50000 * 1.1, CURRENT_DATE, 'Active');

-- 6. INSERT from SELECT (subquery)
-- Создание временной таблицы temp_employees и перенос сотрудников IT-отдела
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

-- ============================================================================
-- Part C: Complex UPDATE Operations
-- ============================================================================

-- 7. UPDATE with arithmetic expressions
-- Увеличение зарплаты всем сотрудникам на 10%
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE clause and multiple conditions
-- Обновление статуса на 'Senior' для сотрудников с зарплатой > 60000 и наймом до 2020-01-01
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
-- Обновление отдела на основе диапазона зарплат через условное выражение CASE
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT
-- Сброс отдела на значение по умолчанию для неактивных сотрудников
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
-- Увеличение бюджета отдела на 20% выше средней зарплаты сотрудников этого отдела
UPDATE departments d
SET budget = (
    SELECT AVG(salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns
-- Обновление нескольких колонок: salary = salary * 1.15 и status = 'Promoted' для отдела 'Sales'
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- ============================================================================
-- Part D: Advanced DELETE Operations
-- ============================================================================

-- 13. DELETE with simple WHERE condition
-- Удаление всех уволенных сотрудников
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
-- Удаление по нескольким условиям (зарплата < 40000, дата найма > '2023-01-01', отдел NULL)
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
-- Удаление отделов, у которых нет сотрудников
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT department::integer
    FROM employees
    WHERE department IS NOT NULL AND department ~ '^[0-9]+$'
);
-- Примечание: если связь departments.dept_name = employees.department:
-- DELETE FROM departments
-- WHERE dept_name NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING clause
-- Удаление завершенных проектов с возвратом всех удаленных записей
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- ============================================================================
-- Part E: Operations with NULL Values
-- ============================================================================

-- 17. INSERT with NULL values
-- Вставка сотрудника с NULL в salary и department
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Robert', 'Taylor', NULL, NULL, '2023-08-01', 'Active');

-- 18. UPDATE NULL handling
-- Замена NULL значений в department на 'Unassigned'
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
-- Удаление записей, где salary IS NULL или department IS NULL
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- ============================================================================
-- Part F: RETURNING Clause Operations
-- ============================================================================

-- 20. INSERT with RETURNING
-- Вставка нового сотрудника с возвратом emp_id и конкатенации полного имени
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Michael', 'Scott', 'IT', 75000, '2022-03-15', 'Active')
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
-- Повышение зарплаты сотрудникам IT на 5000 с возвратом emp_id, старой и новой зарплаты
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns
-- Удаление старых сотрудников (нанятых до 2020-01-01) с возвратом всех колонок
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- ============================================================================
-- Part G: Advanced DML Patterns
-- ============================================================================

-- 23. Conditional INSERT
-- Вставка только если сотрудника с такими first_name и last_name еще нет в базе
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'David', 'Miller', 'Finance', 65000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'David' AND last_name = 'Miller'
);

-- 24. UPDATE with JOIN logic using subqueries
-- Обновление зарплаты в зависимости от бюджета отдела сотрудника
UPDATE employees e
SET salary = CASE
    WHEN (SELECT d.budget FROM departments d WHERE d.dept_name = e.department) > 100000
        THEN salary * 1.10
    ELSE salary * 1.05
END
WHERE EXISTS (
    SELECT 1
    FROM departments d
    WHERE d.dept_name = e.department
);

-- 25. Bulk operations
-- Вставка 5 сотрудников одним запросом и последующее увеличение их зарплаты на 10% в одном UPDATE
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('User1', 'Test', 'Support', 30000, CURRENT_DATE, 'Active'),
    ('User2', 'Test', 'Support', 31000, CURRENT_DATE, 'Active'),
    ('User3', 'Test', 'Support', 32000, CURRENT_DATE, 'Active'),
    ('User4', 'Test', 'Support', 33000, CURRENT_DATE, 'Active'),
    ('User5', 'Test', 'Support', 34000, CURRENT_DATE, 'Active');

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Support' AND last_name = 'Test';

-- 26. Data migration simulation
-- Создание таблицы employee_archive, перенос сотрудников со статусом 'Inactive' и их удаление
CREATE TABLE IF NOT EXISTS employee_archive (LIKE employees INCLUDING ALL);

WITH moved_rows AS (
    DELETE FROM employees
    WHERE status = 'Inactive'
    RETURNING *
)
INSERT INTO employee_archive
SELECT * FROM moved_rows;

-- 27. Complex business logic
-- Сдвиг даты окончания проекта (end_date) на 30 дней вперед для проектов с бюджетом > 50000
-- и если в связанном отделе работает более 3 сотрудников
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      JOIN departments d ON d.dept_name = e.department
      WHERE d.dept_id = p.dept_id
  ) > 3;