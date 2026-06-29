# 统计分析功能设计文档

## 一、任务概述
1. **存储过程**：封装按系部/专业/班级分类汇总统计的逻辑
2. **窗口函数**：实现成绩排名、分布（如名次、percentile）等分析功能
3. **SQL脚本**：编写统计相关的存储过程和窗口函数查询

---

## 二、存储过程设计

### 2.1 设计原则

1. **参数化设计**：所有存储过程都支持可选参数，不传则统计全部数据
2. **层级统计**：支持按系部→专业→班级的层级进行统计
3. **逻辑删除过滤**：所有查询都包含 `is_deleted = 0` 条件
4. **数据完整性**：使用 LEFT JOIN 确保即使没有成绩数据也能返回结构

### 2.2 存储过程清单

| 存储过程名 | 功能描述 | 参数 | 返回字段 |
|-----------|---------|------|----------|
| `sp_stat_by_department` | 按系部统计 | `semester_id`(可选) | dept_name, student_count, avg_score, max_score, min_score, failed_count, excellent_count, failed_rate |
| `sp_stat_by_major` | 按专业统计 | `semester_id`(可选), `department_id`(可选) | major_name, department_name, student_count, avg_score, max_score, min_score, failed_count, excellent_rate |
| `sp_stat_by_class` | 按班级统计 | `semester_id`(可选), `major_id`(可选) | class_name, major_name, student_count, avg_score, max_score, min_score, failed_count, passed_count, pass_rate |
| `sp_stat_by_subject` | 按科目统计 | `semester_id`(可选), `department_id`(可选) | subject_name, credit, score_count, avg_score, max_score, min_score, std_dev, failed_count, pass_rate |
| `sp_student_ranking` | 学生成绩排名 | `class_id`(可选), `semester_id`(可选) | student_no, name, class_name, total_score, avg_score, class_rank, school_rank, percentile_rank |
| `sp_score_grade_distribution` | 成绩等级分布 | `semester_id`(可选) | grade, count, percentage |
| `sp_calculate_gpa` | 计算学生GPA | `student_id`, `semester_id`(可选) | student_no, name, weighted_avg_score, gpa |
| `sp_score_quartile_analysis` | 成绩四分位分析 | `subject_id`(可选), `semester_id`(可选) | dimension, min_score, q1_score, median_score, q3_score, max_score, total_count |

### 2.3 核心存储过程设计详解

#### 2.3.1 按系部统计 (`sp_stat_by_department`)

**设计思路**：
- 通过多表 LEFT JOIN 关联 departments → majors → classes → students → scores
- 使用 `COUNT(DISTINCT s.id)` 统计学生总数（避免重复计数）
- 使用 `AVG()`, `MAX()`, `MIN()` 聚合函数计算成绩统计值
- 使用 `CASE WHEN` 实现条件计数（不及格人数、优秀人数）
- 计算不及格率：`SUM(不及格人数) / COUNT(总人数) * 100`

**SQL实现**：
```sql
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
```

#### 2.3.2 学生成绩排名 (`sp_student_ranking`)

**设计思路**：
- 使用 `RANK()` 窗口函数实现班级内和全校排名
- 使用 `PERCENT_RANK()` 计算百分位排名
- 使用 `PARTITION BY c.id` 按班级分组排名
- 使用 `ORDER BY AVG(sc.score) DESC` 按平均分降序排列

**SQL实现**：
```sql
SELECT
    s.id AS student_id,
    s.student_no,
    s.name,
    c.class_name,
    m.major_name,
    SUM(sc.score) AS total_score,
    ROUND(AVG(sc.score), 2) AS avg_score,
    COUNT(sc.id) AS subject_count,
    RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS class_rank,
    RANK() OVER (ORDER BY AVG(sc.score) DESC) AS school_rank,
    PERCENT_RANK() OVER (ORDER BY AVG(sc.score) DESC) * 100 AS percentile_rank
FROM students s
LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0
LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0
LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
WHERE s.is_deleted = 0 AND s.status = 1
  AND (p_class_id IS NULL OR s.class_id = p_class_id)
  AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
GROUP BY s.id, s.student_no, s.name, c.class_name, m.major_name
ORDER BY avg_score DESC;
```

---

## 三、窗口函数设计

### 3.1 窗口函数类型

| 函数类型 | 函数名 | 用途 |
|---------|--------|------|
| **排名函数** | `RANK()` | 带间隔排名（并列时跳过名次） |
| | `DENSE_RANK()` | 紧密排名（并列时不跳过名次） |
| | `ROW_NUMBER()` | 行号（无并列） |
| **分布函数** | `PERCENT_RANK()` | 百分位排名（0-1） |
| | `NTILE(n)` | 将数据分为n个桶 |
| **聚合函数** | `AVG() OVER()` | 移动平均 |
| | `SUM() OVER()` | 累积求和 |

