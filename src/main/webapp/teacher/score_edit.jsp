<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="com.score.dao.DB" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.SQLException" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"teacher".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 接收成绩ID ====================
    String scoreIdParam = request.getParameter("id");
    int scoreId = 0;
    try {
        scoreId = Integer.parseInt(scoreIdParam.trim());
    } catch (NumberFormatException | NullPointerException e) {
        response.sendRedirect(request.getContextPath() + "/teacher/score_list.jsp");
        return;
    }

    // ==================== 查询成绩详情 ====================
    Map<String, Object> scoreInfo = null;
    String loadError = null;

    try {
        scoreInfo = DB.getScoreById(scoreId);
        if (scoreInfo == null) {
            loadError = "成绩记录不存在或已被删除";
        } else {
            // 再次验证该成绩是否属于当前教师
            String checkSql = "SELECT 1 FROM scores WHERE id = ? AND recorded_by = ? AND is_deleted = 0";
            List<Map<String, Object>> checkRows = DB.executeQuery(checkSql, scoreId, currentUser.getId());
            if (checkRows.isEmpty()) {
                loadError = "您无权修改该成绩记录";
                scoreInfo = null;
            }
        }
    } catch (SQLException e) {
        loadError = "数据加载失败：" + e.getMessage();
    } finally {
        try { DB.closeConnection(); } catch (SQLException ignored) {}
    }

    // 获取 Servlet 传递的错误信息
    String error = (String) request.getAttribute("error");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>修改成绩 - 教师工作台</title>
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
            max-width: 600px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .form-card {
            background: #fff;
            padding: 32px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.06);
        }
        .form-card h2 {
            font-size: 20px;
            color: #333;
            margin-bottom: 24px;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        .form-group .readonly-value {
            padding: 12px;
            background: #f5f7fa;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            color: #333;
        }
        .form-group input[type="number"] {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input[type="number"]:focus {
            outline: none;
            border-color: #42a5f5;
        }
        .btn-group {
            display: flex;
            gap: 12px;
            margin-top: 24px;
        }
        .btn {
            flex: 1;
            padding: 14px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            display: inline-block;
            transition: opacity 0.3s;
        }
        .btn:hover { opacity: 0.9; }
        .btn-primary { background: linear-gradient(135deg, #42a5f5 0%, #1e88e5 100%); color: #fff; }
        .btn-cancel { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .error-msg {
            background: #ffebee;
            color: #c62828;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #c62828;
        }
        .info-msg {
            background: #e3f2fd;
            color: #1565c0;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #1565c0;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>教师工作台 - 修改成绩</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/teacher/score_list.jsp">返回列表</a>
        <a href="<%= ctx %>/teacher/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (loadError != null) { %>
    <div class="error-msg"><%= loadError %></div>
    <div style="text-align:center;margin-top:20px;">
        <a href="<%= ctx %>/teacher/score_list.jsp" class="btn btn-cancel">返回成绩列表</a>
    </div>
    <% } else if (scoreInfo != null) { %>
    <div class="form-card">
        <h2>修改成绩</h2>

        <% if (error != null) { %>
        <div class="error-msg"><%= error %></div>
        <% } %>

        <form action="<%= ctx %>/score/update" method="post">
            <input type="hidden" name="scoreId" value="<%= scoreInfo.get("score_id") %>">

            <div class="form-group">
                <label>学生姓名</label>
                <div class="readonly-value"><%= scoreInfo.get("student_name") %></div>
            </div>

            <div class="form-group">
                <label>学号</label>
                <div class="readonly-value"><%= scoreInfo.get("student_no") %></div>
            </div>

            <div class="form-group">
                <label>科目</label>
                <div class="readonly-value"><%= scoreInfo.get("subject_name") %></div>
            </div>

            <div class="form-group">
                <label>学期</label>
                <div class="readonly-value"><%= scoreInfo.get("semester_name") %></div>
            </div>

            <div class="form-group">
                <label>当前等级</label>
                <div class="readonly-value"><%= scoreInfo.get("grade_level") != null ? scoreInfo.get("grade_level") : "未评级" %></div>
            </div>

            <div class="form-group">
                <label for="newScore">新分数 <span style="color:#e53935;">*</span></label>
                <input type="number" id="newScore" name="newScore"
                       min="0" max="100" step="0.01"
                       value="<%= scoreInfo.get("score") %>"
                       placeholder="请输入新分数（0-100）" required>
            </div>

            <div class="btn-group">
                <button type="submit" class="btn btn-primary">保存修改</button>
                <a href="<%= ctx %>/teacher/score_list.jsp" class="btn btn-cancel">取 消</a>
            </div>
        </form>
    </div>
    <% } %>
</div>
</body>
</html>