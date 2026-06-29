-- ============================================================
-- 统计分析存储过程与窗口函数
-- ============================================================

USE score_system;

-- ============================================================
-- 存储过程：按系部统计成绩
-- 输入参数：semester_id（学期ID，可选，不传则统计所有学期）
-- 返回：系部ID、系部名称、学生总数、平均分、最高分、最低分、不及格人数、优秀人数
-- ============================================================
DROP PROCEDURE IF EXISTS sp_stat_by_department;
DELIMITER //
CREATE PROCEDURE sp_stat_by_department(IN p_semester_id INT)
BEGIN
SELECT
    d.id AS department_id,
    d.dept_name,
    COUNT(DISTINCT s.id) AS student_count,
    ROUND(AVG(sc.score), 2) AS avg_score,
    MAX(sc.score) AS max_score,
    MIN(sc.score) AS min_score,
    SUM(CASE WHEN sc.score < 60 THEN 1 ELSE 0 END) AS failed_count,
    SUM(CASE WHEN sc.score >= 90 THEN 1 ELSE 0 END) AS excellent_count,
    ROUND(SUM(CASE WHEN sc.score < 60 THEN 1 ELSE 0 END) / COUNT(sc.id) * 100, 2) AS failed_rate
FROM departments d
         LEFT JOIN majors m ON d.id = m.department_id AND m.is_deleted = 0
         LEFT JOIN classes c ON m.id = c.major_id AND c.is_deleted = 0
         LEFT JOIN students s ON c.id = s.class_id AND s.is_deleted = 0 AND s.status = 1
         LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
WHERE d.is_deleted = 0
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY d.id, d.dept_name
ORDER BY avg_score DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：按专业统计成绩
-- 输入参数：semester_id（学期ID，可选）、department_id（系部ID，可选）
-- 返回：专业ID、专业名称、所属系部、学生总数、平均分、最高分、最低分、不及格人数
-- ============================================================
DROP PROCEDURE IF EXISTS sp_stat_by_major;
DELIMITER //
CREATE PROCEDURE sp_stat_by_major(IN p_semester_id INT, IN p_department_id INT)
BEGIN
SELECT
    m.id AS major_id,
    m.major_name,
    d.dept_name AS department_name,
    COUNT(DISTINCT s.id) AS student_count,
    ROUND(AVG(sc.score), 2) AS avg_score,
    MAX(sc.score) AS max_score,
    MIN(sc.score) AS min_score,
    SUM(CASE WHEN sc.score < 60 THEN 1 ELSE 0 END) AS failed_count,
    ROUND(SUM(CASE WHEN sc.score >= 85 THEN 1 ELSE 0 END) / COUNT(sc.id) * 100, 2) AS excellent_rate
FROM majors m
         LEFT JOIN departments d ON m.department_id = d.id AND d.is_deleted = 0
         LEFT JOIN classes c ON m.id = c.major_id AND c.is_deleted = 0
         LEFT JOIN students s ON c.id = s.class_id AND s.is_deleted = 0 AND s.status = 1
         LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
WHERE m.is_deleted = 0
  AND (p_department_id IS NULL OR m.department_id = p_department_id)
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY m.id, m.major_name, d.dept_name
ORDER BY avg_score DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：按班级统计成绩
-- 输入参数：semester_id（学期ID，可选）、major_id（专业ID，可选）、department_id（系部ID，可选）
-- 返回：班级ID、班级名称、所属专业、学生总数、平均分、最高分、最低分、不及格人数、及格率
-- ============================================================
DROP PROCEDURE IF EXISTS sp_stat_by_class;
DELIMITER //
CREATE PROCEDURE sp_stat_by_class(IN p_semester_id INT, IN p_major_id INT, IN p_department_id INT)
BEGIN
SELECT
    c.id AS class_id,
    c.class_name,
    m.major_name,
    COUNT(DISTINCT s.id) AS student_count,
    ROUND(AVG(sc.score), 2) AS avg_score,
    MAX(sc.score) AS max_score,
    MIN(sc.score) AS min_score,
    SUM(CASE WHEN sc.score < 60 THEN 1 ELSE 0 END) AS failed_count,
    SUM(CASE WHEN sc.score >= 60 THEN 1 ELSE 0 END) AS passed_count,
    ROUND(SUM(CASE WHEN sc.score >= 60 THEN 1 ELSE 0 END) / COUNT(sc.id) * 100, 2) AS pass_rate
FROM classes c
         LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
         LEFT JOIN students s ON c.id = s.class_id AND s.is_deleted = 0 AND s.status = 1
         LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
