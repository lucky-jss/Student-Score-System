<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.Student" %>
<%@ page import="com.score.dao.DB" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.math.RoundingMode" %>

<%
    // ==================== 权限检查 ====================
    Student student = (Student) session.getAttribute("student");
    String role = (String) session.getAttribute("role");
    if (student == null || !"student".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String ctx = request.getContextPath();
    int studentId = student.getId();

    // ==================== 查询数据 ====================
    String className = "未知班级";
    List<Map<String, Object>> gpaResult = new ArrayList<>();
    List<Map<String, Object>> scoreList = new ArrayList<>();
    List<Map<String, Object>> rankResult = new ArrayList<>();
    String error = null;

    try {
        // 班级名称
        className = DB.getClassName(student.getClassId());

        // 调用 sp_calculate_gpa 计算总 GPA（不限制学期）
        gpaResult = DB.callProcedureQuery("{call sp_calculate_gpa(?, ?)}", studentId, null);

        // 查询各科成绩 + 对应绩点
        String scoreSql =
                "SELECT " +
                        "  sem.semester_name, " +
                        "  sub.subject_name, " +
                        "  sub.credit, " +
                        "  sc.score, " +
                        "  gs.grade AS level_grade, " +
                        "  gs.gpa AS subject_gpa " +
                        "FROM scores sc " +
                        "JOIN subjects sub ON sc.subject_id = sub.id AND sub.is_deleted = 0 " +
                        "JOIN semesters sem ON sc.semester_id = sem.id AND sem.is_deleted = 0 " +
                        "LEFT JOIN grading_settings gs ON sub.id = gs.subject_id " +
                        "  AND sc.semester_id = gs.semester_id " +
                        "  AND sc.score >= gs.min_score AND sc.score <= gs.max_score " +
                        "  AND gs.is_deleted = 0 " +
                        "WHERE sc.student_id = ? AND sc.is_deleted = 0 " +
                        "ORDER BY sem.start_date DESC, sub.subject_name";
        scoreList = DB.executeQuery(scoreSql, studentId);

        // 查询年级排名和班级排名（基于平均分）
        String rankSql =
                "SELECT t.grade_rank, t.class_rank FROM (" +
                        "  SELECT " +
                        "    s.id AS sid, " +
                        "    RANK() OVER (ORDER BY AVG(sc2.score) DESC) AS grade_rank, " +
                        "    RANK() OVER (PARTITION BY s.class_id ORDER BY AVG(sc2.score) DESC) AS class_rank " +
                        "  FROM students s " +
                        "  LEFT JOIN scores sc2 ON s.id = sc2.student_id AND sc2.is_deleted = 0 " +
                        "  WHERE s.is_deleted = 0 AND s.status = 1 " +
                        "  GROUP BY s.id, s.class_id " +
                        ") t WHERE t.sid = ?";
        rankResult = DB.executeQuery(rankSql, studentId);

    } catch (Exception e) {
        error = "数据加载失败：" + e.getMessage();
    }

    // ==================== 计算等级分布 ====================
    int countA = 0, countB = 0, countC = 0, countD = 0, countF = 0;
    BigDecimal totalCredits = BigDecimal.ZERO;
    for (Map<String, Object> row : scoreList) {
        BigDecimal score = row.get("score") != null ? new BigDecimal(row.get("score").toString()) : BigDecimal.ZERO;
        BigDecimal credit = row.get("credit") != null ? new BigDecimal(row.get("credit").toString()) : BigDecimal.ZERO;
        totalCredits = totalCredits.add(credit);
        if (score.compareTo(new BigDecimal("90")) >= 0) countA++;
        else if (score.compareTo(new BigDecimal("80")) >= 0) countB++;
        else if (score.compareTo(new BigDecimal("70")) >= 0) countC++;
        else if (score.compareTo(new BigDecimal("60")) >= 0) countD++;
        else countF++;
    }

    // ==================== 提取 GPA 数据 ====================
    BigDecimal gpa = BigDecimal.ZERO;
    BigDecimal weightedAvg = BigDecimal.ZERO;
    if (!gpaResult.isEmpty()) {
        Map<String, Object> gpaRow = gpaResult.get(0);
        if (gpaRow.get("gpa") != null) {
            gpa = new BigDecimal(gpaRow.get("gpa").toString());
        }
        if (gpaRow.get("weighted_avg_score") != null) {
            weightedAvg = new BigDecimal(gpaRow.get("weighted_avg_score").toString());
        }
    }

    // ==================== 提取排名数据 ====================
    int gradeRank = 0;
    int classRank = 0;
    if (!rankResult.isEmpty()) {
        Map<String, Object> rankRow = rankResult.get(0);
        if (rankRow.get("grade_rank") != null) gradeRank = ((Number) rankRow.get("grade_rank")).intValue();
        if (rankRow.get("class_rank") != null) classRank = ((Number) rankRow.get("class_rank")).intValue();
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>成绩统计 - 学生个人中心</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #66bb6a 0%, #43a047 100%);
            color: #fff;
            padding: 16px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 18px; font-weight: 500; }
        .header .nav-links a {
            color: #fff;
            text-decoration: none;
            margin-left: 16px;
            font-size: 14px;
            padding: 6px 14px;
            background: rgba(255,255,255,0.2);
            border-radius: 4px;
            transition: background 0.3s;
        }
        .header .nav-links a:hover { background: rgba(255,255,255,0.3); }
        .container {
            max-width: 1000px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .error-msg {
            background: #ffebee;
            color: #c62828;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #c62828;
        }

        /* 学生信息卡 */
        .info-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            padding: 24px;
            margin-bottom: 20px;
        }
        .info-card h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 16px;
        }
        .info-item .label { font-size: 13px; color: #999; margin-bottom: 4px; }
        .info-item .value { font-size: 15px; color: #333; font-weight: 500; }
        .info-item .value.highlight { color: #43a047; font-size: 20px; }

        /* 统计卡片 */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            padding: 20px;
            text-align: center;
        }
        .stat-card .number {
            font-size: 28px;
            font-weight: 600;
            color: #43a047;
            margin-bottom: 6px;
        }
        .stat-card .label { font-size: 13px; color: #888; }

        /* 等级分布 */
        .grade-bar {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
        }
        .grade-bar:last-child { margin-bottom: 0; }
        .grade-label {
            width: 40px;
            text-align: center;
            font-weight: 600;
            font-size: 14px;
        }
        .grade-a { color: #2e7d32; }
        .grade-b { color: #1565c0; }
        .grade-c { color: #f57f17; }
        .grade-d { color: #e65100; }
        .grade-f { color: #c62828; }
        .grade-track {
            flex: 1;
            height: 24px;
            background: #f5f5f5;
            border-radius: 12px;
            overflow: hidden;
            position: relative;
        }
        .grade-fill {
            height: 100%;
            border-radius: 12px;
            transition: width 0.5s ease;
        }
        .fill-a { background: #a5d6a7; }
        .fill-b { background: #90caf9; }
        .fill-c { background: #ffe082; }
        .fill-d { background: #ffcc80; }
        .fill-f { background: #ef9a9a; }
        .grade-count {
            width: 40px;
            text-align: right;
            font-size: 14px;
            color: #555;
        }

        /* 表格 */
        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
            margin-bottom: 20px;
        }
        .table-card table {
            width: 100%;
            border-collapse: collapse;
        }
        .table-card th {
            background: #f5f7fa;
            padding: 12px 16px;
            font-size: 13px;
            color: #666;
            font-weight: 600;
            text-align: center;
            border-bottom: 2px solid #e0e0e0;
        }
        .table-card td {
            padding: 12px 16px;
            font-size: 14px;
            color: #333;
            text-align: center;
            border-bottom: 1px solid #f0f0f0;
        }
        .table-card tr:nth-child(even) { background: #fafbfc; }
        .table-card tr:hover { background: #f0f7f0; }
        .score-badge {
            display: inline-block;
            padding: 2px 10px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 500;
        }
        .score-excellent { background: #e8f5e9; color: #2e7d32; }
        .score-good { background: #e3f2fd; color: #1565c0; }
        .score-pass { background: #fff8e1; color: #f57f17; }
        .score-fail { background: #ffebee; color: #c62828; }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 16px;
        }

        @media print {
            .header .nav-links { display: none !important; }
            body { background: #fff; }
            .container { margin: 0; padding: 20px; }
            .info-card, .stat-card, .table-card { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
<div class="header">
    <h1>学生个人中心 - 成绩统计</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/student/index.jsp">返回首页</a>
        <a href="<%= ctx %>/student/query">成绩查询</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (error != null) { %>
    <div class="error-msg"><%= error %></div>
    <% } %>

    <!-- 学生基本信息 -->
    <div class="info-card">
        <h3>基本信息</h3>
        <div class="info-grid">
            <div class="info-item">
                <div class="label">姓名</div>
                <div class="value"><%= student.getName() %></div>
            </div>
            <div class="info-item">
                <div class="label">学号</div>
                <div class="value"><%= student.getStudentNo() %></div>
            </div>
            <div class="info-item">
                <div class="label">班级</div>
                <div class="value"><%= className %></div>
            </div>
            <div class="info-item">
                <div class="label">加权平均分</div>
                <div class="value highlight"><%= weightedAvg %></div>
            </div>
            <div class="info-item">
                <div class="label">总 GPA</div>
                <div class="value highlight"><%= gpa %></div>
            </div>
            <div class="info-item">
                <div class="label">已修学分</div>
                <div class="value highlight"><%= totalCredits %></div>
            </div>
        </div>
    </div>

    <!-- 排名信息 -->
    <% if (gradeRank > 0 || classRank > 0) { %>
    <div class="stat-grid">
        <div class="stat-card">
            <div class="number"><%= gradeRank > 0 ? gradeRank : "-" %></div>
            <div class="label">年级排名</div>
        </div>
        <div class="stat-card">
            <div class="number"><%= classRank > 0 ? classRank : "-" %></div>
            <div class="label">班级排名</div>
        </div>
        <div class="stat-card">
            <div class="number"><%= scoreList.size() %></div>
            <div class="label">已修科目</div>
        </div>
        <div class="stat-card">
            <div class="number"><%= totalCredits %></div>
            <div class="label">总学分</div>
        </div>
    </div>
    <% } %>

    <!-- 等级分布 -->
    <% if (scoreList.size() > 0) { %>
    <div class="info-card">
        <h3>等级分布</h3>
        <% int totalSubjects = scoreList.size(); %>
        <div class="grade-bar">
            <span class="grade-label grade-a">A</span>
            <div class="grade-track">
                <div class="grade-fill fill-a" style="width:<%= totalSubjects > 0 ? (countA * 100 / totalSubjects) : 0 %>%"></div>
            </div>
            <span class="grade-count"><%= countA %> 门</span>
        </div>
        <div class="grade-bar">
            <span class="grade-label grade-b">B</span>
            <div class="grade-track">
                <div class="grade-fill fill-b" style="width:<%= totalSubjects > 0 ? (countB * 100 / totalSubjects) : 0 %>%"></div>
            </div>
            <span class="grade-count"><%= countB %> 门</span>
        </div>
        <div class="grade-bar">
            <span class="grade-label grade-c">C</span>
            <div class="grade-track">
                <div class="grade-fill fill-c" style="width:<%= totalSubjects > 0 ? (countC * 100 / totalSubjects) : 0 %>%"></div>
            </div>
            <span class="grade-count"><%= countC %> 门</span>
        </div>
        <div class="grade-bar">
            <span class="grade-label grade-d">D</span>
            <div class="grade-track">
                <div class="grade-fill fill-d" style="width:<%= totalSubjects > 0 ? (countD * 100 / totalSubjects) : 0 %>%"></div>
            </div>
            <span class="grade-count"><%= countD %> 门</span>
        </div>
        <div class="grade-bar">
            <span class="grade-label grade-f">F</span>
            <div class="grade-track">
                <div class="grade-fill fill-f" style="width:<%= totalSubjects > 0 ? (countF * 100 / totalSubjects) : 0 %>%"></div>
            </div>
            <span class="grade-count"><%= countF %> 门</span>
        </div>
    </div>
    <% } %>

    <!-- 成绩明细 -->
    <div class="table-card">
        <% if (scoreList.isEmpty()) { %>
        <div class="empty-state">暂无成绩记录</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th>序号</th>
                <th>学期</th>
                <th>科目</th>
                <th>学分</th>
                <th>分数</th>
                <th>等级</th>
                <th>绩点</th>
            </tr>
            </thead>
            <tbody>
            <% int idx = 0; %>
            <% for (Map<String, Object> row : scoreList) { %>
            <% idx++; %>
            <% BigDecimal score = row.get("score") != null ? new BigDecimal(row.get("score").toString()) : BigDecimal.ZERO; %>
            <% BigDecimal credit = row.get("credit") != null ? new BigDecimal(row.get("credit").toString()) : BigDecimal.ZERO; %>
            <% BigDecimal subjectGpa = row.get("subject_gpa") != null ? new BigDecimal(row.get("subject_gpa").toString()) : BigDecimal.ZERO; %>
            <% String levelGrade = row.get("level_grade") != null ? (String) row.get("level_grade") : "-"; %>
            <tr>
                <td><%= idx %></td>
                <td><%= row.get("semester_name") %></td>
                <td><%= row.get("subject_name") %></td>
                <td><%= credit %></td>
                <td>
                    <span class="score-badge <%=
                        score.compareTo(new BigDecimal("90")) >= 0 ? "score-excellent" :
                        score.compareTo(new BigDecimal("80")) >= 0 ? "score-good" :
                        score.compareTo(new BigDecimal("60")) >= 0 ? "score-pass" : "score-fail"
                    %>"><%= score %></span>
                </td>
                <td><%= levelGrade %></td>
                <td><%= subjectGpa.compareTo(BigDecimal.ZERO) > 0 ? subjectGpa : "-" %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>
</div>
</body>
</html>