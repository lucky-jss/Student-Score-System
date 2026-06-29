<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
    // 权限校验：只有管理员能访问
    String role = (String) session.getAttribute("role");
    String realName = (String) session.getAttribute("realName");
    if (!"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    if (realName == null) realName = "管理员";

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
    <title>管理员首页 - 学生成绩在线发布系统</title>
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
        .bg-cyan { background: #e8faff; }
        .bg-indigo { background: #e8e8fe; }
        .bg-olive { background: #f0f0e0; }
        .alert {
            padding: 14px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }
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
        <h2>管理员控制台</h2>
        <p>您可以在此管理系统设置、用户管理、科目管理等全部功能</p>
    </div>

    <div class="menu-grid">
        <a href="#" class="menu-card">
            <div class="icon bg-blue">&#128187;</div>
            <h3>系部管理</h3>
            <p>添加、修改、删除系部信息，维护学校组织架构</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/subjects" class="menu-card">
            <div class="icon bg-green">&#128218;</div>
            <h3>科目管理</h3>
            <p>维护考试科目列表，设置学分和开课系部</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/users" class="menu-card">
            <div class="icon bg-orange">&#128104;&#8205;&#127979;</div>
            <h3>用户管理</h3>
            <p>管理系统用户账号，分配教师角色和所属系部</p>
        </a>
        <a href="#" class="menu-card">
            <div class="icon bg-purple">&#128197;</div>
            <h3>学期设置</h3>
            <p>维护学期列表，设置当前学期，管理学期时间范围</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/grading" class="menu-card">
            <div class="icon bg-red">&#9881;</div>
            <h3>等级分值设置</h3>
            <p>配置各科目各学期的等级分值对应规则</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/scores" class="menu-card">
            <div class="icon bg-cyan">&#128202;</div>
            <h3>成绩管理</h3>
            <p>查看全校成绩列表，支持多条件筛选、导出和打印</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/statistics.jsp" class="menu-card">
            <div class="icon bg-indigo">&#128200;</div>
            <h3>统计看板</h3>
            <p>查看系部、专业、班级、科目等维度的成绩统计与排名分析</p>
        </a>
        <a href="<%= request.getContextPath() %>/admin/audit-log" class="menu-card">
            <div class="icon bg-olive">&#128203;</div>
            <h3>审计日志</h3>
            <p>查看系统操作审计记录，追踪成绩增删改及用户变更</p>
        </a>
    </div>
</div>
</body>
</html>