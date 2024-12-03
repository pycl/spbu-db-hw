-- Таблица для комнат
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    room_type VARCHAR(50) NOT NULL,  -- single, double, suite
    floor_number INT NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    capacity INT NOT NULL,  -- number of people
    status VARCHAR(20) DEFAULT 'available'  -- available, occupied, maintenance
);
-- Таблица для гостей
CREATE TABLE guests (
    guest_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    passport_number VARCHAR(18) UNIQUE NOT NULL,  -- passport number
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для персонала
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,  -- manager, receptionist, housekeeper
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    hire_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active'  -- active, inactive
);

-- Таблица для бронирований
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    guest_id INT REFERENCES guests(guest_id),
    room_id INT REFERENCES rooms(room_id),
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'confirmed',  -- confirmed, checked_in, checked_out, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (check_out_date > check_in_date)
);

-- Таблица для оплат
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    reservation_id INT REFERENCES reservations(reservation_id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,  -- cash, credit_card, debit_card
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'completed'  -- completed, pending, failed
);

-- Таблица для дополнительных услуг
CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL
);

-- Таблица для заказов дополнительных услуг
CREATE TABLE service_orders (
    order_id SERIAL PRIMARY KEY,
    reservation_id INT REFERENCES reservations(reservation_id),
    service_id INT REFERENCES services(service_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quantity INT DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'completed'  -- completed, cancelled
);

-- Таблица для журнала обслуживания
CREATE TABLE maintenance_logs (
    log_id SERIAL PRIMARY KEY,
    room_id INT REFERENCES rooms(room_id),
    staff_id INT REFERENCES staff(staff_id),
    maintenance_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'  -- pending, completed
);

-- Вставка данных в таблицу rooms
INSERT INTO rooms (room_number, room_type, floor_number, price_per_night, capacity, status)
VALUES 
('101', 'single', 1, 100.00, 1, 'available'),
('102', 'double', 1, 150.00, 2, 'occupied'),
('201', 'suite', 2, 300.00, 4, 'available'),
('202', 'double', 2, 180.00, 2, 'available'),
('203', 'single', 2, 120.00, 1, 'maintenance'),
('301', 'suite', 3, 350.00, 4, 'occupied'),
('302', 'double', 3, 200.00, 2, 'available');

-- Вставка данных в таблицу guests
INSERT INTO guests (first_name, last_name, passport_number, phone, email)
VALUES 
('Иван', 'Иванов', '123456789', '+71234567890', 'ivanov@gmail.com'),
('Мария', 'Петрова', '987654321', '+79876543210', 'petrova@gmail.com'),
('Анна', 'Сидорова', '456789123', '+79991112233', 'sidorova@gmail.com'),
('Дмитрий', 'Козлов', '789123456', '+79992223344', 'kozlov@gmail.com'),
('Елена', 'Морозова', '321654987', '+79993334455', 'morozova@gmail.com'),
('Сергей', 'Волков', '147258369', '+79994445566', 'volkov@gmail.com'),
('Татьяна', 'Соколова', '963852741', '+79995556677', 'sokolova@gmail.com');

-- Вставка данных в таблицу staff
INSERT INTO staff (first_name, last_name, position, phone, email, hire_date, status)
VALUES 
('Алексей', 'Смирнов', 'manager', '+71112223344', 'smirnov@gmail.com', '2023-01-15', 'active'),
('Ольга', 'Кузнецова', 'receptionist', '+79998887766', 'kuznetsova@gmail.com', '2023-02-20', 'active'),
('Николай', 'Попов', 'housekeeper', '+79161112233', 'popov@gmail.com', '2023-03-15', 'active'),
('Екатерина', 'Васильева', 'receptionist', '+79162223344', 'vasileva@gmail.com', '2023-04-01', 'active'),
('Андрей', 'Михайлов', 'manager', '+79163334455', 'mikhailov@gmail.com', '2023-05-10', 'active'),
('Ирина', 'Новикова', 'housekeeper', '+79164445566', 'novikova@gmail.com', '2023-06-20', 'inactive'),
('Павел', 'Федоров', 'receptionist', '+79165556677', 'fedorov@gmail.com', '2023-07-01', 'active');

-- Вставка данных в таблицу reservations
INSERT INTO reservations (guest_id, room_id, check_in_date, check_out_date, total_price, status)
VALUES 
(1, 1, '2024-10-01', '2024-10-05', 400.00, 'confirmed'),
(2, 2, '2024-10-03', '2024-10-07', 600.00, 'checked_in'),
(3, 3, '2024-10-10', '2024-10-15', 600.00, 'confirmed'),
(4, 4, '2024-10-12', '2024-10-14', 700.00, 'confirmed'),
(5, 5, '2024-10-15', '2024-10-20', 1000.00, 'confirmed'),
(1, 2, '2024-10-18', '2024-10-22', 720.00, 'confirmed'),
(2, 1, '2024-10-25', '2024-10-30', 1500.00, 'confirmed');

-- Вставка данных в таблицу payments
INSERT INTO payments (reservation_id, amount, payment_method, status)
VALUES 
(1, 400.00, 'credit_card', 'completed'),
(2, 600.00, 'debit_card', 'pending'),
(3, 600.00, 'cash', 'completed'),
(4, 700.00, 'credit_card', 'completed'),
(5, 1000.00, 'debit_card', 'completed'),
(6, 720.00, 'cash', 'pending'),
(7, 1500.00, 'credit_card', 'completed');

-- Вставка данных в таблицу services
INSERT INTO services (service_name, description, price)
VALUES 
('Room Service', '24/7 room service', 50.00),
('Spa', 'Access to spa facilities', 100.00),
('Прачечная', 'Услуги прачечной и глажки', 30.00),
('Трансфер', 'Трансфер из/в аэропорт', 80.00),
('Фитнес-зал', 'Доступ в фитнес-зал', 40.00),
('Завтрак', 'Завтрак в номер', 25.00),
('Экскурсии', 'Организация экскурсий', 150.00);

-- Вставка данных в таблицу service_orders
INSERT INTO service_orders (reservation_id, service_id, quantity, total_price, status)
VALUES 
(1, 1, 2, 100.00, 'completed'),
(2, 2, 1, 100.00, 'completed'),
(3, 3, 1, 40.00, 'completed'),
(4, 4, 2, 50.00, 'completed'),
(5, 5, 1, 150.00, 'completed'),
(1, 3, 3, 120.00, 'completed'),
(2, 4, 1, 25.00, 'cancelled');

-- Вставка данных в таблицу maintenance_logs
INSERT INTO maintenance_logs (room_id, staff_id, description, status)
VALUES 
(1, 1, 'Ремонт кондиционеров', 'pending'),
(2, 1, 'Проверка водопровода', 'completed'),
(3, 2, 'Замена телевизора', 'completed'),
(4, 7, 'Проверка пожарной сигнализации', 'completed'),
(5, 5, 'Замена постельного белья', 'completed'),
(1, 6, 'Уборка номера', 'completed'),
(2, 3, 'Дезинфекция помещения', 'pending');

