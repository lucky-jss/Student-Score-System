USE score_system;
DROP VIEW IF EXISTS v_student_my_score;
DROP VIEW IF EXISTS v_teacher_my_class_score;
DROP VIEW IF EXISTS v_admin_full_score;

-- 1.学生视图：仅展示当前学生本人成绩，过滤已删除数据
CREATE VIEW v_student_my_score AS
SELECT
    s.student_no AS 学号,
    s.name AS 学生姓名,
    c.class_name AS 班级,
    m.major_name AS 专业,
    d.dept_name AS 系部,
    sub.subject_code AS 科目编号,
    sub.subject_name AS 科目名称,
    sub.credit AS 学分,
    sem.semester_name AS 学期,
    sc.score AS 分数,
    sc.grade AS 等级,
    gs.gpa AS 绩点
FROM scores sc
         JOIN students s ON sc.student_id = s.id
         JOIN classes c ON s.class_id = c.id
         JOIN majors m ON c.major_id = m.id
         JOIN departments d ON m.department_id = d.id
         JOIN subjects sub ON sc.subject_id = sub.id
         JOIN semesters sem ON sc.semester_id = sem.id
         LEFT JOIN grading_settings gs ON sc.subject_id = gs.subject_id AND sc.semester_id = gs.semester_id AND sc.grade = gs.grade
WHERE sc.is_deleted = 0 AND s.is_deleted = 0;

-- 学生查询示例（DB.executeQuery直接调用）
-- SELECT * FROM v_student_my_score WHERE 学号 = ?

-- 2.教师视图：仅教师可查看所有学生成绩，按系部隔离
CREATE VIEW v_teacher_my_class_score AS
SELECT
    u.username AS 教师账号,
    u.real_name AS 教师姓名,
    d.dept_name AS 教师所属系部,
    s.student_no AS 学号,
    s.name AS 学生姓名,
    c.class_name AS 班级,
    sub.subject_name AS 科目,
    sem.semester_name AS 学期,
    sc.score AS 分数,
    sc.recorded_at AS 录入时间
FROM scores sc
         JOIN users u ON sc.recorded_by = u.id
         JOIN students s ON sc.student_id = s.id
         JOIN classes c ON s.class_id = c.id
         JOIN majors m ON c.major_id = m.id
         JOIN departments d ON m.department_id = d.id
         JOIN subjects sub ON sc.subject_id = sub.id
         JOIN semesters sem ON sc.semester_id = sem.id
WHERE sc.is_deleted = 0 AND u.is_deleted = 0;

-- 教师查询示例
-- SELECT * FROM v_teacher_my_class_score WHERE 教师账号 = ?

-- 3.管理员全量视图：完整所有成绩+操作人+审计基础信息
CREATE VIEW v_admin_full_score AS
SELECT
    sc.id AS 成绩主键,
    s.student_no,
    s.name AS 学生姓名,
    c.class_name,
    m.major_name,
    d.dept_name,
    sub.subject_code,
    sub.subject_name,
    sem.semester_name,
    sc.score,
    sc.grade,
    u.real_name AS 录入教师,
    sc.recorded_at,
    sc.created_at,
    sc.updated_at,
    sc.is_deleted
FROM scores sc
         JOIN students s ON sc.student_id = s.id
         JOIN classes c ON s.class_id = c.id
         JOIN majors m ON c.major_id = m.id
         JOIN departments d ON m.department_id = d.id
         JOIN subjects sub ON sc.subject_id = sub.id
         JOIN semesters sem ON sc.semester_id = sem.id
         JOIN users u ON sc.recorded_by = u.id;