### 3.2 窗口函数应用场景

#### 3.2.1 成绩排名对比

**需求**：同时展示三种排名方式，便于对比分析

**SQL实现**：
```sql
SELECT
    s.id AS student_id,
    s.student_no,
    s.name,
    c.class_name,
    ROUND(AVG(sc.score), 2) AS avg_score,
    RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS rank_with_gap,
    DENSE_RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) AS row_num,
    PERCENT_RANK() OVER (PARTITION BY c.id ORDER BY AVG(sc.score) DESC) * 100 AS percentile_in_class
FROM students s
LEFT JOIN classes c ON s.class_id = c.id
LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0
WHERE s.is_deleted = 0 AND s.status = 1
GROUP BY s.id, s.student_no, s.name, c.class_name
ORDER BY c.id, avg_score DESC;
```

**三种排名方式对比**：

| 学生 | 平均分 | RANK() | DENSE_RANK() | ROW_NUMBER() |
|------|--------|--------|--------------|--------------|
| 张三 | 95 | 1 | 1 | 1 |
| 李四 | 95 | 1 | 1 | 2 |
| 王五 | 90 | 3 | 2 | 3 |
| 赵六 | 85 | 4 | 3 | 4 |

#### 3.2.2 成绩分布分析（五分位）

**需求**：将成绩分为5个区间，分析成绩分布

**SQL实现**：
```sql
SELECT
    ntile_group,
    CONCAT('区间', ntile_group) AS group_name,
    MIN(score) AS min_score,
    MAX(score) AS max_score,
    ROUND(AVG(score), 2) AS avg_score,
    COUNT(*) AS count
FROM (
    SELECT
        sc.score,
        NTILE(5) OVER (ORDER BY sc.score) AS ntile_group
    FROM scores sc
    WHERE sc.is_deleted = 0
) AS score_groups
GROUP BY ntile_group
ORDER BY ntile_group;
```

#### 3.2.3 四分位分析

**需求**：计算成绩的四分位数，用于异常值检测

**SQL实现**：
```sql
WITH score_stats AS (
    SELECT
        sc.score,
        PERCENT_RANK() OVER (ORDER BY sc.score) AS percentile
    FROM scores sc
    WHERE sc.is_deleted = 0
      AND (p_subject_id IS NULL OR sc.subject_id = p_subject_id)
      AND (p_semester_id IS NULL OR sc.semester_id = p_semester_id)
)
SELECT
    CASE WHEN p_subject_id IS NOT NULL THEN (SELECT subject_name FROM subjects WHERE id = p_subject_id) ELSE '全校' END AS dimension,
    MIN(score) AS min_score,
    ROUND(AVG(CASE WHEN percentile <= 0.25 THEN score END), 2) AS q1_score,
    ROUND(AVG(CASE WHEN percentile <= 0.5 AND percentile > 0.25 THEN score END), 2) AS median_score,
    ROUND(AVG(CASE WHEN percentile <= 0.75 AND percentile > 0.5 THEN score END), 2) AS q3_score,
    MAX(score) AS max_score,
    COUNT(*) AS total_count
FROM score_stats;
```

---

## 四、Java服务层设计

### 4.1 StatisticsService 类

**职责**：封装存储过程调用和窗口函数查询

**方法清单**：

| 方法名 | 功能 | 参数 | 返回值 |
|--------|------|------|--------|
| `getDepartmentStatistics` | 按系部统计 | `semesterId` | `List<Map<String, Object>>` |
| `getMajorStatistics` | 按专业统计 | `semesterId`, `departmentId` | `List<Map<String, Object>>` |
| `getClassStatistics` | 按班级统计 | `semesterId`, `majorId` | `List<Map<String, Object>>` |
| `getSubjectStatistics` | 按科目统计 | `semesterId`, `departmentId` | `List<Map<String, Object>>` |
| `getStudentRanking` | 学生排名 | `classId`, `semesterId` | `List<Map<String, Object>>` |
| `getGradeDistribution` | 等级分布 | `semesterId` | `List<Map<String, Object>>` |
| `calculateGPA` | 计算GPA | `studentId`, `semesterId` | `List<Map<String, Object>>` |
| `getQuartileAnalysis` | 四分位分析 | `subjectId`, `semesterId` | `List<Map<String, Object>>` |
| `getStudentScoreRanking` | 详细排名（窗口函数） | `classId`, `semesterId` | `List<Map<String, Object>>` |
| `getScoreDistribution` | 成绩分布（NTILE） | `semesterId` | `List<Map<String, Object>>` |