WHERE c.is_deleted = 0
  AND (p_major_id IS NULL OR c.major_id = p_major_id)
  AND (p_department_id IS NULL OR m.department_id = p_department_id)
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY c.id, c.class_name, m.major_name
ORDER BY avg_score DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：按科目统计成绩
-- 输入参数：semester_id（学期ID，可选）、department_id（系部ID，可选）
-- 返回：科目ID、科目名称、学分、平均分、最高分、最低分、标准差、不及格人数
-- ============================================================
DROP PROCEDURE IF EXISTS sp_stat_by_subject;
DELIMITER //
CREATE PROCEDURE sp_stat_by_subject(IN p_semester_id INT, IN p_department_id INT)
BEGIN
SELECT
    sub.id AS subject_id,
    sub.subject_name,
    sub.credit,
    COUNT(sc.id) AS score_count,
    ROUND(AVG(sc.score), 2) AS avg_score,
    MAX(sc.score) AS max_score,
    MIN(sc.score) AS min_score,
    ROUND(STDDEV(sc.score), 2) AS std_dev,
    SUM(CASE WHEN sc.score < 60 THEN 1 ELSE 0 END) AS failed_count,
    ROUND(SUM(CASE WHEN sc.score >= 60 THEN 1 ELSE 0 END) / COUNT(sc.id) * 100, 2) AS pass_rate
FROM subjects sub
         LEFT JOIN scores sc ON sub.id = sc.subject_id AND sc.is_deleted = 0
WHERE sub.is_deleted = 0
  AND (p_department_id IS NULL OR sub.department_id = p_department_id)
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY sub.id, sub.subject_name, sub.credit
ORDER BY avg_score DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：学生成绩排名（按班级）
-- 输入参数：class_id（班级ID，可选）、semester_id（学期ID，可选）、department_id（系部ID，可选）、major_id（专业ID，可选）
-- 返回：学生ID、学号、姓名、班级、总分、平均分、班级排名、年级排名
-- ============================================================
DROP PROCEDURE IF EXISTS sp_student_ranking;
DELIMITER //
CREATE PROCEDURE sp_student_ranking(
    IN p_class_id INT,
    IN p_semester_id INT,
    IN p_department_id INT,
    IN p_major_id INT
)
BEGIN
SELECT
    t.student_id,
    t.student_no,
    t.name,
    t.class_name,
    t.major_name,
    t.total_score,
    t.avg_score,
    t.subject_count,
    RANK() OVER (PARTITION BY t.class_id ORDER BY t.avg_score DESC) AS class_rank,
    RANK() OVER (ORDER BY t.avg_score DESC) AS school_rank,
    PERCENT_RANK() OVER (ORDER BY t.avg_score DESC) * 100 AS percentile_rank
FROM (
         SELECT
             s.id AS student_id,
             s.student_no,
             s.name,
             c.id AS class_id,
             c.class_name,
             m.major_name,
             SUM(sc.score) AS total_score,
             ROUND(AVG(sc.score), 2) AS avg_score,
             COUNT(sc.id) AS subject_count
         FROM students s
                  LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0
                  LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
                  LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
         WHERE s.is_deleted = 0 AND s.status = 1
           AND (p_class_id IS NULL OR s.class_id = p_class_id)
           AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
           AND (p_department_id IS NULL OR m.department_id = p_department_id)
           AND (p_major_id IS NULL OR c.major_id = p_major_id)
         GROUP BY s.id, s.student_no, s.name, c.id, c.class_name, m.major_name
     ) t
ORDER BY t.avg_score DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：成绩等级分布统计
-- 输入参数：semester_id（学期ID，可选）、department_id（系部ID，可选）
-- 返回：等级、人数、占比
-- ============================================================
DROP PROCEDURE IF EXISTS sp_score_grade_distribution;
DELIMITER //
CREATE PROCEDURE sp_score_grade_distribution(IN p_semester_id INT, IN p_department_id INT)
BEGIN
SELECT
    t.grade,
    t.count,
    ROUND(t.count / total.total_count * 100, 2) AS percentage
