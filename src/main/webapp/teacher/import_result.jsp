<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"teacher".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取导入结果 ====================
    Integer successCount = (Integer) request.getAttribute("successCount");
    Integer failCount = (Integer) request.getAttribute("failCount");
    @SuppressWarnings("unchecked")
    List<String> errors = (List<String>) request.getAttribute("errors");

    if (successCount == null) successCount = 0;
    if (failCount == null) failCount = 0;
    if (errors == null) errors = new ArrayList<>();

    boolean hasErrors = !errors.isEmpty();
    boolean allSuccess = successCount > 0 && failCount == 0;

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>导入结果 - 教师工作台</title>
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
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
        }
        .result-card {
            background: #fff;
            padding: 32px;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.06);
            margin-bottom: 24px;
        }
        .result-card h2 {
            font-size: 20px;
            color: #333;
            margin-bottom: 24px;
            text-align: center;
        }
        .summary {
            display: flex;
            justify-content: center;
            gap: 40px;
            margin-bottom: 24px;
        }
        .summary-item {
            text-align: center;
            padding: 20px 30px;
            border-radius: 10px;
            min-width: 140px;
        }
        .summary-item .number {
            font-size: 32px;
            font-weight: 600;
            margin-bottom: 6px;
        }
        .summary-item .label {
            font-size: 14px;
            color: #666;
        }
        .bg-success { background: #e8f5e9; }
        .bg-success .number { color: #2e7d32; }
        .bg-fail { background: #ffebee; }
        .bg-fail .number { color: #c62828; }
        .status-msg {
            text-align: center;
            font-size: 15px;
            padding: 14px;
            border-radius: 8px;
            margin-bottom: 24px;
        }
        .status-all-success { background: #e8f5e9; color: #2e7d32; }
        .status-partial { background: #fff8e1; color: #f57f17; }
        .status-fail { background: #ffebee; color: #c62828; }
        .error-section h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 12px;
        }
        .error-list {
            list-style: none;
            background: #fafbfc;
            border: 1px solid #f0f0f0;
            border-radius: 8px;
            max-height: 360px;
            overflow-y: auto;
            padding: 12px 16px;
        }
        .error-list li {
            padding: 8px 0;
            font-size: 13px;
            color: #c62828;
            border-bottom: 1px solid #f0f0f0;
        }
        .error-list li:last-child { border-bottom: none; }
        .actions {
            text-align: center;
            margin-top: 24px;
        }
        .actions a {
            display: inline-block;
            padding: 10px 24px;
            background: #42a5f5;
            color: #fff;
            text-decoration: none;
            border-radius: 6px;
            font-size: 14px;
            margin: 0 8px;
            transition: background 0.3s;
        }
        .actions a:hover { background: #1e88e5; }
        .actions a.secondary {
            background: #f5f7fa;
            color: #555;
            border: 1px solid #ddd;
        }
        .actions a.secondary:hover { background: #e3f2fd; }
    </style>
</head>
<body>
<div class="header">
    <h1>导入结果</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/teacher/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <div class="result-card">
        <h2>成绩导入完成</h2>

        <div class="summary">
            <div class="summary-item bg-success">
                <div class="number"><%= successCount %></div>
                <div class="label">导入成功</div>
            </div>
            <div class="summary-item bg-fail">
                <div class="number"><%= failCount %></div>
                <div class="label">导入失败</div>
            </div>
        </div>

        <% if (allSuccess) { %>
        <div class="status-msg status-all-success">
            &#10004; 全部 <%= successCount %> 条成绩导入成功！
        </div>
        <% } else if (successCount > 0 && failCount > 0) { %>
        <div class="status-msg status-partial">
            &#9888; 部分导入成功，共有 <%= failCount %> 条记录失败，请查看下方错误明细。
        </div>
        <% } else if (failCount > 0) { %>
        <div class="status-msg status-fail">
            &#10008; 导入失败，共有 <%= failCount %> 条记录未导入，请查看下方错误明细。
        </div>
        <% } else { %>
        <div class="status-msg status-partial">
            未检测到有效数据行，请检查 CSV 文件内容。
        </div>
        <% } %>

        <% if (hasErrors) { %>
        <div class="error-section">
            <h3>错误明细（共 <%= errors.size() %> 条）</h3>
            <ul class="error-list">
                <% for (String err : errors) { %>
                <li><%= err %></li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <div class="actions">
            <a href="<%= ctx %>/teacher/import_score.jsp">继续导入</a>
            <a href="<%= ctx %>/teacher/score_list.jsp" class="secondary">查看成绩列表</a>
        </div>
    </div>
</div>
</body>
</html>
