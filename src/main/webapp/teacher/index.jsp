<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
    // 权限校验：只有教师能访问
    String role = (String) session.getAttribute("role");
    String realName = (String) session.getAttribute("realName");
    if (!"teacher".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    if (realName == null) realName = "教师";

    // 获取操作结果信息
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
    <title>教师首页 - 学生成绩在线发布系统</title>
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
        .bg-purple { background: #f0e8fe; }
        .bg-red { background: #ffe8e8; }
        .bg-teal { background: #e0f7fa; }
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
        <h2>教师工作台</h2>
        <p>您可以在此录入、修改、删除成绩，查看统计信息</p>
    </div>

    <div class="menu-grid">
        <a href="<%= request.getContextPath() %>/teacher/input_score.jsp" class="menu-card">
            <div class="icon bg-blue">&#9997;</div>
            <h3>成绩录入</h3>
            <p>为学生手动录入各科成绩</p>
        </a>
        <a href="<%= request.getContextPath() %>/teacher/import_score.jsp" class="menu-card">
            <div class="icon bg-teal">&#128228;</div>
            <h3>批量导入成绩</h3>
            <p>通过上传 CSV 文件批量录入或更新成绩</p>
        </a>
        <a href="<%= request.getContextPath() %>/teacher/score_list.jsp" class="menu-card">
            <div class="icon bg-green">&#128221;</div>
            <h3>成绩管理</h3>
            <p>查看、修改、删除已录入的成绩记录</p>
        </a>
        <a href="<%= request.getContextPath() %>/teacher/statistics.jsp" class="menu-card">
            <div class="icon bg-orange">&#128202;</div>
            <h3>成绩统计</h3>
            <p>按系部、专业、班级分类汇总统计成绩分布</p>
        </a>
    </div>
</div>
</body>
</html>