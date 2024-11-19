-- 1.Создайте временную таблицу high_sales_products, которая будет содержать продукты, проданные в количестве более 10 единиц за последние 7 дней.
CREATE TEMP TABLE high_sales_products AS 
SELECT
    p.product_id,
    p.name,
    p.price
    SUM(s.quantity) as total_quantity
FROM
    products p
JOIN
    sales s ON p.product_id = s.product_id
WHERE
    s.sale_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY
    p.product_id, p.name, p.price
HAVING
    SUM(s.quantity) > 10

-- Выведите данные из таблицы high_sales_products.
SELECT * FROM high_sales_products;
LIMIT 10;

-- 2.Создайте CTE employee_sales_stats, который посчитает общее количество продаж и среднее количество продаж для каждого сотрудника за последние 30 дней.
WITH employee_sales_stats AS (
    SELECT
        e.employee_id,
        e.name,
        COUNT(s.sale_id) AS total_sales,
        AVG(s.quantity) AS avg_sales
    FROM
        employees e
    JOIN
        sales s ON e.employee_id = s.employee_id
    WHERE
        s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        e.employee_id, e.name
),
company_average AS (
    SELECT 
        AVG(total_sales) AS avg_company_sales 
    FROM employee_sales_stats
)
-- Напишите запрос, который выводит сотрудников с количеством продаж выше среднего по компании.
SELECT 
    ess.*,
    ca.avg_company_sales,
FROM
    employee_sales_stats ess
CROSS JOIN
    company_average ca
WHERE
    ess.total_sales > ca.avg_company_sales
ORDER BY
    ess.total_sales DESC
LIMIT 10;

-- 3.Используя CTE, создайте иерархическую структуру, показывающую всех сотрудников, которые подчиняются конкретному менеджеру.
WITH employee_hierarchy AS (
    SELECT 
        e1.name AS manager,
        e2.name AS employee
    FROM
        employees e1
    JOIN
        employees e2 ON e1.employee_id = e2.manager_id
)
SELECT * FROM employee_hierarchy
LIMIT 5;

-- 4.Напишите запрос с CTE, который выведет топ-3 продукта по количеству 
-- продаж за текущий месяц и за прошлый месяц. 
-- В результатах должно быть указано, к какому месяцу относится каждая запись
WITH monthly_sales AS (
    SELECT
        p.product_id,
        p.name,
        SUM(s.quantity) AS total_sales,
        DATE_TRUNC('month', s.sale_date) AS sale_month
    CASE
        WHEN DATE_TRUNC('month', s.sale_date) = DATE_TRUNC('month', CURRENT_DATE) 
            THEN 'Текущий месяц'
        WHEN DATE_TRUNC('month', s.sale_date) = DATE_TRUNC('month',CURRENT_DATE - INTERVAL '1 month')
            THEN 'Предыдущий месяц'
    END as month_label,
  -- Ранжируем продукты по продажам внутри каждого месяца
    RANK() OVER (
        PARTITION BY DATE_TRUNC('month', s.sale_date)
        ORDER BY SUM(s.quantity) DESC
    ) as sales_rank
    FROM
        products p
    JOIN
        sales s ON p.product_id = s.product_id
    WHERE
        DATE_TRUNC('month',s.sale_date) IN 
        (
            DATE_TRUNC('month', CURRENT_DATE),
            DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        )
    GROUP BY
        p.product_id, p.name, sale_month
)
SELECT 
    product_name,
    month_label,
    sales_rank
FROM monthly_sales
WHERE sales_rank <= 3
ORDER BY
    sale_month DESC
LIMIT 10;

-- 5.Создайте индекс для таблицы sales по полю employee_id и sale_date. 
-- Проверьте, как наличие индекса влияет на производительность следующего запроса, используя трассировку (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT
    employee_id,
    COUNT(*) AS total_sales,
    SUM(quantity) AS total_quantity
FROM
    Sales
WHERE
    sale_date BETWEEN '2024-10-01' AND '2024-11-30'
GROUP BY
    employee_id

CREATE INDEX idx_employee_id_sale_date ON Sales(employee_id, sale_date);

EXPLAIN ANALYZE
SELECT
    employee_id,
    COUNT(*) AS total_sales,
    SUM(quantity) AS total_quantity
FROM
    Sales
WHERE
    sale_date BETWEEN '2024-10-01' AND '2024-11-30'
GROUP BY
    employee_id

-- 6.Используя трассировку, проанализируйте запрос, который находит общее количество проданных единиц каждого продукта.
EXPLAIN ANALYZE
SELECT
    s.product_id,
    p.name,
    SUM(quantity) AS total_quantity
FROM
    Sales s
JOIN
    products p ON s.product_id = p.product_id
GROUP BY
    s.product_id,p.name
ORDER BY
    total_quantity DESC
LIMIT 5;

