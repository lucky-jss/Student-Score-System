<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取 Servlet 传递的数据 ====================
    List<Map<String, Object>> scoreList = (List<Map<String, Object>>) request.getAttribute("scoreList");
    List<Map<String, Object>> departments = (List<Map<String, Object>>) request.getAttribute("departments");
    List<Map<String, Object>> majors = (List<Map<String, Object>>) request.getAttribute("majors");
    List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
    List<Map<String, Object>> subjects = (List<Map<String, Object>>) request.getAttribute("subjects");
    List<Map<String, Object>> semesters = (List<Map<String, Object>>) request.getAttribute("semesters");

    Long totalRecords = (Long) request.getAttribute("totalRecords");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer currentPage = (Integer) request.getAttribute("currentPage");

    Integer selectedDepartmentId = (Integer) request.getAttribute("selectedDepartmentId");
    Integer selectedMajorId = (Integer) request.getAttribute("selectedMajorId");
    Integer selectedClassId = (Integer) request.getAttribute("selectedClassId");
    Integer selectedSubjectId = (Integer) request.getAttribute("selectedSubjectId");
    Integer selectedSemesterId = (Integer) request.getAttribute("selectedSemesterId");

    if (scoreList == null) scoreList = new ArrayList<>();
    if (departments == null) departments = new ArrayList<>();
    if (majors == null) majors = new ArrayList<>();
    if (classes == null) classes = new ArrayList<>();
    if (subjects == null) subjects = new ArrayList<>();
    if (semesters == null) semesters = new ArrayList<>();
    if (totalRecords == null) totalRecords = 0L;
    if (totalPages == null) totalPages = 1;
    if (currentPage == null) currentPage = 1;
    if (selectedDepartmentId == null) selectedDepartmentId = -1;
    if (selectedMajorId == null) selectedMajorId = -1;
    if (selectedClassId == null) selectedClassId = -1;
    if (selectedSubjectId == null) selectedSubjectId = -1;
    if (selectedSemesterId == null) selectedSemesterId = -1;

    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();

    // 构建当前筛选条件的查询字符串（用于分页和导出）
    StringBuilder filterParams = new StringBuilder();
    if (selectedDepartmentId != -1) filterParams.append("&departmentId=").append(selectedDepartmentId);
    if (selectedMajorId != -1) filterParams.append("&majorId=").append(selectedMajorId);
    if (selectedClassId != -1) filterParams.append("&classId=").append(selectedClassId);
    if (selectedSubjectId != -1) filterParams.append("&subjectId=").append(selectedSubjectId);
    if (selectedSemesterId != -1) filterParams.append("&semesterId=").append(selectedSemesterId);
    String filterQuery = filterParams.toString();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>全校成绩查询 - 管理员控制台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            max-width: 1300px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .alert {
            padding: 12px 18px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }

        /* 筛选栏 */
        .filter-bar {
            background: #fff;
            padding: 20px 24px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            margin-bottom: 20px;
        }
        .filter-bar h3 {
            font-size: 15px;
            color: #333;
            margin-bottom: 14px;
            font-weight: 600;
        }
        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
            margin-bottom: 14px;
        }
        .filter-item label {
            display: block;
            font-size: 13px;
            color: #666;
            margin-bottom: 6px;
            font-weight: 500;
        }
        .filter-item select {
            width: 100%;
            padding: 8px 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            background: #fff;
        }
        .filter-item select:focus { outline: none; border-color: #667eea; }
        .filter-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
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
        .btn-primary { background: #667eea; color: #fff; }
        .btn-secondary { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .btn-export { background: #42a5f5; color: #fff; }
        .btn-print { background: #66bb6a; color: #fff; }

        /* 统计信息 */
        .stats-bar {
            background: #fff;
            padding: 12px 24px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            font-size: 14px;
            color: #666;
        }
        .stats-bar strong { color: #333; }

        /* 表格 */
        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        .table-card table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .table-card th {
            background: #f5f7fa;
            padding: 10px 8px;
            font-size: 12px;
            color: #666;
            font-weight: 600;
            text-align: center;
            border-bottom: 2px solid #e0e0e0;
            white-space: nowrap;
        }
        .table-card td {
            padding: 10px 8px;
            color: #333;
            text-align: center;
            border-bottom: 1px solid #f0f0f0;
        }
        .table-card tr:nth-child(even) { background: #fafbfc; }
        .table-card tr:hover { background: #e8f4fd; }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 16px;
        }
        .score-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 500;
        }
        .score-excellent { background: #e8f5e9; color: #2e7d32; }
        .score-good { background: #e3f2fd; color: #1565c0; }
        .score-pass { background: #fff8e1; color: #f57f17; }
        .score-fail { background: #ffebee; color: #c62828; }

        /* 分页 */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 6px;
            padding: 16px;
            background: #fff;
            border-top: 1px solid #f0f0f0;
        }
        .pagination a, .pagination span {
            padding: 6px 12px;
            border-radius: 4px;
            font-size: 13px;
            text-decoration: none;
            color: #667eea;
            border: 1px solid #e0e0e0;
            transition: all 0.3s;
        }
        .pagination a:hover {
            background: #667eea;
            color: #fff;
            border-color: #667eea;
        }
        .pagination .current {
            background: #667eea;
            color: #fff;
            border-color: #667eea;
        }
        .pagination .disabled {
            color: #bbb;
            cursor: not-allowed;
        }
        .pagination .disabled:hover {
            background: #fff;
            color: #bbb;
            border-color: #e0e0e0;
        }
        .pagination .page-info {
            border: none;
            color: #666;
            margin: 0 8px;
        }
        .pagination .page-info:hover {
            background: #fff;
            color: #666;
        }

        /* 打印样式 */
        @media print {
            .header, .filter-bar, .filter-actions, .pagination, .btn { display: none !important; }
            .container { margin: 0; padding: 10px; max-width: 100%; }
            .table-card { box-shadow: none; }
            body { background: #fff; }
        }
    </style>
</head>
<body>
<div class="header">
    <h1>管理员控制台 - 全校成绩查询</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (error != null) { %>
    <div class="alert alert-error">&#10008; <%= error %></div>
    <% } %>

    <!-- 筛选栏 -->
    <div class="filter-bar">
        <h3>&#128269; 筛选条件</h3>
        <form id="filterForm" action="<%= ctx %>/admin/scores" method="get">
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="departmentId">系部</label>
                    <select id="departmentId" name="departmentId" onchange="submitFilterForm()">
                        <option value="-1" <%= selectedDepartmentId == -1 ? "selected" : "" %>>全部系部</option>
                        <% for (Map<String, Object> d : departments) { %>
                        <option value="<%= d.get("id") %>" <%= selectedDepartmentId.equals(d.get("id")) ? "selected" : "" %>>
                            <%= d.get("dept_name") %>
                        </option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="majorId">专业</label>
                    <select id="majorId" name="majorId" onchange="submitFilterForm()">
                        <option value="-1" <%= selectedMajorId == -1 ? "selected" : "" %>>全部专业</option>
                        <% for (Map<String, Object> m : majors) { %>
                        <option value="<%= m.get("id") %>" <%= selectedMajorId.equals(m.get("id")) ? "selected" : "" %>>
                            <%= m.get("major_name") %>
                        </option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="classId">班级</label>
                    <select id="classId" name="classId" onchange="submitFilterForm()">
                        <option value="-1" <%= selectedClassId == -1 ? "selected" : "" %>>全部班级</option>
                        <% for (Map<String, Object> c : classes) { %>
                        <option value="<%= c.get("id") %>" <%= selectedClassId.equals(c.get("id")) ? "selected" : "" %>>
                            <%= c.get("class_name") %>
                        </option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="subjectId">科目</label>
                    <select id="subjectId" name="subjectId" onchange="submitFilterForm()">
                        <option value="-1" <%= selectedSubjectId == -1 ? "selected" : "" %>>全部科目</option>
                        <% for (Map<String, Object> s : subjects) { %>
                        <option value="<%= s.get("id") %>" <%= selectedSubjectId.equals(s.get("id")) ? "selected" : "" %>>
                            <%= s.get("subject_name") %>
                        </option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="semesterId">学期</label>
                    <select id="semesterId" name="semesterId" onchange="submitFilterForm()">
                        <option value="-1" <%= selectedSemesterId == -1 ? "selected" : "" %>>全部学期</option>
                        <% for (Map<String, Object> sem : semesters) { %>
                        <option value="<%= sem.get("id") %>" <%= selectedSemesterId.equals(sem.get("id")) ? "selected" : "" %>>
                            <%= sem.get("semester_name") %>
                        </option>
                        <% } %>
                    </select>
                </div>
            </div>
            <div class="filter-actions">
                <button type="submit" class="btn btn-primary">&#128269; 查询</button>
                <a href="<%= ctx %>/admin/scores" class="btn btn-secondary">&#128260; 重置</a>
                <a href="<%= ctx %>/admin/scores/export?page=1<%= filterQuery %>" class="btn btn-export">&#128190; 导出 CSV</a>
                <button type="button" class="btn btn-print" onclick="window.print()">&#128424; 打印</button>
            </div>
        </form>
    </div>

    <!-- 统计信息 -->
    <div class="stats-bar">
        共 <strong><%= totalRecords %></strong> 条记录，
        第 <strong><%= currentPage %></strong> / <strong><%= totalPages %></strong> 页
    </div>

    <!-- 成绩表格 -->
    <div class="table-card">
        <% if (scoreList.isEmpty()) { %>
        <div class="empty-state">暂无成绩记录</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th style="width:40px;">序号</th>
                <th>学号</th>
                <th>姓名</th>
                <th>班级</th>
                <th>系部</th>
                <th>专业</th>
                <th>科目</th>
                <th>学期</th>
                <th>分数</th>
                <th>等级</th>
                <th>录入人</th>
                <th>录入时间</th>
            </tr>
            </thead>
            <tbody>
            <% int idx = (currentPage - 1) * 15; %>
            <% for (Map<String, Object> row : scoreList) { %>
            <% idx++; %>
            <tr>
                <td><%= idx %></td>
                <td><%= row.get("student_no") %></td>
                <td><%= row.get("student_name") %></td>
                <td><%= row.get("class_name") %></td>
                <td><%= row.get("department_name") %></td>
                <td><%= row.get("major_name") %></td>
                <td><%= row.get("subject_name") %></td>
                <td><%= row.get("semester_name") %></td>
                <td>
                    <% BigDecimal scoreVal = row.get("score") != null ? new BigDecimal(row.get("score").toString()) : BigDecimal.ZERO; %>
                    <span class="score-badge <%=
                                        scoreVal.compareTo(new BigDecimal("90")) >= 0 ? "score-excellent" :
                                        scoreVal.compareTo(new BigDecimal("80")) >= 0 ? "score-good" :
                                        scoreVal.compareTo(new BigDecimal("60")) >= 0 ? "score-pass" : "score-fail"
                                    %>"><%= scoreVal %></span>
                </td>
                <td><%= row.get("grade_level") != null ? row.get("grade_level") : "-" %></td>
                <td><%= row.get("entered_by") != null ? row.get("entered_by") : "-" %></td>
                <td><%= row.get("recorded_at") %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>

    <!-- 分页 -->
    <% if (totalPages > 1) { %>
    <div class="pagination">
        <%-- 首页 --%>
        <% if (currentPage > 1) { %>
        <a href="<%= ctx %>/admin/scores?page=1<%= filterQuery %>">首页</a>
        <% } else { %>
        <span class="disabled">首页</span>
        <% } %>

        <%-- 上一页 --%>
        <% if (currentPage > 1) { %>
        <a href="<%= ctx %>/admin/scores?page=<%= currentPage - 1 %><%= filterQuery %>">上一页</a>
        <% } else { %>
        <span class="disabled">上一页</span>
        <% } %>

        <%-- 页码信息 --%>
        <span class="page-info"><%= currentPage %> / <%= totalPages %></span>

        <%-- 下一页 --%>
        <% if (currentPage < totalPages) { %>
        <a href="<%= ctx %>/admin/scores?page=<%= currentPage + 1 %><%= filterQuery %>">下一页</a>
        <% } else { %>
        <span class="disabled">下一页</span>
        <% } %>

        <%-- 末页 --%>
        <% if (currentPage < totalPages) { %>
        <a href="<%= ctx %>/admin/scores?page=<%= totalPages %><%= filterQuery %>">末页</a>
        <% } else { %>
        <span class="disabled">末页</span>
        <% } %>
    </div>
    <% } %>
</div>

<script>
    // 联动筛选：下拉框改变时自动提交表单
    function submitFilterForm() {
        document.getElementById('filterForm').submit();
    }
</script>
</body>
</html>