### 4.2 StatisticsServlet 类

**职责**：提供 RESTful API 接口

**API端点**：

| 端点 | HTTP方法 | 功能 | 参数 |
|------|---------|------|------|
| `/statistics/department` | GET | 系部统计 | `semesterId`(可选) |
| `/statistics/major` | GET | 专业统计 | `semesterId`(可选), `departmentId`(可选) |
| `/statistics/class` | GET | 班级统计 | `semesterId`(可选), `majorId`(可选) |
| `/statistics/subject` | GET | 科目统计 | `semesterId`(可选), `departmentId`(可选) |
| `/statistics/ranking` | GET | 学生排名 | `classId`(可选), `semesterId`(可选) |
| `/statistics/grade-distribution` | GET | 等级分布 | `semesterId`(可选) |
| `/statistics/gpa` | GET | 计算GPA | `studentId`, `semesterId`(可选) |
| `/statistics/quartile` | GET | 四分位分析 | `subjectId`(可选), `semesterId`(可选) |
| `/statistics/score-distribution` | GET | 成绩分布 | `semesterId`(可选) |
| `/statistics/detailed-ranking` | GET | 详细排名 | `classId`(可选), `semesterId`(可选) |

---

## 五、性能优化策略

### 5.1 索引优化建议

| 表名 | 索引字段 | 索引类型 | 优化场景 |
|------|----------|----------|----------|
| scores | `student_id + semester_id` | 联合索引 | 学生按学期查询成绩 |
| scores | `subject_id + semester_id` | 联合索引 | 按科目学期统计 |
| scores | `score` | 普通索引 | 按分数范围查询 |
| students | `class_id` | 普通索引 | 按班级查询学生 |
| students | `status + is_deleted` | 联合索引 | 筛选在读学生 |

### 5.2 存储过程优化策略

1. **参数化查询**：使用预编译语句，避免SQL注入
2. **条件短路**：将 `IS NULL` 检查放在前面，减少不必要的表扫描
3. **LEFT JOIN 优化**：只在必要时使用 LEFT JOIN，优先使用 INNER JOIN
4. **避免 SELECT ***：只选择需要的字段，减少数据传输量
5. **GROUP BY 优化**：确保 GROUP BY 字段有索引

### 5.3 窗口函数优化策略

1. **合理使用 PARTITION BY**：分区字段应选择基数适中的列
2. **避免过度分区**：分区过多会降低性能
3. **排序优化**：确保 ORDER BY 字段有索引
4. **CTE 优化**：使用 CTE 简化复杂查询，提高可读性

---

## 六、文件结构

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── score/
│   │           ├── controller/
│   │           │   └── StatisticsServlet.java    # 统计API控制器
│   │           └── service/
│   │               └── StatisticsService.java    # 统计服务层
│   └── webapp/
└── docs/
    ├── statistics_procedures.sql                 # 存储过程脚本
    └── statistics_design.md                      # 设计文档（本文档）
```

---

## 七、使用示例

### 7.1 存储过程调用

```sql
-- 按系部统计当前学期成绩
CALL sp_stat_by_department(1);

-- 按专业统计（指定系部）
CALL sp_stat_by_major(1, 1);

-- 学生成绩排名（全校）
CALL sp_student_ranking(NULL, 1);

-- 成绩等级分布
CALL sp_score_grade_distribution(1);

-- 计算学生GPA
CALL sp_calculate_gpa(1, 1);

-- 四分位分析
CALL sp_score_quartile_analysis(NULL, 1);
```

### 7.2 API调用示例

```bash
# 系部统计
GET /statistics/department?semesterId=1

# 专业统计（指定系部）
GET /statistics/major?semesterId=1&departmentId=1

# 学生排名
GET /statistics/ranking?classId=1&semesterId=1

# 等级分布
GET /statistics/grade-distribution?semesterId=1

# 计算GPA
GET /statistics/gpa?studentId=1&semesterId=1
```

---

## 八、设计亮点

1. **参数化设计**：所有接口都支持可选参数，灵活适应不同统计需求
2. **多层级统计**：支持系部→专业→班级的层级统计，满足不同管理需求
3. **窗口函数应用**：使用 RANK()、DENSE_RANK()、PERCENT_RANK()、NTILE() 等窗口函数实现复杂分析
4. **数据完整性**：使用 LEFT JOIN 确保即使没有成绩数据也能返回结构
5. **性能优化**：合理使用索引和查询优化策略
6. **RESTful API**：提供标准化的 API 接口，便于前端调用
