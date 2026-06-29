package com.score.dao;

import java.sql.*;
import java.util.*;
import com.score.model.Student;
import com.score.model.Subject;
import com.score.model.Semester;
import com.score.util.PageResult;

/**
 * 数据库连接与操作封装类。
 * 提供数据库连接获取、事务控制、通用增删改查、存储过程调用等功能。
 * 使用 ThreadLocal 管理连接，支持同一线程内的事务操作。
 *
 * @author A同学（组长）
 */
public class DB {

    // ==================== 数据库连接配置 ====================
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";
    private static final String URL = "jdbc:mysql://localhost:3306/score_system"
            + "?useSSL=false"
            + "&serverTimezone=UTC"
            + "&characterEncoding=UTF-8"
            + "&allowPublicKeyRetrieval=true";
    private static final String USERNAME = "root";
    // ⚠️ 请修改为实际密码
    private static final String PASSWORD = "20061127Lw";

    // 使用 ThreadLocal 保证每个线程拥有独立的数据库连接
    private static final ThreadLocal<Connection> CONNECTION_HOLDER = new ThreadLocal<>();

    static {
        try {
            Class.forName(DRIVER);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL 驱动加载失败", e);
        }
    }

    /**
     * 获取数据库连接。
     * 如果当前线程已持有连接，则直接返回；否则创建新连接。
     *
     * @return 数据库连接
     * @throws SQLException 获取连接失败时抛出
     */
    public static Connection getConnection() throws SQLException {
        Connection conn = CONNECTION_HOLDER.get();
        if (conn == null || conn.isClosed()) {
            conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);
            CONNECTION_HOLDER.set(conn);
        }
        return conn;
    }

    /**
     * 开启事务。
     * 将当前连接的自动提交设置为 false。
     *
     * @throws SQLException 操作失败时抛出
     */
    @SuppressWarnings("unused")
    public static void beginTransaction() throws SQLException {
        Connection conn = getConnection();
        conn.setAutoCommit(false);
    }

    /**
     * 提交事务。
     *
     * @throws SQLException 操作失败时抛出
     */
    @SuppressWarnings("unused")
    public static void commitTransaction() throws SQLException {
        Connection conn = CONNECTION_HOLDER.get();
        if (conn != null) {
            conn.commit();
            conn.setAutoCommit(true);
        }
    }

    /**
     * 回滚事务。
     *
     * @throws SQLException 操作失败时抛出
     */
    @SuppressWarnings("unused")
    public static void rollbackTransaction() throws SQLException {
        Connection conn = CONNECTION_HOLDER.get();
        if (conn != null) {
            conn.rollback();
            conn.setAutoCommit(true);
        }
    }

    /**
     * 关闭当前线程持有的数据库连接，并从 ThreadLocal 中移除。
     *
     * @throws SQLException 关闭失败时抛出
     */
    public static void closeConnection() throws SQLException {
        Connection conn = CONNECTION_HOLDER.get();
        if (conn != null) {
            conn.close();
            CONNECTION_HOLDER.remove();
        }
    }

    /**
     * 执行增删改操作（INSERT / UPDATE / DELETE）。
     *
     * @param sql    SQL 语句，支持 ? 占位符
     * @param params 参数列表
     * @return 受影响的行数
     * @throws SQLException 执行失败时抛出
     */
    public static int executeUpdate(String sql, Object... params) throws SQLException {
        Connection conn = getConnection();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setParameters(ps, params);
            return ps.executeUpdate();
        }
    }

    /**
     * 执行插入操作，返回自增主键ID。
     *
     * @param sql    INSERT SQL 语句，支持 ? 占位符
     * @param params 参数列表
     * @return 自增主键ID
     * @throws SQLException 执行失败时抛出
     */
    public static int executeInsert(String sql, Object... params) throws SQLException {
        Connection conn = getConnection();
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            setParameters(ps, params);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return -1;
    }

    /**
     * 执行查询操作，返回 List&lt;Map&lt;String, Object&gt;&gt; 结果集。
     *
     * @param sql    SQL 语句，支持 ? 占位符
     * @param params 参数列表
     * @return 查询结果列表，每条记录为一个 Map（key=列名，value=值）
     * @throws SQLException 执行失败时抛出
     */
    public static List<Map<String, Object>> executeQuery(String sql, Object... params) throws SQLException {
        Connection conn = getConnection();
        List<Map<String, Object>> result = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setParameters(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData meta = rs.getMetaData();
                int columnCount = meta.getColumnCount();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        row.put(meta.getColumnLabel(i), rs.getObject(i));
                    }
                    result.add(row);
                }
            }
        }
        return result;
    }

    /**
     * 调用无返回结果集的存储过程。
     *
     * @param sql    存储过程调用语句，如 "{call sp_name(?,?)}"
     * @param params 参数列表
     * @throws SQLException 执行失败时抛出
     */
    public static void callProcedure(String sql, Object... params) throws SQLException {
        Connection conn = getConnection();
        try (CallableStatement cs = conn.prepareCall(sql)) {
            setParameters(cs, params);
            cs.execute();
        }
    }

    /**
     * 调用带返回结果集的存储过程。
     *
     * @param sql    存储过程调用语句
     * @param params 参数列表
     * @return 查询结果列表
     * @throws SQLException 执行失败时抛出
     */
    public static List<Map<String, Object>> callProcedureQuery(String sql, Object... params) throws SQLException {
        Connection conn = getConnection();
        List<Map<String, Object>> result = new ArrayList<>();
        try (CallableStatement cs = conn.prepareCall(sql)) {
            setParameters(cs, params);
            try (ResultSet rs = cs.executeQuery()) {
                ResultSetMetaData meta = rs.getMetaData();
                int columnCount = meta.getColumnCount();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        row.put(meta.getColumnLabel(i), rs.getObject(i));
                    }
                    result.add(row);
                }
            }
        }
        return result;
    }

    /**
     * 为 PreparedStatement / CallableStatement 设置参数。
     *
     * @param ps     预编译语句对象
     * @param params 参数数组
     * @throws SQLException 设置失败时抛出
     */
    private static void setParameters(PreparedStatement ps, Object... params) throws SQLException {
        if (params != null) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
        }
    }

    /**
     * 关闭数据库资源（ResultSet、Statement、Connection）。
     * 注意：Connection 通常由 ThreadLocal 管理，此方法用于特殊场景手动释放。
     *
     * @param rs   结果集
     * @param stmt 语句对象
     * @param conn 连接对象
     */
    public static void closeResources(ResultSet rs, Statement stmt, Connection conn) {
        try {
            if (rs != null) rs.close();
        } catch (SQLException ignored) {
        }
        try {
            if (stmt != null) stmt.close();
        } catch (SQLException ignored) {
        }
        try {
            if (conn != null) conn.close();
        } catch (SQLException ignored) {
        }
    }

    // ==================== 新增：按系部查询学生列表 ====================

    /**
     * 按系部查询所有在读学生列表。
     * 查询链：departments → majors → classes → students
     *
     * @param departmentId 系部ID
     * @return 学生列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Student> getStudentsByDepartment(int departmentId) throws SQLException {
        String sql =
                "SELECT s.id, s.student_no, s.name, s.class_id, s.password_hash, s.gender, " +
                        "       s.birth_date, s.phone, s.email, s.status, s.is_deleted, s.created_at, s.updated_at " +
                        "FROM students s " +
                        "JOIN classes c ON s.class_id = c.id " +
                        "JOIN majors m ON c.major_id = m.id " +
                        "WHERE m.department_id = ? " +
                        "  AND s.is_deleted = 0 " +
                        "  AND s.status = 1 " +
                        "  AND c.is_deleted = 0 " +
                        "  AND m.is_deleted = 0 " +
                        "ORDER BY s.name";

        List<Map<String, Object>> rows = executeQuery(sql, departmentId);
        List<Student> students = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            students.add(mapToStudent(row));
        }
        return students;
    }

    /**
     * 查询所有未删除的科目列表。
     *
     * @return 科目列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Subject> getSubjects() throws SQLException {
        String sql =
                "SELECT id, subject_code, subject_name, credit, department_id, " +
                        "       is_deleted, created_at, updated_at " +
                        "FROM subjects " +
                        "WHERE is_deleted = 0 " +
                        "ORDER BY subject_code";

        List<Map<String, Object>> rows = executeQuery(sql);
        List<Subject> subjects = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            subjects.add(mapToSubject(row));
        }
        return subjects;
    }

    /**
     * 查询所有未删除的学期列表。
     *
     * @return 学期列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Semester> getSemesters() throws SQLException {
        String sql =
                "SELECT id, semester_name, start_date, end_date, is_current, " +
                        "       is_deleted, created_at, updated_at " +
                        "FROM semesters " +
                        "WHERE is_deleted = 0 " +
                        "ORDER BY start_date DESC";

        List<Map<String, Object>> rows = executeQuery(sql);
        List<Semester> semesters = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            semesters.add(mapToSemester(row));
        }
        return semesters;
    }

    /**
     * 检查指定学生、科目、学期是否已有有效成绩记录。
     *
     * @param studentId  学生ID
     * @param subjectId  科目ID
     * @param semesterId 学期ID
     * @return true=已存在，false=不存在
     * @throws SQLException 查询失败时抛出
     */
    public static boolean isScoreExists(int studentId, int subjectId, int semesterId) throws SQLException {
        String sql =
                "SELECT 1 FROM scores " +
                        "WHERE student_id = ? AND subject_id = ? AND semester_id = ? AND is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql, studentId, subjectId, semesterId);
        return !rows.isEmpty();
    }

    // ==================== 私有：结果集映射工具方法 ====================

    private static Student mapToStudent(Map<String, Object> row) {
        Student s = new Student();
        s.setId((Integer) row.get("id"));
        s.setStudentNo((String) row.get("student_no"));
        s.setName((String) row.get("name"));
        s.setClassId((Integer) row.get("class_id"));
        s.setPasswordHash((String) row.get("password_hash"));
        s.setGender((String) row.get("gender"));
        if (row.get("birth_date") != null) {
            s.setBirthDate(((java.sql.Date) row.get("birth_date")).toLocalDate());
        }
        s.setPhone((String) row.get("phone"));
        s.setEmail((String) row.get("email"));
        s.setStatus((Integer) row.get("status"));
        s.setIsDeleted(row.get("is_deleted") != null && ((Number) row.get("is_deleted")).intValue() == 1);

        // 安全处理 created_at
        Object createdAt = row.get("created_at");
        if (createdAt instanceof java.sql.Timestamp) {
            s.setCreatedAt(((java.sql.Timestamp) createdAt).toLocalDateTime());
        } else if (createdAt instanceof java.time.LocalDateTime) {
            s.setCreatedAt((java.time.LocalDateTime) createdAt);
        } else {
            s.setCreatedAt(null);
        }

        // 安全处理 updated_at
        Object updatedAt = row.get("updated_at");
        if (updatedAt instanceof java.sql.Timestamp) {
            s.setUpdatedAt(((java.sql.Timestamp) updatedAt).toLocalDateTime());
        } else if (updatedAt instanceof java.time.LocalDateTime) {
            s.setUpdatedAt((java.time.LocalDateTime) updatedAt);
        } else {
            s.setUpdatedAt(null);
        }

        return s;
    }

    private static Subject mapToSubject(Map<String, Object> row) {
        Subject s = new Subject();
        s.setId((Integer) row.get("id"));
        s.setSubjectCode((String) row.get("subject_code"));
        s.setSubjectName((String) row.get("subject_name"));
        s.setCredit(row.get("credit") != null ? new java.math.BigDecimal(row.get("credit").toString()) : null);
        s.setDepartmentId((Integer) row.get("department_id"));
        s.setIsDeleted(row.get("is_deleted") != null && ((Number) row.get("is_deleted")).intValue() == 1);

        // 安全处理 created_at
        Object createdAt = row.get("created_at");
        if (createdAt instanceof java.sql.Timestamp) {
            s.setCreatedAt(((java.sql.Timestamp) createdAt).toLocalDateTime());
        } else if (createdAt instanceof java.time.LocalDateTime) {
            s.setCreatedAt((java.time.LocalDateTime) createdAt);
        } else {
            s.setCreatedAt(null);
        }

        // 安全处理 updated_at
        Object updatedAt = row.get("updated_at");
        if (updatedAt instanceof java.sql.Timestamp) {
            s.setUpdatedAt(((java.sql.Timestamp) updatedAt).toLocalDateTime());
        } else if (updatedAt instanceof java.time.LocalDateTime) {
            s.setUpdatedAt((java.time.LocalDateTime) updatedAt);
        } else {
            s.setUpdatedAt(null);
        }

        return s;
    }

    private static Semester mapToSemester(Map<String, Object> row) {
        Semester s = new Semester();
        s.setId((Integer) row.get("id"));
        s.setSemesterName((String) row.get("semester_name"));
        if (row.get("start_date") != null) {
            s.setStartDate(((java.sql.Date) row.get("start_date")).toLocalDate());
        }
        if (row.get("end_date") != null) {
            s.setEndDate(((java.sql.Date) row.get("end_date")).toLocalDate());
        }
        s.setIsCurrent(row.get("is_current") != null && ((Number) row.get("is_current")).intValue() == 1);
        s.setIsDeleted(row.get("is_deleted") != null && ((Number) row.get("is_deleted")).intValue() == 1);

        // 安全处理 created_at
        Object createdAt = row.get("created_at");
        if (createdAt instanceof java.sql.Timestamp) {
            s.setCreatedAt(((java.sql.Timestamp) createdAt).toLocalDateTime());
        } else if (createdAt instanceof java.time.LocalDateTime) {
            s.setCreatedAt((java.time.LocalDateTime) createdAt);
        } else {
            s.setCreatedAt(null);
        }

        // 安全处理 updated_at
        Object updatedAt = row.get("updated_at");
        if (updatedAt instanceof java.sql.Timestamp) {
            s.setUpdatedAt(((java.sql.Timestamp) updatedAt).toLocalDateTime());
        } else if (updatedAt instanceof java.time.LocalDateTime) {
            s.setUpdatedAt((java.time.LocalDateTime) updatedAt);
        } else {
            s.setUpdatedAt(null);
        }

        return s;
    }

    // ==================== 新增：学生成绩查询相关方法 ====================

    /**
     * 查询学生成绩列表（含学期内排名和全校排名），支持分页。
     * 🔄 当前使用普通SQL查询，待D同学创建 v_student_score_view 后可替换
     * 替换后查询方式：
     * SELECT * FROM v_student_score_view WHERE student_id = ? AND (semester_id = ? OR ? = -1)
     *
     * @param studentId  学生ID
     * @param semesterId 学期ID，-1 表示全部学期
     * @param page       当前页码（从1开始）
     * @param pageSize   每页条数
     * @return 分页结果对象
     * @throws SQLException 查询失败时抛出
     */
    public static PageResult<Map<String, Object>> getStudentScoresWithRank(
            int studentId, int semesterId, int page, int pageSize) throws SQLException {

        PageResult<Map<String, Object>> pageResult = new PageResult<>();
        pageResult.setCurrentPage(page);
        pageResult.setPageSize(pageSize);

        // 1. 查询总记录数
        String countSql =
                "SELECT COUNT(*) AS cnt FROM scores " +
                        "WHERE student_id = ? AND is_deleted = 0 AND (? = -1 OR semester_id = ?)";
        List<Map<String, Object>> countRows = executeQuery(countSql, studentId, semesterId, semesterId);
        long totalRecords = ((Number) countRows.get(0).get("cnt")).longValue();
        pageResult.setTotalRecords(totalRecords);

        // 计算总页数
        int totalPages = (int) ((totalRecords + pageSize - 1) / pageSize);
        if (totalPages == 0) totalPages = 1;
        pageResult.setTotalPages(totalPages);

        // 修正页码（防止超出范围）
        if (page < 1) page = 1;
        if (page > totalPages) page = totalPages;

        // 2. 查询带排名的成绩数据
        // 先对所有学生计算排名（窗口函数在内层无筛选），再在外层筛选当前学生
        int offset = (page - 1) * pageSize;

        String dataSql =
                "SELECT * FROM (" +
                        "  SELECT " +
                        "    sc.id, " +
                        "    sc.student_id, " +
                        "    sem.id AS semester_id, sem.semester_name, " +
                        "    sub.id AS subject_id, sub.subject_name, " +
                        "    sc.score, " +
                        "    sc.grade AS grade_level, " +
                        "    sc.recorded_at, " +
                        "    RANK() OVER (PARTITION BY c.enrollment_year, sc.subject_id, sc.semester_id ORDER BY sc.score DESC) AS grade_rank, " +
                        "    RANK() OVER (PARTITION BY s.class_id, sc.subject_id, sc.semester_id ORDER BY sc.score DESC) AS class_rank " +
                        "  FROM scores sc " +
                        "  JOIN students s ON sc.student_id = s.id " +
                        "  JOIN classes c ON s.class_id = c.id " +
                        "  JOIN subjects sub ON sc.subject_id = sub.id " +
                        "  JOIN semesters sem ON sc.semester_id = sem.id " +
                        "  WHERE sc.is_deleted = 0 " +
                        ") ranked " +
                        "WHERE ranked.student_id = ? " +
                        "  AND (? = -1 OR ranked.semester_id = ?) " +
                        "ORDER BY ranked.semester_id DESC, ranked.subject_name " +
                        "LIMIT ? OFFSET ?";

        List<Map<String, Object>> rows = executeQuery(dataSql, studentId, semesterId, semesterId, pageSize, offset);
        pageResult.setList(rows);

        return pageResult;
    }

    /**
     * 查询学生成绩列表（不分页，用于导出）。
     * 使用 v_student_my_score 视图简化多表 JOIN。
     *
     * @param studentId  学生ID
     * @param semesterId 学期ID，-1 表示全部学期
     * @return 成绩列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getStudentScoresForExport(
            int studentId, int semesterId) throws SQLException {

        String sql =
                "SELECT " +
                        "  学期 AS semester_name, " +
                        "  科目名称 AS subject_name, " +
                        "  分数 AS score, " +
                        "  等级 AS grade_level, " +
                        "  科目编号 AS subject_code, " +
                        "  学分 AS credit, " +
                        "  绩点 AS gpa " +
                        "FROM v_student_my_score " +
                        "WHERE 学号 = (SELECT student_no FROM students WHERE id = ? AND is_deleted = 0) " +
                        "  AND (? = -1 OR 学期 IN (SELECT semester_name FROM semesters WHERE id = ?))";

        return executeQuery(sql, studentId, semesterId, semesterId);
    }

    /**
     * 获取当前学期ID（is_current=1 的学期）。
     * 如果没有当前学期，返回 -1。
     *
     * @return 当前学期ID，无当前学期返回 -1
     * @throws SQLException 查询失败时抛出
     */
    public static int getCurrentSemesterId() throws SQLException {
        String sql = "SELECT id FROM semesters WHERE is_current = 1 AND is_deleted = 0 LIMIT 1";
        List<Map<String, Object>> rows = executeQuery(sql);
        if (rows.isEmpty()) {
            return -1;
        }
        return ((Number) rows.get(0).get("id")).intValue();
    }

    /**
     * 查询学生所在班级名称。
     *
     * @param classId 班级ID
     * @return 班级名称
     * @throws SQLException 查询失败时抛出
     */
    public static String getClassName(int classId) throws SQLException {
        String sql = "SELECT class_name FROM classes WHERE id = ? AND is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql, classId);
        if (rows.isEmpty()) {
            return "未知班级";
        }
        return (String) rows.get(0).get("class_name");
    }

    /**
     * 查询所有未删除的学期列表（返回 Map 格式，供下拉框使用）。
     *
     * @return 学期列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getSemestersRaw() throws SQLException {
        String sql =
                "SELECT id, semester_name, is_current " +
                        "FROM semesters " +
                        "WHERE is_deleted = 0 " +
                        "ORDER BY start_date DESC";
        return executeQuery(sql);
    }

    // ==================== 新增：成绩修改相关方法 ====================

    /**
     * 根据分数查询对应的等级。
     * 从 grading_settings 表中查找该分数所属的等级区间（min_score ≤ score ≤ max_score）。
     * 如果未找到匹配等级，返回 null。
     *
     * @param score 分数
     * @return 等级字符串（如 "A"、"B+"），未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static String getGradeLevel(double score) throws SQLException {
        String sql =
                "SELECT grade FROM grading_settings " +
                        "WHERE ? >= min_score AND ? <= max_score " +
                        "  AND is_deleted = 0 " +
                        "LIMIT 1";
        List<Map<String, Object>> rows = executeQuery(sql, score, score);
        if (!rows.isEmpty()) {
            return (String) rows.get(0).get("grade");
        }
        // Fallback：数据库无匹配时使用硬编码默认规则
        if (score >= 90) return "A";
        if (score >= 80) return "B";
        if (score >= 70) return "C";
        if (score >= 60) return "D";
        return "F";
    }

    /**
     * 查询指定成绩的完整信息（含学生姓名、科目名称、学期名称）。
     * 用于修改页面回显。
     *
     * @param scoreId 成绩ID
     * @return 成绩信息 Map，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static Map<String, Object> getScoreById(int scoreId) throws SQLException {
        String sql =
                "SELECT " +
                        "  sc.id AS score_id, sc.student_id, sc.subject_id, sc.semester_id, " +
                        "  sc.score, sc.grade AS grade_level, " +
                        "  st.name AS student_name, st.student_no, " +
                        "  sub.subject_name, " +
                        "  sem.semester_name " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "WHERE sc.id = ? AND sc.is_deleted = 0";

        List<Map<String, Object>> rows = executeQuery(sql, scoreId);
        if (rows.isEmpty()) {
            return null;
        }
        return rows.get(0);
    }

    /**
     * 更新成绩记录。
     * 注意：修改成功后，触发器 tr_scores_after_update 会自动记录审计日志到 audit_log 表，
     * 代码无需额外处理审计逻辑。
     *
     * @param scoreId    成绩ID
     * @param newScore   新分数
     * @param gradeLevel 新等级
     * @return true=成功，false=失败
     * @throws SQLException 更新失败时抛出
     */
    public static boolean updateScore(int scoreId, double newScore, String gradeLevel) throws SQLException {
        int rows = executeUpdate(
                "UPDATE scores SET score = ?, grade = ?, updated_at = NOW() WHERE id = ? AND is_deleted = 0",
                newScore, gradeLevel, scoreId
        );
        return rows > 0;
    }

    /**
     * 查询当前教师录入的成绩列表。
     * 支持按学生筛选，默认显示最近录入的 20 条。
     *
     * @param teacherId  教师ID（recorded_by）
     * @param studentId  学生ID，-1 表示全部学生
     * @param limit      返回条数上限
     * @return 成绩列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getTeacherScores(int teacherId, int studentId, int limit) throws SQLException {
        String sql =
                "SELECT " +
                        "  sc.id AS score_id, " +
                        "  st.name AS student_name, " +
                        "  st.student_no, " +
                        "  sub.subject_name, " +
                        "  sem.semester_name, " +
                        "  sc.score, " +
                        "  sc.grade AS grade_level, " +
                        "  sc.recorded_at " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "WHERE sc.recorded_by = ? " +
                        "  AND sc.is_deleted = 0 " +
                        "  AND (? = -1 OR sc.student_id = ?) " +
                        "ORDER BY sc.recorded_at DESC " +
                        "LIMIT ?";

        return executeQuery(sql, teacherId, studentId, studentId, limit);
    }

    /**
     * 教师成绩列表多条件筛选查询。
     * 支持按班级、专业、科目、关键词组合筛选。
     *
     * @param teacherId   教师ID（recorded_by）
     * @param classId     班级ID，0 表示不筛选
     * @param majorId     专业ID，0 表示不筛选
     * @param subjectId   科目ID，0 表示不筛选
     * @param keyword     搜索关键词（姓名/学号模糊匹配），null 表示不搜索
     * @return 成绩列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getTeacherScoresWithFilter(
            int teacherId, int classId, int majorId, int subjectId, String keyword) throws SQLException {

        StringBuilder sql = new StringBuilder(
                "SELECT " +
                        "  sc.id AS score_id, " +
                        "  st.name AS student_name, " +
                        "  st.student_no, " +
                        "  cl.class_name, " +
                        "  sub.subject_name, " +
                        "  sem.semester_name, " +
                        "  sc.score, " +
                        "  sc.grade AS grade_level, " +
                        "  sc.recorded_at " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN classes cl ON st.class_id = cl.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "WHERE sc.recorded_by = ? " +
                        "  AND sc.is_deleted = 0 ");

        java.util.List<Object> params = new java.util.ArrayList<>();
        params.add(teacherId);

        if (classId > 0) {
            sql.append("AND st.class_id = ? ");
            params.add(classId);
        }
        if (majorId > 0) {
            sql.append("AND cl.major_id = ? ");
            params.add(majorId);
        }
        if (subjectId > 0) {
            sql.append("AND sc.subject_id = ? ");
            params.add(subjectId);
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (st.name LIKE ? OR st.student_no LIKE ?) ");
            String pattern = "%" + keyword.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }

        sql.append("ORDER BY sc.recorded_at DESC LIMIT 100");

        return executeQuery(sql.toString(), params.toArray());
    }

    // ==================== 新增：成绩删除相关方法 ====================

    /**
     * 单条逻辑删除成绩记录。
     * 仅当该成绩由指定教师录入且未被删除时，才执行删除。
     *
     * @param scoreId   成绩ID
     * @param teacherId 教师ID（recorded_by）
     * @return true=删除成功，false=删除失败（无权限或记录不存在）
     * @throws SQLException 删除失败时抛出
     */
    public static boolean deleteScoreById(int scoreId, int teacherId) throws SQLException {
        int rows = executeUpdate(
                "UPDATE scores SET is_deleted = 1, updated_at = NOW() " +
                        "WHERE id = ? AND recorded_by = ? AND is_deleted = 0",
                scoreId, teacherId
        );
        return rows > 0;
    }

    /**
     * 批量逻辑删除成绩记录。
     * 逐条验证权限（recorded_by = teacherId），全部通过才执行删除。
     * 调用方需自行管理事务（beginTransaction / commitTransaction / rollbackTransaction）。
     *
     * @param scoreIds  成绩ID数组
     * @param teacherId 教师ID（recorded_by）
     * @return 成功删除的数量
     * @throws SQLException 删除失败时抛出
     */
    public static int deleteScoresBatch(int[] scoreIds, int teacherId) throws SQLException {
        if (scoreIds == null || scoreIds.length == 0) {
            return 0;
        }

        int deletedCount = 0;
        String sql =
                "UPDATE scores SET is_deleted = 1, updated_at = NOW() " +
                        "WHERE id = ? AND recorded_by = ? AND is_deleted = 0";

        for (int scoreId : scoreIds) {
            int rows = executeUpdate(sql, scoreId, teacherId);
            if (rows > 0) {
                deletedCount++;
            }
        }
        return deletedCount;
    }

    // ==================== 新增：管理员成绩查询相关方法 ====================

    /**
     * 管理员查询全校成绩（支持多条件组合筛选 + 分页）。
     * 同时通过 pageResult 返回总记录数和总页数。
     *
     * @param departmentId 系部ID，-1=全部
     * @param majorId      专业ID，-1=全部
     * @param classId      班级ID，-1=全部
     * @param subjectId    科目ID，-1=全部
     * @param semesterId   学期ID，-1=全部
     * @param page         当前页码（从1开始）
     * @param pageSize     每页条数
     * @param pageResult   分页结果对象，用于返回总记录数和总页数
     * @return 当前页成绩列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getAdminScores(
            int departmentId, int majorId, int classId, int subjectId, int semesterId,
            int page, int pageSize, com.score.util.PageResult<?> pageResult) throws SQLException {

        // 先查总记录数
        String countSql =
                "SELECT COUNT(*) AS total " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN classes c ON st.class_id = c.id " +
                        "JOIN majors m ON c.major_id = m.id " +
                        "JOIN departments d ON m.department_id = d.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "WHERE sc.is_deleted = 0 " +
                        "  AND st.is_deleted = 0 " +
                        "  AND c.is_deleted = 0 " +
                        "  AND m.is_deleted = 0 " +
                        "  AND d.is_deleted = 0 " +
                        "  AND sub.is_deleted = 0 " +
                        "  AND sem.is_deleted = 0 " +
                        "  AND (? = -1 OR d.id = ?) " +
                        "  AND (? = -1 OR m.id = ?) " +
                        "  AND (? = -1 OR c.id = ?) " +
                        "  AND (? = -1 OR sub.id = ?) " +
                        "  AND (? = -1 OR sem.id = ?)";

        List<Map<String, Object>> countRows = executeQuery(countSql,
                departmentId, departmentId,
                majorId, majorId,
                classId, classId,
                subjectId, subjectId,
                semesterId, semesterId
        );

        long totalRecords = 0;
        if (!countRows.isEmpty() && countRows.get(0).get("total") != null) {
            totalRecords = ((Number) countRows.get(0).get("total")).longValue();
        }

        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages < 1) totalPages = 1;

        pageResult.setTotalRecords(totalRecords);
        pageResult.setTotalPages(totalPages);
        pageResult.setCurrentPage(page);
        pageResult.setPageSize(pageSize);

        // 查询当前页数据
        String sql =
                "SELECT " +
                        "  sc.id AS score_id, " +
                        "  st.student_no, " +
                        "  st.name AS student_name, " +
                        "  c.class_name, " +
                        "  d.dept_name AS department_name, " +
                        "  m.major_name, " +
                        "  sub.subject_name, " +
                        "  sem.semester_name, " +
                        "  sc.score, " +
                        "  sc.grade AS grade_level, " +
                        "  u.real_name AS entered_by, " +
                        "  sc.recorded_at " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN classes c ON st.class_id = c.id " +
                        "JOIN majors m ON c.major_id = m.id " +
                        "JOIN departments d ON m.department_id = d.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "LEFT JOIN users u ON sc.recorded_by = u.id " +
                        "WHERE sc.is_deleted = 0 " +
                        "  AND st.is_deleted = 0 " +
                        "  AND c.is_deleted = 0 " +
                        "  AND m.is_deleted = 0 " +
                        "  AND d.is_deleted = 0 " +
                        "  AND sub.is_deleted = 0 " +
                        "  AND sem.is_deleted = 0 " +
                        "  AND (? = -1 OR d.id = ?) " +
                        "  AND (? = -1 OR m.id = ?) " +
                        "  AND (? = -1 OR c.id = ?) " +
                        "  AND (? = -1 OR sub.id = ?) " +
                        "  AND (? = -1 OR sem.id = ?) " +
                        "ORDER BY sem.start_date DESC, d.dept_name, m.major_name, c.class_name, st.name " +
                        "LIMIT ? OFFSET ?";

        int offset = (page - 1) * pageSize;
        return executeQuery(sql,
                departmentId, departmentId,
                majorId, majorId,
                classId, classId,
                subjectId, subjectId,
                semesterId, semesterId,
                pageSize, offset
        );
    }

    /**
     * 管理员导出全校成绩（支持多条件组合筛选，不分页）。
     *
     * @param departmentId 系部ID，-1=全部
     * @param majorId      专业ID，-1=全部
     * @param classId      班级ID，-1=全部
     * @param subjectId    科目ID，-1=全部
     * @param semesterId   学期ID，-1=全部
     * @return 成绩列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getAdminScoresForExport(
            int departmentId, int majorId, int classId, int subjectId, int semesterId) throws SQLException {

        String sql =
                "SELECT " +
                        "  st.student_no, " +
                        "  st.name AS student_name, " +
                        "  c.class_name, " +
                        "  d.dept_name AS department_name, " +
                        "  m.major_name, " +
                        "  sub.subject_name, " +
                        "  sem.semester_name, " +
                        "  sc.score, " +
                        "  sc.grade AS grade_level, " +
                        "  u.real_name AS entered_by, " +
                        "  sc.recorded_at " +
                        "FROM scores sc " +
                        "JOIN students st ON sc.student_id = st.id " +
                        "JOIN classes c ON st.class_id = c.id " +
                        "JOIN majors m ON c.major_id = m.id " +
                        "JOIN departments d ON m.department_id = d.id " +
                        "JOIN subjects sub ON sc.subject_id = sub.id " +
                        "JOIN semesters sem ON sc.semester_id = sem.id " +
                        "LEFT JOIN users u ON sc.recorded_by = u.id " +
                        "WHERE sc.is_deleted = 0 " +
                        "  AND st.is_deleted = 0 " +
                        "  AND c.is_deleted = 0 " +
                        "  AND m.is_deleted = 0 " +
                        "  AND d.is_deleted = 0 " +
                        "  AND sub.is_deleted = 0 " +
                        "  AND sem.is_deleted = 0 " +
                        "  AND (? = -1 OR d.id = ?) " +
                        "  AND (? = -1 OR m.id = ?) " +
                        "  AND (? = -1 OR c.id = ?) " +
                        "  AND (? = -1 OR sub.id = ?) " +
                        "  AND (? = -1 OR sem.id = ?) " +
                        "ORDER BY sem.start_date DESC, d.dept_name, m.major_name, c.class_name, st.name";

        return executeQuery(sql,
                departmentId, departmentId,
                majorId, majorId,
                classId, classId,
                subjectId, subjectId,
                semesterId, semesterId
        );
    }

    /**
     * 查询所有系部列表（用于筛选下拉框）。
     *
     * @return 系部列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getDepartments() throws SQLException {
        String sql = "SELECT id, dept_code, dept_name FROM departments WHERE is_deleted = 0 ORDER BY dept_name";
        return executeQuery(sql);
    }

    /**
     * 根据系部ID查询专业列表（用于筛选下拉框联动）。
     *
     * @param departmentId 系部ID，-1=返回全部专业
     * @return 专业列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getMajorsByDepartment(int departmentId) throws SQLException {
        String sql;
        if (departmentId == -1) {
            sql = "SELECT id, major_code, major_name, department_id FROM majors WHERE is_deleted = 0 ORDER BY major_name";
            return executeQuery(sql);
        } else {
            sql = "SELECT id, major_code, major_name, department_id FROM majors WHERE department_id = ? AND is_deleted = 0 ORDER BY major_name";
            return executeQuery(sql, departmentId);
        }
    }

    /**
     * 根据专业ID查询班级列表（用于筛选下拉框联动）。
     *
     * @param majorId 专业ID，-1=返回全部班级
     * @return 班级列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getClassesByMajor(int majorId) throws SQLException {
        String sql;
        if (majorId == -1) {
            sql = "SELECT id, class_code, class_name, major_id FROM classes WHERE is_deleted = 0 ORDER BY class_name";
            return executeQuery(sql);
        } else {
            sql = "SELECT c.id, c.class_code, c.class_name, c.major_id FROM classes c " +
                    "JOIN majors m ON c.major_id = m.id " +
                    "WHERE m.id = ? AND c.is_deleted = 0 ORDER BY c.class_name";
            return executeQuery(sql, majorId);
        }
    }

    /**
     * 查询所有科目列表（用于筛选下拉框）。
     *
     * @return 科目列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getSubjectsForAdmin() throws SQLException {
        String sql = "SELECT id, subject_code, subject_name FROM subjects WHERE is_deleted = 0 ORDER BY subject_name";
        return executeQuery(sql);
    }

    /**
     * 查询所有学期列表（用于筛选下拉框）。
     *
     * @return 学期列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getSemestersForAdmin() throws SQLException {
        String sql = "SELECT id, semester_name, start_date, is_current FROM semesters WHERE is_deleted = 0 ORDER BY start_date DESC";
        return executeQuery(sql);
    }

    // ==================== 新增：管理员科目管理相关方法 ====================

    /**
     * 分页查询科目列表（含系部名称）。
     *
     * @param page       当前页码（从1开始）
     * @param pageSize   每页条数
     * @param pageResult 分页结果对象
     * @return 当前页科目列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getSubjectsPaged(
            int page, int pageSize, PageResult<Map<String, Object>> pageResult) throws SQLException {

        // 查询总记录数
        String countSql = "SELECT COUNT(*) AS cnt FROM subjects WHERE is_deleted = 0";
        List<Map<String, Object>> countRows = executeQuery(countSql);
        long totalRecords = ((Number) countRows.get(0).get("cnt")).longValue();
        pageResult.setTotalRecords(totalRecords);

        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages < 1) totalPages = 1;
        pageResult.setTotalPages(totalPages);
        pageResult.setCurrentPage(page);
        pageResult.setPageSize(pageSize);

        if (page < 1) page = 1;
        if (page > totalPages) page = totalPages;

        int offset = (page - 1) * pageSize;
        String sql =
                "SELECT sub.id, sub.subject_code, sub.subject_name, sub.credit, " +
                        "  sub.department_id, d.dept_name, sub.is_deleted " +
                        "FROM subjects sub " +
                        "LEFT JOIN departments d ON sub.department_id = d.id AND d.is_deleted = 0 " +
                        "WHERE sub.is_deleted = 0 " +
                        "ORDER BY sub.id DESC " +
                        "LIMIT ? OFFSET ?";
        return executeQuery(sql, pageSize, offset);
    }

    /**
     * 根据ID查询科目详情（含系部名称）。
     *
     * @param subjectId 科目ID
     * @return 科目信息 Map，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static Map<String, Object> getSubjectById(int subjectId) throws SQLException {
        String sql =
                "SELECT sub.id, sub.subject_code, sub.subject_name, sub.credit, " +
                        "  sub.department_id, d.dept_name " +
                        "FROM subjects sub " +
                        "LEFT JOIN departments d ON sub.department_id = d.id AND d.is_deleted = 0 " +
                        "WHERE sub.id = ? AND sub.is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql, subjectId);
        if (rows.isEmpty()) {
            return null;
        }
        return rows.get(0);
    }

    /**
     * 新增科目。
     *
     * @param subjectCode   科目编码
     * @param subjectName   科目名称
     * @param credit        学分
     * @param departmentId  所属系部ID
     * @return 新增记录的ID
     * @throws SQLException 插入失败时抛出
     */
    public static int addSubject(String subjectCode, String subjectName, double credit, int departmentId) throws SQLException {
        String sql =
                "INSERT INTO subjects (subject_code, subject_name, credit, department_id) " +
                        "VALUES (?, ?, ?, ?)";
        return executeInsert(sql, subjectCode, subjectName, credit, departmentId);
    }

    /**
     * 更新科目信息。
     *
     * @param subjectId     科目ID
     * @param subjectCode   科目编码
     * @param subjectName   科目名称
     * @param credit        学分
     * @param departmentId  所属系部ID
     * @return 影响行数
     * @throws SQLException 更新失败时抛出
     */
    public static int updateSubject(int subjectId, String subjectCode, String subjectName, double credit, int departmentId) throws SQLException {
        String sql =
                "UPDATE subjects SET subject_code = ?, subject_name = ?, credit = ?, department_id = ?, updated_at = NOW() " +
                        "WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, subjectCode, subjectName, credit, departmentId, subjectId);
    }

    /**
     * 逻辑删除科目。
     *
     * @param subjectId 科目ID
     * @return 影响行数
     * @throws SQLException 删除失败时抛出
     */
    public static int deleteSubject(int subjectId) throws SQLException {
        String sql = "UPDATE subjects SET is_deleted = 1, updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, subjectId);
    }

    /**
     * 检查科目编码是否已存在（排除指定ID，用于编辑时）。
     *
     * @param subjectCode 科目编码
     * @param excludeId   排除的科目ID，新增时传 null
     * @return true=已存在，false=不存在
     * @throws SQLException 查询失败时抛出
     */
    public static boolean isSubjectCodeExists(String subjectCode, Integer excludeId) throws SQLException {
        String sql;
        List<Map<String, Object>> rows;
        if (excludeId == null) {
            sql = "SELECT id FROM subjects WHERE subject_code = ? AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, subjectCode);
        } else {
            sql = "SELECT id FROM subjects WHERE subject_code = ? AND id != ? AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, subjectCode, excludeId);
        }
        return !rows.isEmpty();
    }

    // ==================== 新增：管理员等级分值设置相关方法 ====================

    /**
     * 查询所有等级分值规则（全局配置，固定 subject_id=1, semester_id=1）。
     *
     * @return 等级规则列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getGradingSettings() throws SQLException {
        String sql =
                "SELECT id, grade, min_score, max_score, gpa, is_deleted " +
                        "FROM grading_settings " +
                        "WHERE subject_id = 1 AND semester_id = 1 " +
                        "ORDER BY FIELD(grade, 'A', 'B', 'C', 'D', 'F')";
        return executeQuery(sql);
    }

    /**
     * 根据ID查询等级分值规则。
     *
     * @param id 规则ID
     * @return 规则信息 Map，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static Map<String, Object> getGradingSettingById(int id) throws SQLException {
        String sql =
                "SELECT id, grade, min_score, max_score, gpa, is_deleted " +
                        "FROM grading_settings WHERE id = ? AND subject_id = 1 AND semester_id = 1";
        List<Map<String, Object>> rows = executeQuery(sql, id);
        if (rows.isEmpty()) {
            return null;
        }
        return rows.get(0);
    }

    /**
     * 检查分数区间是否与现有规则重叠。
     *
     * @param excludeId 排除的ID（编辑时），新增时传 null
     * @param minScore  新区间最低分
     * @param maxScore  新区间最高分
     * @return true=存在重叠，false=无重叠
     * @throws SQLException 查询失败时抛出
     */
    public static boolean isGradeRangeOverlap(Integer excludeId, double minScore, double maxScore) throws SQLException {
        String sql;
        List<Map<String, Object>> rows;
        if (excludeId == null) {
            sql = "SELECT id FROM grading_settings " +
                    "WHERE is_deleted = 0 " +
                    "  AND NOT (max_score < ? OR min_score > ?) " +
                    "LIMIT 1";
            rows = executeQuery(sql, minScore, maxScore);
        } else {
            sql = "SELECT id FROM grading_settings " +
                    "WHERE is_deleted = 0 AND id != ? " +
                    "  AND NOT (max_score < ? OR min_score > ?) " +
                    "LIMIT 1";
            rows = executeQuery(sql, excludeId, minScore, maxScore);
        }
        return !rows.isEmpty();
    }

    /**
     * 查询当前有效的等级规则数量。
     *
     * @return 有效规则数量
     * @throws SQLException 查询失败时抛出
     */
    public static int getActiveGradingSettingCount() throws SQLException {
        String sql = "SELECT COUNT(*) AS cnt FROM grading_settings WHERE is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql);
        return ((Number) rows.get(0).get("cnt")).intValue();
    }

    /**
     * 根据等级查询规则（用于检查唯一性）。
     *
     * @param grade     等级（A/B/C/D/F）
     * @param excludeId 排除的ID，新增时传 null
     * @return true=已存在，false=不存在
     * @throws SQLException 查询失败时抛出
     */
    public static boolean isGradeExists(String grade, Integer excludeId) throws SQLException {
        String sql;
        List<Map<String, Object>> rows;
        if (excludeId == null) {
            sql = "SELECT id FROM grading_settings WHERE grade = ? AND subject_id = 1 AND semester_id = 1 AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, grade);
        } else {
            sql = "SELECT id FROM grading_settings WHERE grade = ? AND id != ? AND subject_id = 1 AND semester_id = 1 AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, grade, excludeId);
        }
        return !rows.isEmpty();
    }

    /**
     * 新增等级分值规则（全局配置，固定 subject_id=1, semester_id=1）。
     *
     * @param grade     等级
     * @param minScore  最低分
     * @param maxScore  最高分
     * @param gpa       绩点
     * @return 新增记录ID
     * @throws SQLException 插入失败时抛出
     */
    public static int addGradingSetting(String grade, double minScore, double maxScore, double gpa) throws SQLException {
        String sql =
                "INSERT INTO grading_settings (subject_id, semester_id, grade, min_score, max_score, gpa) " +
                        "VALUES (1, 1, ?, ?, ?, ?)";
        return executeInsert(sql, grade, minScore, maxScore, gpa);
    }

    /**
     * 更新等级分值规则。
     *
     * @param id        规则ID
     * @param grade     等级
     * @param minScore  最低分
     * @param maxScore  最高分
     * @param gpa       绩点
     * @return 影响行数
     * @throws SQLException 更新失败时抛出
     */
    public static int updateGradingSetting(int id, String grade, double minScore, double maxScore, double gpa) throws SQLException {
        String sql =
                "UPDATE grading_settings SET grade = ?, min_score = ?, max_score = ?, gpa = ?, updated_at = NOW() " +
                        "WHERE id = ? AND subject_id = 1 AND semester_id = 1 AND is_deleted = 0";
        return executeUpdate(sql, grade, minScore, maxScore, gpa, id);
    }

    /**
     * 逻辑删除等级分值规则。
     *
     * @param id 规则ID
     * @return 影响行数
     * @throws SQLException 删除失败时抛出
     */
    public static int deleteGradingSetting(int id) throws SQLException {
        String sql = "UPDATE grading_settings SET is_deleted = 1, updated_at = NOW() WHERE id = ? AND subject_id = 1 AND semester_id = 1 AND is_deleted = 0";
        return executeUpdate(sql, id);
    }

    // ==================== 新增：管理员用户管理相关方法 ====================

    /**
     * 分页查询用户列表（含系部名称）。
     *
     * @param page       当前页码（从1开始）
     * @param pageSize   每页条数
     * @param pageResult 分页结果对象
     * @return 当前页用户列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getUsersPaged(
            int page, int pageSize, PageResult<Map<String, Object>> pageResult) throws SQLException {

        String countSql = "SELECT COUNT(*) AS cnt FROM users WHERE is_deleted = 0";
        List<Map<String, Object>> countRows = executeQuery(countSql);
        long totalRecords = ((Number) countRows.get(0).get("cnt")).longValue();
        pageResult.setTotalRecords(totalRecords);

        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages < 1) totalPages = 1;
        pageResult.setTotalPages(totalPages);
        pageResult.setCurrentPage(page);
        pageResult.setPageSize(pageSize);

        if (page < 1) page = 1;
        if (page > totalPages) page = totalPages;

        int offset = (page - 1) * pageSize;
        String sql =
                "SELECT u.id, u.username, u.real_name, u.role, u.department_id, " +
                        "  d.dept_name, u.status, u.last_login_at, u.created_at " +
                        "FROM users u " +
                        "LEFT JOIN departments d ON u.department_id = d.id AND d.is_deleted = 0 " +
                        "WHERE u.is_deleted = 0 " +
                        "ORDER BY u.id DESC " +
                        "LIMIT ? OFFSET ?";
        return executeQuery(sql, pageSize, offset);
    }

    /**
     * 根据ID查询用户详情。
     */
    public static Map<String, Object> getUserById(int userId) throws SQLException {
        String sql =
                "SELECT u.id, u.username, u.real_name, u.role, u.department_id, d.dept_name, u.status " +
                        "FROM users u " +
                        "LEFT JOIN departments d ON u.department_id = d.id AND d.is_deleted = 0 " +
                        "WHERE u.id = ? AND u.is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql, userId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    /**
     * 检查用户名是否已存在（不区分大小写）。
     */
    public static boolean isUsernameExists(String username, Integer excludeId) throws SQLException {
        String sql;
        List<Map<String, Object>> rows;
        if (excludeId == null) {
            sql = "SELECT id FROM users WHERE LOWER(username) = LOWER(?) AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, username);
        } else {
            sql = "SELECT id FROM users WHERE LOWER(username) = LOWER(?) AND id != ? AND is_deleted = 0 LIMIT 1";
            rows = executeQuery(sql, username, excludeId);
        }
        return !rows.isEmpty();
    }

    /**
     * 新增用户。
     */
    public static int addUser(String username, String passwordHash, String realName, String role, Integer departmentId) throws SQLException {
        String sql = "INSERT INTO users (username, password_hash, real_name, role, department_id) VALUES (?, ?, ?, ?, ?)";
        return executeInsert(sql, username, passwordHash, realName, role, departmentId);
    }

    /**
     * 更新用户信息（不含密码）。
     */
    public static int updateUser(int userId, String realName, String role, Integer departmentId, int status) throws SQLException {
        String sql = "UPDATE users SET real_name = ?, role = ?, department_id = ?, status = ?, updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, realName, role, departmentId, status, userId);
    }

    /**
     * 重置用户密码。
     */
    public static int resetUserPassword(int userId, String passwordHash) throws SQLException {
        String sql = "UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, passwordHash, userId);
    }

    /**
     * 切换用户状态（启用/禁用）。
     */
    public static int toggleUserStatus(int userId) throws SQLException {
        String sql = "UPDATE users SET status = IF(status = 1, 0, 1), updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, userId);
    }

    /**
     * 逻辑删除用户。
     */
    public static int deleteUser(int userId) throws SQLException {
        String sql = "UPDATE users SET is_deleted = 1, updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, userId);
    }

    /**
     * 更新用户密码。
     *
     * @param userId       用户ID
     * @param passwordHash 新密码（BCrypt 加密后）
     * @return 影响行数
     * @throws SQLException 更新失败时抛出
     */
    public static int updatePassword(int userId, String passwordHash) throws SQLException {
        String sql = "UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ? AND is_deleted = 0";
        return executeUpdate(sql, passwordHash, userId);
    }

    // ==================== 成绩批量导入辅助方法 ====================

    /**
     * 根据学号查找学生 ID。
     *
     * @param studentNo 学号
     * @return 学生 ID，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static Integer getStudentIdByNo(String studentNo) throws SQLException {
        String sql = "SELECT id FROM students WHERE student_no = ? AND is_deleted = 0 AND status = 1";
        List<Map<String, Object>> rows = executeQuery(sql, studentNo);
        if (rows.isEmpty()) {
            return null;
        }
        return (Integer) rows.get(0).get("id");
    }

    /**
     * 根据科目编码查找科目 ID。
     *
     * @param subjectCode 科目编码
     * @return 科目 ID，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    public static Integer getSubjectIdByCode(String subjectCode) throws SQLException {
        String sql = "SELECT id FROM subjects WHERE subject_code = ? AND is_deleted = 0";
        List<Map<String, Object>> rows = executeQuery(sql, subjectCode);
        if (rows.isEmpty()) {
            return null;
        }
        return (Integer) rows.get(0).get("id");
    }

    /**
     * 导入单条成绩（存在则更新，不存在则插入）。
     *
     * @param studentId  学生ID
     * @param subjectId  科目ID
     * @param semesterId 学期ID
     * @param score      分数
     * @return true=操作成功
     * @throws SQLException 执行失败时抛出
     */
    public static boolean importScore(int studentId, int subjectId, int semesterId, double score, int recordedBy) throws SQLException {
        if (isScoreExists(studentId, subjectId, semesterId)) {
            String sql = "UPDATE scores SET score = ?, recorded_by = ?, updated_at = NOW() WHERE student_id = ? AND subject_id = ? AND semester_id = ? AND is_deleted = 0";
            return executeUpdate(sql, score, recordedBy, studentId, subjectId, semesterId) > 0;
        } else {
            String sql = "INSERT INTO scores (student_id, subject_id, semester_id, score, recorded_by) VALUES (?, ?, ?, ?, ?)";
            return executeInsert(sql, studentId, subjectId, semesterId, score, recordedBy) > 0;
        }
    }

    // ==================== 审计日志查询 ====================

    /**
     * 分页查询审计日志，支持按操作类型和时间范围筛选。
     *
     * @param action    操作类型（INSERT/UPDATE/DELETE），null 或空表示不筛选
     * @param startDate 起始日期（yyyy-MM-dd），null 或空表示不筛选
     * @param endDate   结束日期（yyyy-MM-dd），null 或空表示不筛选
     * @param page      当前页码（从 1 开始）
     * @param pageSize  每页条数
     * @param pageResult 分页结果对象（用于填充分页信息）
     * @return 当前页数据列表
     * @throws SQLException 查询失败时抛出
     */
    public static List<Map<String, Object>> getAuditLogs(
            String action, String startDate, String endDate,
            int page, int pageSize, PageResult<Map<String, Object>> pageResult) throws SQLException {

        // 构建 WHERE 条件
        StringBuilder where = new StringBuilder(" WHERE 1=1");
        java.util.List<Object> params = new java.util.ArrayList<>();

        if (action != null && !action.trim().isEmpty()) {
            where.append(" AND al.action = ?");
            params.add(action.trim());
        }
        if (startDate != null && !startDate.trim().isEmpty()) {
            where.append(" AND al.created_at >= ?");
            params.add(startDate.trim() + " 00:00:00");
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            where.append(" AND al.created_at <= ?");
            params.add(endDate.trim() + " 23:59:59");
        }

        // 查询总数
        String countSql = "SELECT COUNT(*) AS cnt FROM audit_log al LEFT JOIN users u ON al.user_id = u.id" + where;
        List<Map<String, Object>> countRows = executeQuery(countSql, params.toArray());
        long totalRecords = ((Number) countRows.get(0).get("cnt")).longValue();
        pageResult.setTotalRecords(totalRecords);

        int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
        if (totalPages < 1) totalPages = 1;
        pageResult.setTotalPages(totalPages);
        pageResult.setCurrentPage(page);
        pageResult.setPageSize(pageSize);

        if (page < 1) page = 1;
        if (page > totalPages) page = totalPages;

        int offset = (page - 1) * pageSize;
        String sql =
                "SELECT al.id, al.table_name, al.record_id, al.action, " +
                        "al.old_data, al.new_data, al.created_at, " +
                        "u.real_name AS operator_name " +
                        "FROM audit_log al " +
                        "LEFT JOIN users u ON al.user_id = u.id" +
                        where +
                        " ORDER BY al.created_at DESC" +
                        " LIMIT ? OFFSET ?";
        params.add(pageSize);
        params.add(offset);

        return executeQuery(sql, params.toArray());
    }
}