<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="com.score.model.Semester" %>
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

    // ==================== 加载学期列表 ====================
    List<Semester> semesters = new ArrayList<>();
    String loadError = null;
    try {
        semesters = DB.getSemesters();
    } catch (SQLException e) {
        loadError = "数据加载失败：" + e.getMessage();
    } finally {
        try { DB.closeConnection(); } catch (SQLException ignored) {}
    }

    // 获取操作结果信息
    String error = (String) session.getAttribute("error");
    if (error != null) session.removeAttribute("error");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>批量导入成绩 - 教师工作台</title>
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
            margin-left: 20px;
            font-size: 14px;
            padding: 6px 14px;
            background: rgba(255,255,255,0.2);
            border-radius: 4px;
            transition: background 0.3s;
        }
        .header .nav-links a:hover { background: rgba(255,255,255,0.3); }
        .container {
            max-width: 640px;
            margin: 40px auto;
            padding: 0 20px;
        }
        .alert {
            padding: 14px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }
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
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        .form-group label .required { color: #e53935; }
        .form-group select,
        .form-group input[type="file"] {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            background: #fff;
            transition: border-color 0.3s;
        }
        .form-group select:focus,
        .form-group input[type="file"]:focus {
            outline: none;
            border-color: #42a5f5;
        }
        .hint-box {
            background: #f5f7fa;
            border-left: 4px solid #42a5f5;
            padding: 16px;
            border-radius: 6px;
            margin-bottom: 24px;
            font-size: 13px;
            color: #555;
            line-height: 1.8;
        }
        .hint-box h4 {
            font-size: 14px;
            color: #333;
            margin-bottom: 8px;
        }
        .hint-box code {
            background: #e3f2fd;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: Consolas, monospace;
            color: #1565c0;
        }
        .hint-box a {
            color: #1e88e5;
            text-decoration: none;
        }
        .hint-box a:hover { text-decoration: underline; }
        .btn-submit {
            width: 100%;
            padding: 12px;
            background: #42a5f5;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            cursor: pointer;
            transition: background 0.3s;
        }
        .btn-submit:hover { background: #1e88e5; }
    </style>
</head>
<body>
<div class="header">
    <h1>批量导入成绩</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/teacher/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (error != null) { %>
    <div class="alert alert-error">&#10008; <%= error %></div>
    <% } %>

    <div class="form-card">
        <h2>上传成绩 CSV 文件</h2>

        <div class="hint-box">
            <h4>CSV 格式说明</h4>
            <p>1. 文件格式为 <code>.csv</code>，编码建议为 UTF-8。</p>
            <p>2. 第一行为表头，固定为：<code>student_no,subject_code,score</code></p>
            <p>3. 从第二行开始为数据行，每行一条成绩记录。</p>
            <p>4. 分数必须为 0-100 之间的数字。</p>
            <p>5. 如该学生该科目该学期已存在成绩，将自动更新。</p>
            <p style="margin-top:8px;">
                <a href="<%= ctx %>/score/import?action=template">&#128229; 下载标准模板</a>
            </p>
        </div>

        <form action="<%= ctx %>/score/import" method="post" enctype="multipart/form-data">
            <div class="form-group">
                <label for="semesterId">选择学期 <span class="required">*</span></label>
                <select name="semesterId" id="semesterId" required>
                    <option value="">-- 请选择学期 --</option>
                    <% for (Semester sem : semesters) { %>
                    <option value="<%= sem.getId() %>"><%= sem.getSemesterName() %></option>
                    <% } %>
                </select>
            </div>

            <div class="form-group">
                <label for="csvFile">选择 CSV 文件 <span class="required">*</span></label>
                <input type="file" name="csvFile" id="csvFile" accept=".csv" required>
            </div>

            <button type="submit" class="btn-submit">开始导入</button>
        </form>
    </div>
</div>
</body>
</html>
