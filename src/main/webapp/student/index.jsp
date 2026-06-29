<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.Student" %>
<%
    // 权限校验：只有学生能访问
    String role = (String) session.getAttribute("role");
    Student student = (Student) session.getAttribute("student");
    String realName = (String) session.getAttribute("realName");
    if (!"student".equals(role) || student == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    if (realName == null) realName = "同学";

    String success = (String) session.getAttribute("success");
    String error = (String) session.getAttribute("error");
    if (success != null) session.removeAttribute("success");
    if (error != null) session.removeAttribute("error");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学生首页 - 学生成绩在线发布系统</title>
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
        .header h1 { font-size: 20px; font-weight: 500; }
        .header .user-info {
            display: flex;
            align-items: center;
            gap: 20px;
            font-size: 14px;
        }
        .header .user-info a {
            color: #fff;
            text-decoration: none;
            padding: 6px 16px;
            background: rgba(255,255,255,0.2);
            border-radius: 4px;
            transition: background 0.3s;
        }
        .header .user-info a:hover { background: rgba(255,255,255,0.3); }
        .container {
            max-width: 1200px;
            margin: 40px auto;
            padding: 0 20px;
        }
        .welcome {
            background: #fff;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.06);
            margin-bottom: 30px;
        }
        .welcome h2 { font-size: 22px; color: #333; margin-bottom: 8px; }
        .welcome p { color: #888; font-size: 14px; }
        .alert {
            padding: 14px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }
        .info-card {
            background: #fff;
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.06);
            margin-bottom: 20px;
        }
        .info-card h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .info-row {
            display: flex;
            padding: 10px 0;
            border-bottom: 1px solid #f5f5f5;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { width: 100px; color: #888; font-size: 14px; }
        .info-value { flex: 1; color: #333; font-size: 14px; }
        .menu-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 20px;
        }
        .menu-card {
            background: #fff;
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.06);
            transition: transform 0.3s, box-shadow 0.3s;
            cursor: pointer;
            text-decoration: none;
            color: inherit;
            display: block;
        }
        .menu-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.1);
        }
        .menu-card .icon {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            margin-bottom: 16px;
        }
        .menu-card h3 { font-size: 16px; color: #333; margin-bottom: 6px; }
        .menu-card p { font-size: 13px; color: #999; line-height: 1.5; }
        .bg-blue { background: #e8f0fe; }
        .bg-green { background: #e6f7ed; }
        .bg-orange { background: #fff2e8; }
    </style>
</head>
<body>
<div class="header">
    <h1>学生成绩在线发布系统</h1>
    <div class="user-info">
        <span>欢迎，<%= realName %></span>
        <a href="<%= request.getContextPath() %>/change_password.jsp">修改密码</a>
        <a href="<%= request.getContextPath() %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (success != null) { %>
    <div class="alert alert-success">&#10004; <%= success %></div>
    <% } %>
    <% if (error != null) { %>
    <div class="alert alert-error">&#10008; <%= error %></div>
    <% } %>

    <div class="welcome">
        <h2>学生个人中心</h2>
        <p>您可以在此查询自己的各科成绩和个人信息</p>
    </div>

    <div class="info-card">
        <h3>基本信息</h3>
        <div class="info-row">
            <div class="info-label">学号</div>
            <div class="info-value"><%= student.getStudentNo() %></div>
        </div>
        <div class="info-row">
            <div class="info-label">姓名</div>
            <div class="info-value"><%= student.getName() %></div>
        </div>
        <div class="info-row">
            <div class="info-label">性别</div>
            <div class="info-value"><%= student.getGender() %></div>
        </div>
        <div class="info-row">
            <div class="info-label">班级ID</div>
            <div class="info-value"><%= student.getClassId() %></div>
        </div>
    </div>

    <div class="menu-grid">
        <a href="<%= request.getContextPath() %>/student/query" class="menu-card">
            <div class="icon bg-blue">&#128218;</div>
            <h3>成绩查询</h3>
            <p>查询各学期各科成绩，查看分数、等级和排名</p>
        </a>
        <a href="<%= request.getContextPath() %>/student/statistics.jsp" class="menu-card">
            <div class="icon bg-green">&#128202;</div>
            <h3>成绩统计</h3>
            <p>查看个人成绩分布、排名和绩点情况</p>
        </a>
        <a href="#" class="menu-card">
            <div class="icon bg-orange">&#128196;</div>
            <h3>成绩单打印</h3>
            <p>打印个人成绩单和成绩证明</p>
        </a>
    </div>
</div>
</body>
</html>