FROM (
         SELECT
             CASE
                 WHEN sc.score >= 90 THEN 'A'
                 WHEN sc.score >= 80 THEN 'B'
                 WHEN sc.score >= 70 THEN 'C'
                 WHEN sc.score >= 60 THEN 'D'
                 ELSE 'F'
                 END AS grade,
             COUNT(*) AS count
         FROM scores sc
             LEFT JOIN students s ON sc.student_id = s.id AND s.is_deleted = 0
             LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0
             LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
         WHERE sc.is_deleted = 0
           AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
           AND (p_department_id IS NULL OR m.department_id = p_department_id)
         GROUP BY CASE
             WHEN sc.score >= 90 THEN 'A'
             WHEN sc.score >= 80 THEN 'B'
             WHEN sc.score >= 70 THEN 'C'
             WHEN sc.score >= 60 THEN 'D'
             ELSE 'F'
             END
     ) t
         CROSS JOIN (
    SELECT COUNT(*) AS total_count
    FROM scores sc2
             LEFT JOIN students s2 ON sc2.student_id = s2.id AND s2.is_deleted = 0
             LEFT JOIN classes c2 ON s2.class_id = c2.id AND c2.is_deleted = 0
             LEFT JOIN majors m2 ON c2.major_id = m2.id AND m2.is_deleted = 0
    WHERE sc2.is_deleted = 0
      AND (p_semester_id IS NULL OR sc2.semester_id = p_semester_id)
      AND (p_department_id IS NULL OR m2.department_id = p_department_id)
) AS total
ORDER BY t.grade;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：计算学生GPA
-- 输入参数：student_id（学生ID）、semester_id（学期ID，可选）
-- 返回：学生ID、学号、姓名、GPA
-- ============================================================
DROP PROCEDURE IF EXISTS sp_calculate_gpa;
DELIMITER //
CREATE PROCEDURE sp_calculate_gpa(IN p_student_id INT, IN p_semester_id INT)
BEGIN
SELECT
    s.id AS student_id,
    s.student_no,
    s.name,
    ROUND(SUM(sc.score * sub.credit) / SUM(sub.credit), 2) AS weighted_avg_score,
    ROUND(SUM(gs.gpa * sub.credit) / SUM(sub.credit), 2) AS gpa
FROM students s
         LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
         LEFT JOIN subjects sub ON sc.subject_id = sub.id AND sub.is_deleted = 0
         LEFT JOIN grading_settings gs ON sub.id = gs.subject_id AND sc.semester_id = gs.semester_id
    AND sc.score >= gs.min_score AND sc.score <= gs.max_score
    AND gs.is_deleted = 0
WHERE s.id = p_student_id
  AND s.is_deleted = 0
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY s.id, s.student_no, s.name;
END //
DELIMITER ;

-- ============================================================
-- 存储过程：成绩四分位分析
-- 输入参数：subject_id（科目ID，可选）、semester_id（学期ID，可选）、department_id（系部ID，可选）
-- 返回：统计维度、最小值、第一四分位数、中位数、第三四分位数、最大值
-- ============================================================
DROP PROCEDURE IF EXISTS sp_score_quartile_analysis;
DELIMITER //
CREATE PROCEDURE sp_score_quartile_analysis(IN p_subject_id INT, IN p_semester_id INT, IN p_department_id INT)
BEGIN
SELECT
    sg.ntile_group,
    CONCAT('区间', sg.ntile_group) AS group_name,
    MIN(sg.score) AS min_score,
    MAX(sg.score) AS max_score,
    ROUND(AVG(sg.score), 2) AS avg_score,
    COUNT(*) AS count
FROM (
    SELECT
    sc.score,
    NTILE(5) OVER (ORDER BY sc.score) AS ntile_group
    FROM scores sc
    LEFT JOIN students s ON sc.student_id = s.id AND s.is_deleted = 0
    LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0
    LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
    WHERE sc.is_deleted = 0
    AND (p_subject_id IS NULL OR sc.subject_id = p_subject_id)
    AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
    AND (p_department_id IS NULL OR m.department_id = p_department_id)
    ) sg
GROUP BY sg.ntile_group
ORDER BY sg.ntile_group;
END //
DELIMITER ;

-- ============================================================
-- 窗口函数查询示例：学生成绩排名详情
-- 使用 RANK()、DENSE_RANK()、ROW_NUMBER() 三种排名方式
-- ============================================================
-- 查看某班级学生成绩排名（包含多种排名方式）
-- SELECT
--     s.id AS student_id,
--     s.student_no,
--     s.name,
--     c.class_name,
--     ROUND(AVG(sc.score), 2) AS avg_score,
--     RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS rank_with_gap,
--     DENSE_RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS dense_rank,
--     ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS row_num,
--     PERCENT_RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) * 100 AS percentile_in_class
-- FROM students s
-- LEFT JOIN classes c ON s.class_id = c.id
-- LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
-- WHERE s.is_deleted = 0 AND s.status = 1
-- GROUP BY s.id, s.student_no, s.name, c.class_name
-- ORDER BY c.id, avg_score DESC;

-- ============================================================
-- 窗口函数查询示例：成绩分布百分位
-- 使用 NTILE() 函数将成绩分为若干区间
-- ============================================================
-- 查看成绩分布（分为5个区间）
-- SELECT
--     ntile_group,
--     CONCAT('区间', ntile_group) AS group_name,
--     MIN(score) AS min_score,
--     MAX(score) AS max_score,
--     ROUND(AVG(score), 2) AS avg_score,
--     COUNT(*) AS count
-- FROM (
--     SELECT
--         sc.score,
--         NTILE(5) OVER (ORDER BY sc.score) AS ntile_group
--     FROM scores sc
--     WHERE sc.is_deleted = 0
-- ) AS score_groups
-- GROUP BY ntile_group
-- ORDER BY ntile_group;

