PRAGMA foreign_keys = ON;

-- Удаление старых таблиц
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS boxes;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS service_categories;
DROP TABLE IF EXISTS employees;

-- 1. Мастера/работники
CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    position TEXT NOT NULL DEFAULT 'Мастер',
    salary_percent REAL NOT NULL DEFAULT 30.0 CHECK(salary_percent >= 0 AND salary_percent <= 100),
    hire_date TEXT NOT NULL DEFAULT (date('now')),
    fire_date TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1))
);

-- 2. Категории автомобилей
CREATE TABLE service_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

-- 3. Услуги
CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    duration_min INTEGER NOT NULL CHECK(duration_min > 0),
    price REAL NOT NULL CHECK(price >= 0),
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE RESTRICT
);

-- 4. Боксы
CREATE TABLE boxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    number INTEGER NOT NULL UNIQUE CHECK(number > 0),
    description TEXT DEFAULT ''
);

-- 5. Клиенты
CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    car_model TEXT DEFAULT '',
    car_plate TEXT DEFAULT ''
);

-- 6. Записи (план + факт)
CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    box_id INTEGER NOT NULL,
    appointment_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planned' 
        CHECK(status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    actual_duration_min INTEGER,
    revenue REAL,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE RESTRICT
);

-- Индексы для статистики
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_employee ON appointments(employee_id);
CREATE INDEX idx_appointments_box ON appointments(box_id);
CREATE INDEX idx_employees_active ON employees(is_active);

-- ===== ТЕСТОВЫЕ ДАННЫЕ =====

-- Мастера (один уволен)
INSERT INTO employees (full_name, position, salary_percent, hire_date, fire_date, is_active) VALUES
('Иванов Иван Иванович', 'Старший мастер', 40.0, '2022-03-01', NULL, 1),
('Петров Петр Петрович', 'Мастер', 30.0, '2023-01-15', NULL, 1),
('Сидоров Сидор Сидорович', 'Мастер', 25.0, '2021-06-10', '2024-08-01', 0),
('Козлова Анна Михайловна', 'Администратор', 20.0, '2023-05-20', NULL, 1);

-- Категории авто
INSERT INTO service_categories (name) VALUES
('Легковой'),
('Внедорожник'),
('Грузовой'),
('Мотоцикл');

-- Услуги
INSERT INTO services (category_id, name, duration_min, price) VALUES
(1, 'Экспресс-мойка', 15, 500.0),
(1, 'Комплексная мойка', 45, 1200.0),
(1, 'Химчистка салона', 120, 3500.0),
(1, 'Полировка кузова', 180, 5000.0),
(2, 'Мойка внедорожника', 60, 1500.0),
(2, 'Комплекс внедорожника', 90, 2500.0),
(3, 'Мойка грузовика', 90, 2000.0),
(4, 'Мойка мотоцикла', 30, 700.0);

-- Боксы
INSERT INTO boxes (number, description) VALUES
(1, 'Основной бокс с подъемником'),
(2, 'Бокс для легковых'),
(3, 'Бокс для грузовых');

-- Клиенты
INSERT INTO clients (full_name, phone, car_model, car_plate) VALUES
('Смирнов Алексей', '+79001112233', 'Toyota Camry', 'А123БВ77'),
('Волкова Мария', '+79004445566', 'BMW X5', 'В456ГД77'),
('Новиков Дмитрий', '+79007778899', 'KAMAZ 5490', 'Е789ЖЗ77'),
('Белова Ольга', '+79001234567', 'Honda CBR600', 'И012КЛ77');

-- Записи (разные статусы)
INSERT INTO appointments (client_id, service_id, employee_id, box_id, appointment_date, start_time, status, actual_duration_min, revenue) VALUES
(1, 2, 1, 2, '2024-11-20', '10:00', 'completed', 50, 1200.0),
(2, 5, 2, 1, '2024-11-20', '11:00', 'completed', 65, 1500.0),
(3, 7, 1, 3, '2024-11-21', '09:00', 'completed', 95, 2000.0),
(4, 8, 2, 2, '2024-11-22', '14:00', 'planned', NULL, NULL),
(1, 4, 1, 2, '2024-11-23', '10:00', 'planned', NULL, NULL),
(2, 3, 3, 1, '2024-10-15', '12:00', 'completed', 130, 3500.0);