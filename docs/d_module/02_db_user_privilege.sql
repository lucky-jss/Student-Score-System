USE mysql;
-- 删除旧账号
DROP USER IF EXISTS 'stu_db'@'localhost';
DROP USER IF EXISTS 'tea_db'@'localhost';
DROP USER IF EXISTS 'admin_db'@'localhost';

-- 1.学生数据库账号（仅查学生视图，禁止操作原始表）
CREATE USER 'stu_db'@'localhost' IDENTIFIED BY 'stu123456';
GRANT SELECT ON score_system.v_student_my_score TO 'stu_db'@'localhost';
REVOKE ALL ON score_system.* FROM 'stu_db'@'localhost';

-- 2.教师数据库账号（可增删改成绩、查教师视图，禁止管理员视图）
CREATE USER 'tea_db'@'localhost' IDENTIFIED BY 'tea123456';
GRANT SELECT,INSERT,UPDATE,DELETE ON score_system.scores TO 'tea_db'@'localhost';
GRANT SELECT ON score_system.v_teacher_my_class_score TO 'tea_db'@'localhost';
GRANT SELECT ON score_system.subjects,score_system.semesters,score_system.students,score_system.classes,score_system.majors,score_system.departments TO 'tea_db'@'localhost';
REVOKE SELECT ON score_system.v_admin_full_score FROM 'tea_db'@'localhost';

-- 3.管理员数据库账号（全权限，可执行存储过程、触发器、视图）
CREATE USER 'admin_db'@'localhost' IDENTIFIED BY 'adm123456';
GRANT ALL PRIVILEGES ON score_system.* TO 'admin_db'@'localhost';

FLUSH PRIVILEGES;