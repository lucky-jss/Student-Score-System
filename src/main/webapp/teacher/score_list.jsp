<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"teacher".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取 Servlet 传递的数据 ====================
    List<Map<String, Object>> scoreList = (List<Map<String, Object>>) request.getAttribute("scoreList");
    List<Map<String, Object>> majors = (List<Map<String, Object>>) request.getAttribute("majors");
    List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
    List<Map<String, Object>> subjects = (List<Map<String, Object>>) request.getAttribute("subjects");
    String keyword = (String) request.getAttribute("keyword");
    Integer filterClassId = (Integer) request.getAttribute("classId");
    Integer filterMajorId = (Integer) request.getAttribute("majorId");
    Integer filterSubjectId = (Integer) request.getAttribute("subjectId");

    if (scoreList == null) scoreList = new ArrayList<>();
    if (majors == null) majors = new ArrayList<>();
    if (classes == null) classes = new ArrayList<>();
    if (subjects == null) subjects = new ArrayList<>();
    if (filterClassId == null) filterClassId = 0;
    if (filterMajorId == null) filterMajorId = 0;
    if (filterSubjectId == null) filterSubjectId = 0;

    // 获取操作结果信息（来自 Session 的修改成功消息）
    String sessionSuccess = (String) session.getAttribute("success");
    if (sessionSuccess != null) session.removeAttribute("success");

    // 获取操作结果信息（来自 Request 的错误消息）
    String requestError = (String) request.getAttribute("error");

    // 获取 URL 参数中的删除成功信息
    String urlSuccess = request.getParameter("success");
    String batchCount = request.getParameter("count");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>成绩管理 - 教师工作台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #42a5f5 0%, #1e88e5 100%);
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
            max-width: 1100px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .alert {
            padding: 12px 18px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }

        /* 筛选栏样式 */
        .filter-bar {
            background: #fff;
            padding: 16px 24px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            margin-bottom: 20px;
        }
        .filter-row {
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 12px;
        }
        .filter-row:last-child { margin-bottom: 0; }
        .filter-bar label { font-size: 14px; color: #555; font-weight: 500; }
        .filter-bar select {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 200px;
        }
        .filter-bar select:focus { outline: none; border-color: #42a5f5; }
        .filter-bar input[type="text"] {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 220px;
        }
        .filter-bar input[type="text"]:focus { outline: none; border-color: #42a5f5; }
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
        .btn-primary { background: #42a5f5; color: #fff; }
        .btn-secondary { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .btn-danger { background: #e53935; color: #fff; }
        .btn-danger:hover { opacity: 0.85; background: #c62828; }

        /* 表格样式 */
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
            padding: 12px 14px;
            font-size: 13px;
            color: #666;
            font-weight: 600;
            text-align: center;
            border-bottom: 2px solid #e0e0e0;
        }
        .table-card td {
            padding: 12px 14px;
            font-size: 14px;
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
        .btn-edit {
            padding: 4px 12px;
            background: #42a5f5;
            color: #fff;
            border: none;
            border-radius: 4px;
            font-size: 13px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        .btn-edit:hover { background: #1e88e5; }
        .btn-delete {
            padding: 4px 12px;
            background: #e53935;
            color: #fff;
            border: none;
            border-radius: 4px;
            font-size: 13px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin-left: 4px;
        }
        .btn-delete:hover { background: #c62828; }
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
        .batch-actions {
            background: #fff;
            padding: 12px 24px;
            border-radius: 0 0 10px 10px;
            border-top: 1px solid #f0f0f0;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .batch-actions label {
            font-size: 14px;
            color: #555;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .batch-actions input[type="checkbox"] {
            width: 16px;
            height: 16px;
            cursor: pointer;
        }
        /* 表格中的复选框 */
        .table-card input[type="checkbox"] {
            width: 16px;
            height: 16px;
            cursor: pointer;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>教师工作台 - 成绩管理</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/teacher/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <%-- 修改成功消息（来自 Session） --%>
    <% if (sessionSuccess != null) { %>
    <div class="alert alert-success">&#10004; <%= sessionSuccess %></div>
    <% } %>

    <%-- 删除成功消息（来自 URL 参数） --%>
    <% if ("deleted".equals(urlSuccess)) { %>
    <div class="alert alert-success">&#10004; 成绩已成功删除</div>
    <% } else if ("batch_deleted".equals(urlSuccess)) { %>
    <div class="alert alert-success">&#10004; 成功删除 <%= batchCount %> 条成绩</div>
    <% } %>

    <%-- 错误消息（来自 Request） --%>
    <% if (requestError != null) { %>
    <div class="alert alert-error">&#10008; <%= requestError %></div>
    <% } %>

    <!-- 筛选栏 -->
    <form action="<%= ctx %>/teacher/score_list" method="get" id="filterForm">
        <div class="filter-bar">
            <!-- 第一行：关键词搜索 -->
            <div class="filter-row">
                <label for="keyword">关键词：</label>
                <input type="text" name="keyword" placeholder="输入学生姓名或学号搜索"
                       value="<%= keyword != null ? keyword : "" %>">
            </div>
            <!-- 第二行：下拉筛选 -->
            <div class="filter-row">
                <label for="majorId">专业：</label>
                <select name="majorId" id="majorId">
                    <option value="0">全部专业</option>
                    <% for (Map<String, Object> m : majors) { %>
                    <option value="<%= m.get("id") %>" <%= filterMajorId.equals(m.get("id")) ? "selected" : "" %>>
                        <%= m.get("major_name") %>
                    </option>
                    <% } %>
                </select>

                <label for="classId">班级：</label>
                <select name="classId" id="classId">
                    <option value="0">全部班级</option>
                    <% for (Map<String, Object> c : classes) { %>
                    <option value="<%= c.get("id") %>" <%= filterClassId.equals(c.get("id")) ? "selected" : "" %>>
                        <%= c.get("class_name") %> (<%= c.get("major_name") %>)
                    </option>
                    <% } %>
                </select>

                <label for="subjectId">科目：</label>
                <select name="subjectId" id="subjectId">
                    <option value="0">全部科目</option>
                    <% for (Map<String, Object> s : subjects) { %>
                    <option value="<%= s.get("id") %>" <%= filterSubjectId.equals(s.get("id")) ? "selected" : "" %>>
                        <%= s.get("subject_name") %>
                    </option>
                    <% } %>
                </select>
            </div>
            <!-- 第三行：操作按钮 -->
            <div class="filter-row" style="margin-top:12px;">
                <button type="submit" class="btn btn-primary">查 询</button>
                <a href="<%= ctx %>/teacher/score_list" class="btn btn-secondary">重 置</a>
            </div>
        </div>
    </form>

    <!-- 成绩表格（含批量删除表单） -->
    <form id="batchDeleteForm" action="<%= ctx %>/score/deleteBatch" method="post">
        <div class="table-card">
            <% if (scoreList == null || scoreList.isEmpty()) { %>
            <div class="empty-state">暂无成绩记录</div>
            <% } else { %>
            <table>
                <thead>
                <tr>
                    <th style="width:40px;">
                        <input type="checkbox" id="selectAll" onclick="toggleAll(this)" title="全选">
                    </th>
                    <th style="width:50px;">序号</th>
                    <th>学生姓名</th>
                    <th>学号</th>
                    <th>科目</th>
                    <th>学期</th>
                    <th>分数</th>
                    <th>等级</th>
                    <th>录入时间</th>
                    <th style="width:140px;">操作</th>
                </tr>
                </thead>
                <tbody>
                <% int idx = 0; %>
                <% for (Map<String, Object> row : scoreList) { %>
                <% idx++; %>
                <tr>
                    <td>
                        <input type="checkbox" name="scoreIds" value="<%= row.get("score_id") %>">
                    </td>
                    <td><%= idx %></td>
                    <td><%= row.get("student_name") %></td>
                    <td><%= row.get("student_no") %></td>
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
                    <td><%= row.get("recorded_at") %></td>
                    <td>
                        <a href="<%= ctx %>/teacher/score_edit.jsp?id=<%= row.get("score_id") %>" class="btn-edit">修改</a>
                        <a href="javascript:void(0);" onclick="confirmDelete(<%= row.get("score_id") %>)" class="btn-delete">删除</a>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>
        </div>

        <!-- 批量删除操作栏 -->
        <% if (scoreList != null && !scoreList.isEmpty()) { %>
        <div class="batch-actions">
            <label>
                <input type="checkbox" id="selectAllBottom" onclick="toggleAll(this)">
                全选
            </label>
            <button type="button" class="btn btn-danger" onclick="confirmBatchDelete()">批量删除</button>
        </div>
        <% } %>
    </form>
</div>

<script>
    // 全选/取消全选
    // 替换后（修复：直接使用当前点击复选框的状态）：
    function toggleAll(source) {
        var checkboxes = document.querySelectorAll('input[name="scoreIds"]');
        var selectAllTop = document.getElementById('selectAll');
        var selectAllBottom = document.getElementById('selectAllBottom');

        // 同步两个全选复选框的状态为当前点击复选框的状态
        selectAllTop.checked = source.checked;
        selectAllBottom.checked = source.checked;

        checkboxes.forEach(function(cb) {
            cb.checked = source.checked;
        });
    }

    // 单条删除确认
    function confirmDelete(scoreId) {
        if (confirm('确定要删除该成绩吗？')) {
            window.location.href = '<%= ctx %>/score/delete?scoreId=' + scoreId;
        }
    }

    // 批量删除确认
    function confirmBatchDelete() {
        var checkboxes = document.querySelectorAll('input[name="scoreIds"]:checked');
        if (checkboxes.length === 0) {
            alert('请至少选择一条成绩');
            return;
        }
        if (confirm('确定要删除选中的 ' + checkboxes.length + ' 条成绩吗？')) {
            document.getElementById('batchDeleteForm').submit();
        }
    }

</script>
</body>
</html>