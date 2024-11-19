-- промежуточные таблицы.связывает студентов с курсами
CREATE TABLE student_courses (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(255) NOT NULL,
    course_id VARCHAR(255) NOT NULL,
    UNIQUE (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES Students(id),
    FOREIGN KEY (course_id) REFERENCES Courses(id)
);

-- связывает группы с курсами.
CREATE TABLE group_courses (
    id SERIAL PRIMARY KEY,
    group_id VARCHAR(255) NOT NULL,
    course_id VARCHAR(255) NOT NULL,
    UNIQUE (group_id, course_id),
    FOREIGN KEY (group_id) REFERENCES Groups(id),
    FOREIGN KEY (course_id) REFERENCES Courses(id)
);


INSERT INTO student_courses (student_id, course_id) VALUES
('st1', '1'),
('st1', '2'),
('st2', '1'),
('st2', '3'),
('st3', '1'),
('st3', '4'),
('st4', '2'),
('st4', '3'),
('st5', '2'),
('st5', '4'),
('st6', '3'),
('st6', '4');


INSERT INTO group_courses (group_id, course_id) VALUES
('1', '1'),
('1', '2'),
('1', '3'),
('1', '4'),
('2', '2'),
('2', '3'),
('3', '2'),
('3', '4');

-- Удалить неактуальные поля
ALTER TABLE Students DROP COLUMN courses_ids;

-- гарантировать уникальное отношение
ALTER TABLE Courses ADD CONSTRAINT unique_course_name UNIQUE (name);

-- Создать индекс
-- После создания индекса база данных при выполнении запросов, 
-- связанных с полем group_id, может быстрее находить необходимые строки данных.
-- При создании индекса по умолчанию используется структура B+ дерево. 
-- Если индекс не создается, необходимо просканировать все записи в таблице, 
-- но при использовании индекса B+ дерева требуется доступ лишь к нескольким уровням узлов дерева.
CREATE INDEX idx_students_group_id ON Students(group_id);

-- покажет список всех студентов с их курсами
SELECT
    s.id AS student_id,
    s.first_name,
    s.last_name,
    c.id AS course_id,
    c.name AS course_name
FROM
    Students s
JOIN
    student_courses sc ON s.id = sc.student_id
JOIN
    Courses c ON sc.course_id = c.id
ORDER BY
    s.id, c.id
LIMIT 3;

-- Найти студентов, у которых средняя оценка по курсам выше, чем у любого другого студента в их группе.
-- Поскольку ранее мы создали только таблицу по математике, 
-- нам необходимо определить студентов с наивысшими математическими оценками в каждой группе.
WITH student_avg_grades AS (
    SELECT
        s.id AS student_id,
        s.group_id,
        AVG(m.grade) AS avg_grade
    FROM
        Students s
    JOIN  
        Math m ON s.id = m.students_id
    GROUP BY
        s.group_id,s.id
),
-- Найти каждую группу с наивысшей средней оценкой
group_max_grades AS (
    SELECT
        group_id,
        MAX(avg_grade) AS max_group_grade
    FROM
        student_avg_grades
    GROUP BY
        group_id
)
-- Найти каждого студента в каждой группе с наивысшей средней оценкой
SELECT
    sag.group_id,
    sag.student_id,
    s.first_name,
    s.last_name,
    sag.avg_grade
FROM
    student_avg_grades sag
JOIN
    group_max_grades gmg ON sag.group_id = gmg.group_id
JOIN
    Students s ON sag.student_id = s.id
WHERE
    sag.avg_grade = gmg.max_group_grade;

-- Подсчитать количество студентов на каждом курсе.
SELECT
    c.id AS course_id,
    c.name AS course_name,
    COUNT(sc.student_id) AS student_count
FROM
    Courses c
LEFT JOIN
    student_courses sc ON c.id = sc.course_id
GROUP BY
    c.id, c.name
LIMIT 3;

-- Найти среднюю оценку на каждом курсе.
--Поскольку в данный момент в базе данных имеется только таблица по математике, 
--нам необходимо только вычислить средний балл по математике.
SELECT
    c.id AS course_id,
    c.name AS course_name,
    AVG(m.grade) AS average_grade
FROM
    Courses c,
    Math m
WHERE 
    c.name = 'Math'
GROUP BY
    c.id, c.name
LIMIT 3;