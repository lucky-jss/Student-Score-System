-- =========================================
-- C模块：成绩表索引优化
-- =========================================

-- 1. 学生 + 学期联合索引
-- 用于：学生查询某学期所有成绩
CREATE INDEX idx_student_semester
ON scores(student_id, semester_id);

-- 2. 课程 + 学期联合索引
-- 用于：教师查询某课程某学期成绩
CREATE INDEX idx_subject_semester
ON scores(subject_id, semester_id);
-- =========================================
-- EXPLAIN性能验证（用于实验报告）
-- =========================================

EXPLAIN
SELECT *
FROM scores
WHERE student_id = 1 AND semester_id = 1;

EXPLAIN
SELECT *
FROM scores
WHERE subject_id = 1 AND semester_id = 1;