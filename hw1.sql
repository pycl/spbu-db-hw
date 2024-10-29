CREATE TABLE Courses(
    id        VARCHAR(255) PRIMARY KEY    NOT NULL,
    name      VARCHAR(30)  NOT NULL,
    is_exam   BOOLEAN      NOT NULL,
    min_grade INTEGER      NOT NULL,
    max_grade INTEGER      NOT NULL 
);

CREATE TABLE Groups(
    id        VARCHAR(255) PRIMARY KEY    NOT NULL,
    full_name VARCHAR(30)                 NOT NULL,
    short_name VARCHAR(30)                 NOT NULL,
    students_ids VARCHAR(255)             NOT null
);

CREATE TABLE Students(
    id          VARCHAR(255) PRIMARY KEY  NOT NULL,
    first_name  VARCHAR(30)               NOT NULL,
    last_name   VARCHAR(30)               NOT NULL,
    group_id    VARCHAR(255)              NOT NULL,
    courses_ids VARCHAR(255)              NOT NULL,
    FOREIGN KEY (group_id) REFERENCES groups(id)  
);

CREATE TABLE Math(
    students_id VARCHAR(255) PRIMARY KEY  NOT NULL,
    grade       INTEGER                   NOT NULL,
    grade_str   VARCHAR(255)              NOT NULL,
    FOREIGN KEY (students_id) REFERENCES Students(id)
);

INSERT INTO Courses(id,name,is_exam,min_grade,max_grade) VALUES
(1, 'Math', TRUE, 65, 89),
(2, 'Русский язык', FALSE, 0, 0),
(3, 'Физика', TRUE, 73, 85),
(4, 'Информатика', TRUE, 81, 98); 

INSERT INTO groups(id,full_name,short_name,students_ids) VALUES
(1, 'Группа 1', 'г1', 'st1,st2'),  
(2, 'Группа 2', 'г2', 'st3,st4'),
(3, 'Группа 3', 'г3', 'st5,st6');  

INSERT INTO Students(id,first_name,last_name,group_id,courses_ids) VALUES
('st1', 'Иван', 'Иванов', 1, '1,2'),  
('st2', 'Пётр', 'Петров', 1, '1,3'),  
('st3', 'Владимир', 'Жуков', 1, '1,4'),
('st4', 'Александр', 'Смирнов', 2, '2,3'),
('st5', 'Николай', 'Белоусов', 3, '2,4'), 
('st6', 'Даяна', 'Кириллова', 3, '3,4');

INSERT INTO Math(students_id,grade,grade_str) VALUES
('st1', 65, 'min65-max89'),
('st2', 78, 'min65-max89'),
('st3', 89, 'min65-max89');

-- Фильтрация: найти студентов, получивших балл выше минимального по математике  
SELECT s.first_name,s.last_name,m.grade,c.name AS subject
FROM Students s
JOIN Math m ON s.id = m.students_id
JOIN Courses c ON name = 'Math'
WHERE m.grade > c.min_grade;

-- Агрегация: вычислить средний балл по математике 
SELECT c.min_grade, c.max_grade, (SELECT AVG(grade) FROM Math) AS average_grade  
FROM Courses c  
WHERE c.name = 'Math';

