<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.Student" %>
<%@ page import="com.score.util.PageResult" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>

<%
    // ==================== 权限检查 ====================
    Student student = (Student) session.getAttribute("student");
    String role = (String) session.getAttribute("role");
    if (student == null || !"student".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取数据 ====================
    List<Map<String, Object>> scoreList = (List<Map<String, Object>>) request.getAttribute("scoreList");
    PageResult<Map<String, Object>> pageResult = (PageResult<Map<String, Object>>) request.getAttribute("pageResult");
    List<Map<String, Object>> semesterList = (List<Map<String, Object>>) request.getAttribute("semesterList");
    Integer selectedSemesterId = (Integer) request.getAttribute("selectedSemesterId");
    String studentName = (String) request.getAttribute("studentName");
    String studentNo = (String) request.getAttribute("studentNo");
    String className = (String) request.getAttribute("className");
    String error = (String) request.getAttribute("error");

    if (studentName == null) studentName = student.getName();
    if (studentNo == null) studentNo = student.getStudentNo();
    if (className == null) className = "未知班级";
    if (selectedSemesterId == null) selectedSemesterId = -1;

    int currentPage = pageResult != null ? pageResult.getCurrentPage() : 1;
    int totalPages = pageResult != null ? pageResult.getTotalPages() : 1;
    long totalRecords = pageResult != null ? pageResult.getTotalRecords() : 0;

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>成绩查询 - 学生个人中心</title>
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
        .student-info {
            background: #fff;
            padding: 20px 24px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            display: flex;
            gap: 40px;
            font-size: 14px;
            color: #555;
        }
        .student-info span { font-weight: 500; }
        .student-info .label { color: #999; margin-right: 6px; }
        .filter-bar {
            background: #fff;
            padding: 16px 24px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }
        .filter-bar label { font-size: 14px; color: #555; font-weight: 500; }
        .filter-bar select {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .filter-bar select:focus { outline: none; border-color: #66bb6a; }
        .btn {
            padding: 8px 18px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: opacity 0.3s;
        }
        .btn:hover { opacity: 0.85; }
        .btn-primary { background: #66bb6a; color: #fff; }
        .btn-export { background: #42a5f5; color: #fff; }
        .btn-print { background: #ff9800; color: #fff; }
        .btn-sm { padding: 6px 12px; font-size: 13px; }
        .btn-disabled { background: #ccc; color: #999; cursor: default; }
        .error-msg {
            background: #ffebee;
            color: #c62828;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #c62828;
        }
        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
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
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 16px;
        }
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            padding: 16px;
            font-size: 14px;
            color: #666;
        }
        .pagination a, .pagination span {
            padding: 6px 14px;
            border-radius: 4px;
            text-decoration: none;
            border: 1px solid #ddd;
            color: #555;
        }
        .pagination a:hover { background: #66bb6a; color: #fff; border-color: #66bb6a; }
        .pagination .active {
            background: #66bb6a;
            color: #fff;
            border-color: #66bb6a;
        }
        .pagination .disabled {
            color: #ccc;
            border-color: #eee;
            pointer-events: none;
        }
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
        .rank-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 600;
        }
        .rank-top { background: #fff3e0; color: #e65100; }
        .rank-normal { background: #f5f5f5; color: #666; }

        @media print {
            .header, .filter-bar, .pagination, .no-print { display: none !important; }
            body { background: #fff; }
            .container { margin: 0; padding: 20px; }
            .table-card { box-shadow: none; border: 1px solid #ddd; }
            .student-info { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
<div class="header">
    <h1>学生个人中心 - 成绩查询</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/student/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (error != null) { %>
    <div class="error-msg"><%= error %></div>
    <% } %>

    <!-- 学生基本信息 -->
    <div class="student-info">
        <div><span class="label">姓名：</span><span><%= studentName %></span></div>
        <div><span class="label">学号：</span><span><%= studentNo %></span></div>
        <div><span class="label">班级：</span><span><%= className %></span></div>
        <div><span class="label">成绩总数：</span><span><%= totalRecords %> 条</span></div>
    </div>

    <!-- 筛选栏 -->
    <div class="filter-bar no-print">
        <label for="semesterId">学期筛选：</label>
        <select id="semesterId" name="semesterId">
            <option value="-1" <%= selectedSemesterId == -1 ? "selected" : "" %>>全部学期</option>
            <% if (semesterList != null) { %>
            <% for (Map<String, Object> sem : semesterList) { %>
            <option value="<%= sem.get("id") %>"
                    <%= selectedSemesterId.equals(sem.get("id")) ? "selected" : "" %>>
                <%= sem.get("semester_name") %>
                <%= ((Number) sem.get("is_current")).intValue() == 1 ? "【当前学期】" : "" %>
            </option>
            <% } %>
            <% } %>
        </select>
        <button class="btn btn-primary" onclick="doSearch()">查 询</button>
        <div style="flex:1;"></div>
        <a href="<%= ctx %>/student/export?semesterId=<%= selectedSemesterId %>" class="btn btn-export">导出 CSV</a>
        <button class="btn btn-print" onclick="window.print()">打 印</button>
    </div>

    <!-- 成绩表格 -->
    <div class="table-card">
        <% if (scoreList == null || scoreList.isEmpty()) { %>
        <div class="empty-state">暂无成绩记录</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th style="width:50px;">序号</th>
                <th>学期</th>
                <th>科目</th>
                <th>分数</th>
                <th>等级</th>
                <th>年级排名</th>
                <th>班级排名</th>
                <th>录入时间</th>
            </tr>
            </thead>
            <tbody>
            <% int idx = (currentPage - 1) * (pageResult != null ? pageResult.getPageSize() : 10); %>
            <% for (Map<String, Object> row : scoreList) { %>
            <% idx++; %>
            <tr>
                <td><%= idx %></td>
                <td><%= row.get("semester_name") %></td>
                <td><%= row.get("subject_name") %></td>
                <td>
                    <% BigDecimal scoreVal = row.get("score") != null ? new BigDecimal(row.get("score").toString()) : BigDecimal.ZERO; %>
                    <span class="score-badge <%=
                                        scoreVal.compareTo(new BigDecimal("90")) >= 0 ? "score-excellent" :
                                        scoreVal.compareTo(new BigDecimal("80")) >= 0 ? "score-good" :
                                        scoreVal.compareTo(new BigDecimal("60")) >= 0 ? "score-pass" : "score-fail"
                                    %>"><%= scoreVal %></span>
                </td>
                <td><%= row.get("grade_level") != null ? row.get("grade_level") : "-" %></td>
                <td>
                    <% Object gradeRank = row.get("grade_rank"); %>
                    <span class="rank-badge <%= gradeRank != null && ((Number) gradeRank).intValue() <= 3 ? "rank-top" : "rank-normal" %>">
                                        <%= gradeRank != null ? gradeRank : "-" %>
                                    </span>
                </td>
                <td>
                    <% Object classRank = row.get("class_rank"); %>
                    <span class="rank-badge <%= classRank != null && ((Number) classRank).intValue() <= 3 ? "rank-top" : "rank-normal" %>">
                                        <%= classRank != null ? classRank : "-" %>
                                    </span>
                </td>
                <td><%= row.get("recorded_at") %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>

    <!-- 分页导航 -->
    <% if (totalPages > 1) { %>
    <div class="pagination no-print">
        <% if (currentPage > 1) { %>
        <a href="<%= ctx %>/student/query?semesterId=<%= selectedSemesterId %>&page=1">首页</a>
        <a href="<%= ctx %>/student/query?semesterId=<%= selectedSemesterId %>&page=<%= currentPage - 1 %>">上一页</a>
        <% } else { %>
        <span class="disabled">首页</span>
        <span class="disabled">上一页</span>
        <% } %>

        <span>第 <%= currentPage %> / <%= totalPages %> 页</span>

        <% if (currentPage < totalPages) { %>
        <a href="<%= ctx %>/student/query?semesterId=<%= selectedSemesterId %>&page=<%= currentPage + 1 %>">下一页</a>
        <a href="<%= ctx %>/student/query?semesterId=<%= selectedSemesterId %>&page=<%= totalPages %>">末页</a>
        <% } else { %>
        <span class="disabled">下一页</span>
        <span class="disabled">末页</span>
        <% } %>
    </div>
    <% } %>
</div>

<script>
    function doSearch() {
        var semesterId = document.getElementById('semesterId').value;
        window.location.href = '<%= ctx %>/student/query?semesterId=' + semesterId + '&page=1';
    }
</script>
</body>
</html>