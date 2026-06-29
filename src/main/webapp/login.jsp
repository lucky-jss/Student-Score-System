<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
    // 如果已登录，根据角色重定向到对应首页
    String role = (String) session.getAttribute("role");
    if (role != null) {
        switch (role) {
            case "admin":
                response.sendRedirect(request.getContextPath() + "/admin/index.jsp");
                return;
            case "teacher":
                response.sendRedirect(request.getContextPath() + "/teacher/index.jsp");
                return;
            case "student":
                response.sendRedirect(request.getContextPath() + "/student/index.jsp");
                return;
        }
    }

    String error = (String) request.getAttribute("error");
    String success = (String) session.getAttribute("success");
    if (success != null) {
        session.removeAttribute("success");
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学生成绩在线发布系统 - 登录</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .login-container {
            background: #fff;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 400px;
        }
        .login-title {
            text-align: center;
            font-size: 24px;
            color: #333;
            margin-bottom: 8px;
        }
        .login-subtitle {
            text-align: center;
            font-size: 14px;
            color: #888;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 6px;
            font-size: 14px;
            color: #555;
        }
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        .role-hint {
            background: #f5f7fa;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 13px;
            color: #666;
            line-height: 1.6;
        }
        .role-hint strong {
            color: #333;
        }
        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        .btn-login:hover {
            opacity: 0.9;
        }
        .error-msg {
            background: #fff0f0;
            color: #c00;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #c00;
        }
        .success-msg {
            background: #f0fff0;
            color: #0a0;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #0a0;
        }
        .register-link {
            text-align: center;
            margin-top: 20px;
            font-size: 14px;
            color: #666;
        }
        .register-link a {
            color: #667eea;
            text-decoration: none;
        }
        .register-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
<div class="login-container">
    <h1 class="login-title">学生成绩在线发布系统</h1>
    <p class="login-subtitle">Score Management System</p>

    <% if (error != null) { %>
    <div class="error-msg"><%= error %></div>
    <% } %>
    <% if (success != null) { %>
    <div class="success-msg"><%= success %></div>
    <% } %>

    <div class="role-hint">
        <strong>登录说明：</strong><br>
        学生：请使用学号登录<br>
        教师/管理员：请使用用户名登录
    </div>

    <form action="<%= request.getContextPath() %>/login" method="post">
        <div class="form-group">
            <label for="username">用户名 / 学号</label>
            <input type="text" id="username" name="username" placeholder="请输入用户名或学号" required>
        </div>
        <div class="form-group">
            <label for="password">密码</label>
            <input type="password" id="password" name="password" placeholder="请输入密码" required>
        </div>
        <button type="submit" class="btn-login">登 录</button>
    </form>

    <div class="register-link">
        还没有账号？<a href="<%= request.getContextPath() %>/register.jsp">学生注册</a>
    </div>
</div>
</body>
</html>