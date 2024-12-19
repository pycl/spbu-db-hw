-- Триггер: автоматическое обновление состояния комнаты при изменении статуса бронирования
CREATE OR REPLACE FUNCTION update_room_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'checked_in' THEN
        UPDATE rooms SET status = 'occupied'
        WHERE room_id = NEW.room_id;
    ELSIF NEW.status = 'checked_out' THEN
        UPDATE rooms SET status = 'available'
        WHERE room_id = NEW.room_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reservation_status_change ON reservations;
CREATE TRIGGER reservation_status_change
AFTER UPDATE ON reservations
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION update_room_status();
-- Пример   
UPDATE reservations 
SET status = 'checked_in'
WHERE reservation_id = 1;

-- Триггер: автоматическое вычисление общей стоимости бронирования при добавлении нового бронирования
CREATE OR REPLACE FUNCTION calculate_total_price()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_price :=(
        SELECT price_per_night * (NEW.check_out_date - NEW.check_in_date)
        FROM rooms
        WHERE room_id = NEW.room_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_reservation_insert ON reservations;
CREATE TRIGGER before_reservation_insert
BEFORE INSERT ON reservations
FOR EACH ROW
EXECUTE FUNCTION calculate_total_price();

--Пример
ALTER TABLE public.reservations ALTER COLUMN total_price DROP NOT NULL;
INSERT INTO reservations (guest_id, room_id, check_in_date, check_out_date, status)
VALUES (6, 6, '2024-12-01', '2024-12-05', 'confirmed');

-- Транзакция: создание бронирования и оплаты
CREATE OR REPLACE PROCEDURE create_reservation_with_payment(
    p_guest_id INT,
    p_room_id INT,
    p_check_in_date DATE,
    p_check_out_date DATE,
    p_payment_method VARCHAR(10)
) AS $$
DECLARE
    --переменные
    --Значения здесь автоматически заполняются при вставке данных.
    v_reservation_id INT;
    v_total_price DECIMAL(10,2);
BEGIN
    --проверка на наличие свободной комнаты
    IF NOT EXISTS (
        SELECT * FROM rooms
        WHERE room_id = p_room_id
        AND status = 'available'
    ) THEN
        RAISE EXCEPTION 'Room is not available';
    END IF;

-- Создание бронирования
    INSERT INTO reservations(
        guest_id, room_id, check_in_date, check_out_date, status
    ) VALUES(
        p_guest_id, p_room_id, p_check_in_date, p_check_out_date, 'confirmed'
    ) RETURNING reservation_id, total_price INTO v_reservation_id, v_total_price;

-- Создание оплаты
    INSERT INTO payments(
        reservation_id, amount, payment_method,status
    )VALUES(
        v_reservation_id, v_total_price, p_payment_method, 'completed'
    );

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при создании бронирования и оплаты: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Пример
BEGIN;
CALL create_reservation_with_payment(6, 7, '2024-12-15', '2024-12-20', 'cash');
COMMIT;

