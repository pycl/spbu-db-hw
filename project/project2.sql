-- Создание временной таблицы для анализа загруженности отеля
DROP TABLE IF EXISTS hotel_occupancy; 

CREATE TEMP TABLE hotel_occupancy AS
SELECT
    r.check_in_date,
    COUNT(r.reservation_id) as total_reservations,
    COUNT(DISTINCT r.room_id) as total_rooms,
    ROUND(COUNT(DISTINCT r.room_id)::numeric/
    (SELECT COUNT(*) FROM rooms)::numeric * 100,2) as occupancy_percentage
FROM reservations r
WHERE r.status = 'confirmed'
GROUP BY r.check_in_date;

SELECT * FROM hotel_occupancy
WHERE occupancy_percentage > 80
ORDER BY check_in_date DESC
LIMIT 10;

-- Представление для текущей загрузки отеля
CREATE OR REPLACE VIEW current_hotel_status AS
SELECT
    rm.room_number,
    rm.room_type,
    rm.status,
    g.first_name || ' ' || g.last_name as guest_name,
    r.check_in_date,
    r.check_out_date
FROM room rm
LEFT JOIN reservations r ON rm.room_id = r.room_id AND r.status = 'checked_in'
LEFT JOIN guests g ON r.guest_id = g.guest_id;

-- Представление для финансовой отчетности
CREATE OR REPLACE VIEW financial_summary AS
SELECT
    DATE_TRUNC('month', r.check_in_date) as month,
    COUNT(r.reservation_id) as total_reservations,
    SUM(r.total_price) as room_revenue,
    SUM(so.total_price) as service_revenue,
    SUM(r.total_price + COALESCE(so.total_price, 0)) as total_revenue
FROM reservations r
LEFT JOIN services_orders so ON r.reservation_id = so.reservation_id
WHERE r.status != 'cancelled'
GROUP BY month
ORDER BY month DESC;


-- Функция для валидации телефонного номера
CREATE OR REPLACE FUNCTION is_valid_phone(phone TEXT)  
RETURNS BOOLEAN AS $$  
BEGIN  
    -- Проверка, соответствует ли номер формату: +7 (XXX) XXX-XX-XX или 8 (XXX) XXX-XX-XX
    RETURN phone ~ E'^(\\+7|8) \\([0-9]{3}\\) [0-9]{3}-[0-9]{2}-[0-9]{2}$';  
END;  
$$ LANGUAGE plpgsql;

-- Использование функции в ограничении
ALTER TABLE guests
ADD CONSTRAINT valid_phone 
    CHECK (phone IS NULL OR is_valid_phone(phone));

-- Ошибка,так как он нарушает проверочное ограничение "valid_phone".
INSERT INTO guests (first_name, last_name, passport_number, phone, email)
VALUES 
('Иван', 'Иванов', '123456789', '+71234567890', 'ivanov@gmail.com');
