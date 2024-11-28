--1. Создать триггеры со всеми возможными ключевыми словами, а также рассмотреть операционные триггеры
-- 2. Попрактиковаться в созданиях транзакций (привести пример успешной и фейл транзакции, объяснить в комментариях почему она зафейлилась)
--3. Использовать RAISE для логирования

--BEFORE INSERT

CREATE OR REPLACE FUNCTION validate_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Salary < 0 THEN
        RAISE EXCEPTION 'Salary cannot be negative';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_trigger
BEFORE INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION validate_before_insert();

--AFTER INSERT
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    action VARCHAR(255),
    employee_id INT,
    action_time TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (action, employee_id, action_time)
    VALUES('insert', NEW.employee_id, CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_trigger
AFTER INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION log_after_insert();

--BEFORE UPDATE
CREATE OR REPLACE FUNCTION update_salary_on_position_change()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Position changed: % -> %', OLD.position, NEW.position;
    IF NEW.Position = 'Manager' THEN
        NEW.Salary = 100000;
    ELSIF NEW.Position = 'Developer' THEN
        NEW.Salary = 80000;
    ELSE
        NEW.Salary = 60000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_salary
BEFORE UPDATE ON employees
FOR EACH ROW
WHEN (OLD.Position IS DISTINCT FROM NEW.Position)
EXECUTE FUNCTION update_salary_on_position_change();

--AFTER UPDATE
CREATE OR REPLACE FUNCTION log_after_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (action, employee_id, action_time)
    VALUES('update', NEW.employee_id, CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_update_trigger
AFTER UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION log_after_update();

--BEFORE DELETE
CREATE OR REPLACE FUNCTION archive_employee()
RETURNS TRIGGER AS $$
BEGIN
    RAISE LOG 'Delected employee: %', OLD.name;
    INSERT INTO employees_archive (employee_id, name, position, department, salary)
    VALUES (OLD.employee_id, OLD.name, OLD.position, OLD.department, OLD.salary);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_archive_employee
BEFORE DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION archive_employee();

--INSTEAD OF
CREATE VIEW employee_view AS
SELECT * FROM employees;

CREATE OR REPLACE FUNCTION handle_view_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO employees(name, position, department, salary, manager_id)
    VALUES (NEW.name, NEW.position, NEW.department, NEW.salary, NEW.manager_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER instead_of_insert_trigger
INSTEAD OF INSERT ON employee_view
FOR EACH ROW
EXECUTE FUNCTION handle_view_insert();

--Транзакции
--Успешная транзакция
BEGIN;
INSERT INTO employees (name, "position", department, salary, manager_id)
VALUES ('TOM CAT', 'Manager', 'Sales', 90000, NULL);

INSERT INTO employees (name, "position", department, salary, manager_id)
VALUES ('JERRY MOUSE', 'developer', 'IT', 70000, NULL);

UPDATE employees 
SET manager_id = (SELECT employee_id FROM employees WHERE name = 'TOM CAT' AND position = 'Manager' LIMIT 1)
WHERE name = 'JERRY MOUSE';

COMMIT;

--Неуспешная транзакция
--Здесь мы пытаемся обновить зарплату сотрудника, 
--который не существует в таблице сотрудников, в результате обновление не удается,
--а предыдущая операция вставки также не будет выполнена, транзакция автоматически откатится.
BEGIN;
INSERT INTO employees (name, "position", department, salary, manager_id)
VALUES ('JOY', 'Manager', 'Sales', 10000, NULL);

UPDATE employees
SET Salary = 1000000
WHERE name = 'JOYY';

COMMIT;

--Операция Неуспешная, так как сработал триггер validate_before_insert.
--Вторая операция insert установила зарплату на отрицательное значение.
BEGIN;
INSERT INTO employees (name, "position", department, salary, manager_id)
VALUES ('JOY', 'Manager', 'Sales', 10000, NULL);

INSERT INTO employees (name, "position", department, salary, manager_id)
VALUES ('JACK', 'Manager', 'Sales', -10000, NULL);

COMMIT;