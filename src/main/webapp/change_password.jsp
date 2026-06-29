<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>

<%
    // ==================== 权限检查：所有已登录用户均可访问 ====================
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    String realName = (String) session.getAttribute("realName");
    if (realName == null) realName = currentUser.getRealName();

    String error = (String) request.getAttribute("error");
    String ctx = request.getContextPath();

    // 根据角色确定首页和返回链接
    String homeUrl;
    String roleLabel;
    switch (role != null ? role : "") {
        case "admin": homeUrl = ctx + "/admin/index.jsp"; roleLabel = "管理员"; break;
        case "teacher": homeUrl = ctx + "/teacher/index.jsp"; roleLabel = "教师"; break;
        case "student": homeUrl = ctx + "/student/index.jsp"; roleLabel = "学生"; break;
        default: homeUrl = ctx + "/login.jsp"; roleLabel = "用户";
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>修改密码 - 学生成绩在线发布系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", "PingFang SC", sans-serif; background: #f5f7fa; min-height: 100vh; display: flex; flex-direction: column; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 16px 40px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header h1 { font-size: 18px; font-weight: 500; }
        .header .nav-links a { color: #fff; text-decoration: none; margin-left: 16px; font-size: 14px; padding: 6px 14px; background: rgba(255,255,255,0.2); border-radius: 4px; transition: background 0.3s; }
        .header .nav-links a:hover { background: rgba(255,255,255,0.3); }
        .main { flex: 1; display: flex; align-items: center; justify-content: center; }
        .form-card { background: #fff; border-radius: 10px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); padding: 36px; width: 100%; max-width: 420px; }
        .form-card h2 { font-size: 18px; color: #333; margin-bottom: 6px; }
        .form-card .subtitle { font-size: 14px; color: #999; margin-bottom: 24px; }
        .alert-error { padding: 12px 16px; border-radius: 6px; margin-bottom: 20px; font-size: 14px; background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; font-size: 14px; color: #555; margin-bottom: 8px; font-weight: 500; }
        .form-group input { width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; font-family: inherit; }
        .form-group input:focus { outline: none; border-color: #667eea; }
        .form-actions { display: flex; gap: 12px; margin-top: 24px; padding-top: 20px; border-top: 1px solid #f0f0f0; }
        .btn { padding: 10px 24px; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; text-decoration: none; display: inline-block; transition: opacity 0.3s; }
        .btn:hover { opacity: 0.85; }
        .btn-primary { background: #667eea; color: #fff; }
        .btn-secondary { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .help-text { font-size: 12px; color: #999; margin-top: 6px; }
    </style>
</head>
<body>
<div class="header">
    <h1>修改密码</h1>
    <div class="nav-links">
        <a href="<%= homeUrl %>">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="main">
    <div class="form-card">
        <h2>修改密码</h2>
        <p class="subtitle"><%= roleLabel %>： <%= realName %></p>

        <% if (error != null) { %>
        <div class="alert-error">&#10008; <%= error %></div>
        <% } %>

        <form action="<%= ctx %>/change-password" method="post">
            <div class="form-group">
                <label>当前密码</label>
                <input type="password" name="currentPassword" placeholder="请输入当前密码" required>
            </div>

            <div class="form-group">
                <label>新密码</label>
                <input type="password" name="newPassword" placeholder="请输入新密码（至少6位）" required>
                <div class="help-text">密码长度不能少于 6 位</div>
            </div>

            <div class="form-group">
                <label>确认新密码</label>
                <input type="password" name="confirmPassword" placeholder="请再次输入新密码" required>
            </div>

            <div class="form-actions">
                <button type="submit" class="btn btn-primary">确认修改</button>
                <a href="<%= homeUrl %>" class="btn btn-secondary">取消</a>
            </div>
        </form>
    </div>
</div>
</body>
</html>