-- ============================================================
-- 窗口函数查询示例：移动平均分析
-- 查看学生成绩趋势（使用移动平均）
-- ============================================================
-- SELECT
--     sc.student_id,
--     s.name,
--     sc.subject_id,
--     sub.subject_name,
--     sc.semester_id,
--     sem.semester_name,
--     sc.score,
--     AVG(sc.score) OVER (PARTITION BY sc.student_id ORDER BY sem.start_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
-- FROM scores sc
-- LEFT JOIN students s ON sc.student_id = s.id
-- LEFT JOIN subjects sub ON sc.subject_id = sub.id
-- LEFT JOIN semesters sem ON sc.semester_id = sem.id
-- WHERE sc.is_deleted = 0
-- ORDER BY sc.student_id, sem.start_date;

-- ============================================================
-- 存储过程：批量查询学生 GPA 统计（管理员端）
-- 输入参数：semester_id（学期ID，可选）、department_id（系部ID，可选）、major_id（专业ID，可选）、class_id（班级ID，可选）
-- 返回：学生ID、学号、姓名、班级、专业、系部、加权平均分、GPA、总学分、科目数
-- ============================================================
DROP PROCEDURE IF EXISTS sp_batch_gpa_stat;
DELIMITER //
CREATE PROCEDURE sp_batch_gpa_stat(
    IN p_semester_id INT,
    IN p_department_id INT,
    IN p_major_id INT,
    IN p_class_id INT
)
BEGIN
SELECT
    s.id AS student_id,
    s.student_no,
    s.name,
    c.class_name,
    m.major_name,
    d.dept_name AS department_name,
    ROUND(SUM(sc.score * sub.credit) / SUM(sub.credit), 2) AS weighted_avg_score,
    ROUND(SUM(gs.gpa * sub.credit) / SUM(sub.credit), 2) AS gpa,
    SUM(sub.credit) AS total_credits,
    COUNT(DISTINCT sc.subject_id) AS subject_count
FROM students s
         LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0
         LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
         LEFT JOIN departments d ON m.department_id = d.id AND d.is_deleted = 0
         LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
         LEFT JOIN subjects sub ON sc.subject_id = sub.id AND sub.is_deleted = 0
         LEFT JOIN grading_settings gs ON sub.id = gs.subject_id
    AND sc.semester_id = gs.semester_id
    AND sc.score >= gs.min_score
    AND sc.score <= gs.max_score
    AND gs.is_deleted = 0
WHERE s.is_deleted = 0
  AND s.status = 1
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
  AND (p_department_id IS NULL OR m.department_id = p_department_id)
  AND (p_major_id IS NULL OR c.major_id = p_major_id)
  AND (p_class_id IS NULL OR s.class_id = p_class_id)
GROUP BY s.id, s.student_no, s.name, c.class_name, m.major_name, d.dept_name
HAVING total_credits > 0
ORDER BY gpa DESC;
END //
DELIMITER ;

-- ============================================================
-- 存储过程执行示例
-- ============================================================
-- CALL sp_stat_by_department(NULL);
-- CALL sp_stat_by_major(1, NULL);
-- CALL sp_stat_by_class(1, NULL, NULL);    -- 第三个参数 department_id 为 NULL 时返回全部系部
-- CALL sp_stat_by_class(1, NULL, 1);       -- department_id=1 时只返回系部ID=1的数据
-- CALL sp_stat_by_subject(1, 1);
-- CALL sp_student_ranking(NULL, 1, NULL, NULL);   -- 4 个参数：class_id, semester_id, department_id, major_id
-- CALL sp_score_grade_distribution(1, NULL);    -- 第二个参数 department_id 为 NULL 时返回全部系部
-- CALL sp_score_grade_distribution(NULL, 1);    -- 筛选系部ID=1的数据
-- CALL sp_calculate_gpa(1, 1);
-- CALL sp_score_quartile_analysis(NULL, 1, NULL);  -- 第三个参数 department_id 为 NULL 时返回全部系部
-- CALL sp_score_quartile_analysis(NULL, NULL, 1);  -- 筛选系部ID=1的数据
-- CALL sp_batch_gpa_stat(NULL, NULL, NULL, NULL);    -- 全校学生 GPA
-- CALL sp_batch_gpa_stat(NULL, 1, NULL, NULL);       -- 系部ID=1 的学生 GPA
-- CALL sp_batch_gpa_stat(1, NULL, NULL, NULL);       -- 学期ID=1 的学生 GPA
