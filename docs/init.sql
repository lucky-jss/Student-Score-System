-- ============================================================
-- score-system 数据库初始化脚本
-- 数据库：score_system
-- 字符集：UTF8MB4
-- 存储引擎：InnoDB
-- ============================================================

CREATE DATABASE IF NOT EXISTS score_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE score_system;

-- ============================================================
-- 1. departments（系部表）
-- ============================================================
DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
                             id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                             dept_code VARCHAR(20) NOT NULL COMMENT '系部编码，如 CS',
                             dept_name VARCHAR(100) NOT NULL COMMENT '系部名称',
                             description VARCHAR(255) DEFAULT NULL COMMENT '系部描述',
                             is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                             created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                             updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                             UNIQUE KEY uk_dept_code (dept_code),
                             KEY idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系部表';

-- ============================================================
-- 2. majors（专业表）
-- ============================================================
DROP TABLE IF EXISTS majors;
CREATE TABLE majors (
                        id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                        major_code VARCHAR(20) NOT NULL COMMENT '专业编码，如 CSSE',
                        major_name VARCHAR(100) NOT NULL COMMENT '专业名称',
                        department_id INT NOT NULL COMMENT '所属系部ID',
                        description VARCHAR(255) DEFAULT NULL COMMENT '专业描述',
                        is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                        UNIQUE KEY uk_major_code (major_code),
                        KEY idx_department_id (department_id),
                        KEY idx_is_deleted (is_deleted),
                        CONSTRAINT fk_majors_department FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='专业表';

-- ============================================================
-- 3. classes（班级表）
-- ============================================================
DROP TABLE IF EXISTS classes;
CREATE TABLE classes (
                         id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                         class_code VARCHAR(20) NOT NULL COMMENT '班级编码，如 CSSE202301',
                         class_name VARCHAR(100) NOT NULL COMMENT '班级名称',
                         major_id INT NOT NULL COMMENT '所属专业ID',
                         enrollment_year INT NOT NULL COMMENT '入学年份，如 2023',
                         is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                         created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                         updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                         UNIQUE KEY uk_class_code (class_code),
                         KEY idx_major_id (major_id),
                         KEY idx_enrollment_year (enrollment_year),
                         KEY idx_is_deleted (is_deleted),
                         CONSTRAINT fk_classes_major FOREIGN KEY (major_id) REFERENCES majors(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='班级表';

-- ============================================================
-- 4. semesters（学期表）
-- ============================================================
DROP TABLE IF EXISTS semesters;
CREATE TABLE semesters (
                           id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                           semester_name VARCHAR(50) NOT NULL COMMENT '学期名称，如 2023-2024学年第一学期',
                           start_date DATE NOT NULL COMMENT '开始日期',
                           end_date DATE NOT NULL COMMENT '结束日期',
                           is_current TINYINT NOT NULL DEFAULT 0 COMMENT '是否当前学期：0=否，1=是',
                           is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                           created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                           updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                           UNIQUE KEY uk_semester_name (semester_name),
                           KEY idx_is_current (is_current),
                           KEY idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学期表';

-- ============================================================
-- 5. subjects（科目表）
-- ============================================================
DROP TABLE IF EXISTS subjects;
CREATE TABLE subjects (
                          id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                          subject_code VARCHAR(20) NOT NULL COMMENT '科目编码，如 CS101',
                          subject_name VARCHAR(100) NOT NULL COMMENT '科目名称',
                          credit DECIMAL(3,1) NOT NULL COMMENT '学分',
                          department_id INT NOT NULL COMMENT '开课系部ID',
                          is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                          updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                          UNIQUE KEY uk_subject_code (subject_code),
                          KEY idx_department_id (department_id),
                          KEY idx_is_deleted (is_deleted),
                          CONSTRAINT fk_subjects_department FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='科目表';

-- ============================================================
-- 6. students（学生表）
-- ============================================================
DROP TABLE IF EXISTS students;
CREATE TABLE students (
                          id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                          student_no VARCHAR(20) NOT NULL COMMENT '学号，如 2023001001',
                          name VARCHAR(50) NOT NULL COMMENT '姓名',
                          class_id INT NOT NULL COMMENT '所属班级ID',
                          password_hash VARCHAR(255) NOT NULL COMMENT 'BCrypt 加密后的密码',
                          gender ENUM('男','女') NOT NULL COMMENT '性别',
                          birth_date DATE DEFAULT NULL COMMENT '出生日期',
                          phone VARCHAR(20) DEFAULT NULL COMMENT '联系电话',
                          email VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
                          status TINYINT NOT NULL DEFAULT 1 COMMENT '学籍状态：0=退学，1=在读，2=休学，3=毕业',
                          is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                          updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                          UNIQUE KEY uk_student_no (student_no),
                          KEY idx_class_id (class_id),
                          KEY idx_status (status),
                          KEY idx_is_deleted (is_deleted),
                          CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学生表';

-- ============================================================
-- 7. users（系统用户表）
-- ============================================================
DROP TABLE IF EXISTS users;
CREATE TABLE users (
                       id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                       username VARCHAR(50) NOT NULL COMMENT '用户名',
                       password_hash VARCHAR(255) NOT NULL COMMENT 'BCrypt 加密后的密码',
                       real_name VARCHAR(50) NOT NULL COMMENT '真实姓名',
                       role ENUM('admin','teacher') NOT NULL COMMENT '角色：admin=管理员，teacher=教师',
                       department_id INT DEFAULT NULL COMMENT '所属系部ID，管理员可为空',
                       status TINYINT NOT NULL DEFAULT 1 COMMENT '账号状态：0=禁用，1=正常',
                       last_login_at DATETIME DEFAULT NULL COMMENT '最后登录时间',
                       is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                       created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                       updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                       UNIQUE KEY uk_username (username),
                       KEY idx_department_id (department_id),
                       KEY idx_role (role),
                       KEY idx_status (status),
                       KEY idx_is_deleted (is_deleted),
                       CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统用户表';

-- ============================================================
-- 8. scores（成绩表）—— 核心业务表
-- ============================================================
DROP TABLE IF EXISTS scores;
CREATE TABLE scores (
                        id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                        student_id INT NOT NULL COMMENT '学生ID',
                        subject_id INT NOT NULL COMMENT '科目ID',
                        semester_id INT NOT NULL COMMENT '学期ID',
                        score DECIMAL(5,2) NOT NULL COMMENT '成绩分数',
                        grade VARCHAR(5) DEFAULT NULL COMMENT '等级，如 A、B+',
                        recorded_by INT NOT NULL COMMENT '录入人ID',
                        recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '录入时间',
                        is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                        UNIQUE KEY uk_score_record (student_id, subject_id, semester_id),
                        KEY idx_student_id (student_id),
                        KEY idx_subject_id (subject_id),
                        KEY idx_semester_id (semester_id),
                        KEY idx_recorded_by (recorded_by),
                        KEY idx_is_deleted (is_deleted),
                        KEY idx_score (score),
                        CONSTRAINT fk_scores_student FOREIGN KEY (student_id) REFERENCES students(id),
                        CONSTRAINT fk_scores_subject FOREIGN KEY (subject_id) REFERENCES subjects(id),
                        CONSTRAINT fk_scores_semester FOREIGN KEY (semester_id) REFERENCES semesters(id),
                        CONSTRAINT fk_scores_recorded_by FOREIGN KEY (recorded_by) REFERENCES users(id),
                        CONSTRAINT chk_score_range CHECK (score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='成绩表';

-- ============================================================
-- 9. grading_settings（等级分值设置表）
-- ============================================================
DROP TABLE IF EXISTS grading_settings;
CREATE TABLE grading_settings (
                                  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                                  subject_id INT NOT NULL COMMENT '科目ID',
                                  semester_id INT NOT NULL COMMENT '学期ID',
                                  grade VARCHAR(5) NOT NULL COMMENT '等级，如 A',
                                  min_score DECIMAL(5,2) NOT NULL COMMENT '最低分',
                                  max_score DECIMAL(5,2) NOT NULL COMMENT '最高分',
                                  gpa DECIMAL(3,2) NOT NULL COMMENT '绩点',
                                  is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常，1=已删除',
                                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                                  UNIQUE KEY uk_grading_setting (subject_id, semester_id, grade),
                                  KEY idx_subject_id (subject_id),
                                  KEY idx_semester_id (semester_id),
                                  KEY idx_is_deleted (is_deleted),
                                  CONSTRAINT fk_grading_subject FOREIGN KEY (subject_id) REFERENCES subjects(id),
                                  CONSTRAINT fk_grading_semester FOREIGN KEY (semester_id) REFERENCES semesters(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='等级分值设置表';

-- ============================================================
-- 10. audit_log（审计日志表）
-- ============================================================
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
                           id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
                           user_id INT NOT NULL COMMENT '操作用户ID',
                           action VARCHAR(20) NOT NULL COMMENT '操作类型：INSERT/UPDATE/DELETE',
                           table_name VARCHAR(50) NOT NULL COMMENT '操作表名',
                           record_id INT NOT NULL COMMENT '记录ID',
                           old_data TEXT DEFAULT NULL COMMENT '旧值（JSON格式）',
                           new_data TEXT DEFAULT NULL COMMENT '新值（JSON格式）',
                           ip_address VARCHAR(45) DEFAULT NULL COMMENT 'IP地址',
                           created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
                           KEY idx_user_id (user_id),
                           KEY idx_table_record (table_name, record_id),
                           KEY idx_action (action),
                           KEY idx_created_at (created_at),
                           CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审计日志表';

-- ============================================================
-- 初始化数据
-- ============================================================

-- 系部数据
INSERT INTO departments (dept_code, dept_name, description) VALUES
                                                                ('CS', '计算机科学与技术系', '计算机、软件工程、人工智能等方向'),
                                                                ('EE', '电子工程系', '电子信息、通信工程等方向'),
                                                                ('ME', '机械工程系', '机械设计、自动化等方向');

-- 专业数据
INSERT INTO majors (major_code, major_name, department_id, description) VALUES
                                                                            ('CSSE', '软件工程', 1, '培养软件开发人才'),
                                                                            ('EECE', '电子信息工程', 2, '培养电子信息人才'),
                                                                            ('MEMD', '机械设计制造及其自动化', 3, '培养机械设计人才');

-- 班级数据
INSERT INTO classes (class_code, class_name, major_id, enrollment_year) VALUES
                                                                            ('CSSE202301', '软件工程2023级1班', 1, 2023),
                                                                            ('CSSE202302', '软件工程2023级2班', 1, 2023),
                                                                            ('EECE202301', '电子信息工程2023级1班', 2, 2023),
                                                                            ('MEMD202301', '机械设计2023级1班', 3, 2023);

-- 学期数据
INSERT INTO semesters (semester_name, start_date, end_date, is_current) VALUES
                                                                            ('2023-2024学年第一学期', '2023-09-01', '2024-01-15', 0),
                                                                            ('2023-2024学年第二学期', '2024-02-20', '2024-07-05', 1);

-- 科目数据
INSERT INTO subjects (subject_code, subject_name, credit, department_id) VALUES
                                                                             ('CS101', '数据结构', 4.0, 1),
                                                                             ('CS102', 'Java程序设计', 3.5, 1),
                                                                             ('EE101', '电路原理', 4.0, 2),
                                                                             ('ME101', '机械制图', 3.0, 3);

-- 学生数据（密码明文均为 123456，BCrypt 哈希值）
-- $2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq 为示例哈希，实际请用 jBCrypt 生成
INSERT INTO students (student_no, name, class_id, password_hash, gender, birth_date, phone, email, status) VALUES
                                                                                                               ('2023001001', '张三', 1, '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '男', '2004-03-15', '13800138001', 'zhangsan@example.com', 1),
                                                                                                               ('2023001002', '李四', 1, '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '女', '2004-06-20', '13800138002', 'lisi@example.com', 1),
                                                                                                               ('2023001003', '王五', 2, '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '男', '2003-11-08', '13800138003', 'wangwu@example.com', 1),
                                                                                                               ('2023001004', '赵六', 3, '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '女', '2004-01-25', '13800138004', 'zhaoliu@example.com', 1);

-- 系统用户数据（密码明文均为 123456）
INSERT INTO users (username, password_hash, real_name, role, department_id, status) VALUES
                                                                                        ('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '系统管理员', 'admin', NULL, 1),
                                                                                        ('zhang_teacher', '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '张老师', 'teacher', 1, 1),
                                                                                        ('li_teacher', '$2a$10$N9qo8uLOickgx2ZMRZoMy.Mqrq7d0VqK3jZfX3y8vQqQqQqQqQqQq', '李老师', 'teacher', 2, 1);

-- 成绩数据
INSERT INTO scores (student_id, subject_id, semester_id, score, grade, recorded_by) VALUES
                                                                                        (1, 1, 1, 85.50, 'B+', 2),
                                                                                        (1, 2, 1, 92.00, 'A', 2),
                                                                                        (2, 1, 1, 78.00, 'B', 2),
                                                                                        (2, 2, 1, 88.50, 'B+', 2),
                                                                                        (3, 1, 1, 65.00, 'C', 2),
                                                                                        (3, 2, 2, 72.00, 'B-', 2),
                                                                                        (4, 3, 1, 90.00, 'A-', 3);