-- Простой запрос для получения всех доступных комнат:
CREATE INDEX idx_rooms_status ON rooms(status);
SELECT * 
FROM rooms 
WHERE status = 'available'
LIMIT 10;


-- Получение информации о текущих бронированиях с данными гостей:
CREATE INDEX idx_reservations_status ON reservations(status);
SELECT 
    r.reservation_id,
    g.first_name,
    g.last_name,
    rm.room_number,
    r.check_in_date,
    r.check_out_date,
    r.total_price
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
JOIN rooms rm ON r.room_id = rm.room_id
WHERE r.status = 'confirmed'
LIMIT 10;

-- Отчет по обслуживанию номеров с информацией о сотрудниках В прошлом месяце:
SELECT
    rm.room_number,
    ml.maintenance_date,
    ml.description,
    ml.status,
    s.first_name,
    s.last_name,
    s.position
FROM maintenance_logs ml
JOIN rooms rm ON ml.room_id = rm.room_id
JOIN staff s ON ml.staff_id = s.staff_id
WHERE ml.maintenance_date >= CURRENT_DATE - INTERVAL '1 month'
LIMIT 10;


-- Агрегаций
-- Анализ доходов по типам комнат за последний 2 месяц:
SELECT 
    rm.room_type,
    COUNT(r.reservation_id) AS total_reservations,
    SUM(r.total_price) AS total_revenue,
    ROUND(AVG(r.total_price), 2)AS average_revenue_per_reservation,
    MIN(r.total_price) AS min_revenue,
    MAX(r.total_price) AS max_revenue
FROM reservations r
JOIN rooms rm ON r.room_id = rm.room_id
WHERE r.check_in_date >= CURRENT_DATE - INTERVAL '2 month'
GROUP BY rm.room_type
HAVING COUNT(r.reservation_id) > 0
ORDER BY total_revenue DESC
LIMIT 10;

-- Статистика по заказам дополнительных услуг:
SELECT 
    s.service_name,
    COUNT(so.order_id) AS total_orders,
    SUM(so.total_price) AS total_revenue,
    SUM(so.quantity) AS total_quantity_sold,
    AVG(so.total_price) AS avg_order_value,
    COUNT(DISTINCT r.guest_id) AS unique_guests
FROM service_orders so
JOIN services s ON so.service_id = s.service_id
JOIN reservations r ON so.reservation_id = r.reservation_id
WHERE so.status = 'completed'
GROUP BY s.service_name
ORDER BY total_revenue DESC
LIMIT 10;

--Анализ загруженности персонала по обслуживанию номеров:
SELECT
    s.first_name || ' ' || s.last_name AS staff_name,
    s.position,
    COUNT(ml.log_id) AS total_tasks,
    COUNT(CASE WHEN ml.status = 'completed' THEN 1 END) AS completed_tasks,
    COUNT(CASE WHEN ml.status = 'pending' THEN 1 END) AS pending_tasks,
    COUNT(DISTINCT ml.room_id) AS unique_rooms_serviced
FROM maintenance_logs ml
JOIN staff s ON ml.staff_id = s.staff_id
WHERE ml.maintenance_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY s.staff_id
HAVING COUNT(ml.log_id) > 0
ORDER BY total_tasks DESC
LIMIT 10;




