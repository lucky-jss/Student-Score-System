<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="com.score.util.PageResult" %>
<%@ page import="java.util.*" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取数据 ====================
    List<Map<String, Object>> subjectList = (List<Map<String, Object>>) request.getAttribute("subjectList");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Long totalRecords = (Long) request.getAttribute("totalRecords");

    if (subjectList == null) subjectList = new ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (totalRecords == null) totalRecords = 0L;

    // 操作结果消息
    String sessionSuccess = (String) session.getAttribute("success");
    String sessionError = (String) session.getAttribute("error");
    if (sessionSuccess != null) session.removeAttribute("success");
    if (sessionError != null) session.removeAttribute("error");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>科目管理 - 管理员控制台</title>
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
            max-width: 1000px;
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

        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .toolbar h2 { font-size: 18px; color: #333; }
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
        .btn-edit { background: #42a5f5; color: #fff; padding: 4px 12px; font-size: 13px; }
        .btn-delete { background: #e53935; color: #fff; padding: 4px 12px; font-size: 13px; }
        .btn-delete:hover { background: #c62828; }
        .btn-disabled { background: #ccc; color: #999; cursor: not-allowed; padding: 4px 12px; font-size: 13px; border: none; border-radius: 6px; }

        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        .table-card table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
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
            color: #333;
            text-align: center;
            border-bottom: 1px solid #f0f0f0;
        }
        .table-card tr:nth-child(even) { background: #fafbfc; }
        .table-card tr:hover { background: #e8f4fd; }
        .table-card tr.deleted { background: #f5f5f5; color: #999; }
        .table-card tr.deleted td { color: #999; }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 16px;
        }
        .status-normal { color: #2e7d32; font-weight: 500; }
        .status-deleted { color: #999; }

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
    </style>
</head>
<body>
<div class="header">
    <h1>管理员控制台 - 科目管理</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (sessionSuccess != null) { %>
    <div class="alert alert-success">&#10004; <%= sessionSuccess %></div>
    <% } %>
    <% if (sessionError != null) { %>
    <div class="alert alert-error">&#10008; <%= sessionError %></div>
    <% } %>

    <div class="toolbar">
        <h2>科目列表（共 <%= totalRecords %> 条）</h2>
        <a href="<%= ctx %>/admin/subjects?action=add" class="btn btn-primary">&#43; 添加科目</a>
    </div>

    <div class="table-card">
        <% if (subjectList.isEmpty()) { %>
        <div class="empty-state">暂无科目记录</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th style="width:50px;">序号</th>
                <th>科目编码</th>
                <th>科目名称</th>
                <th>学分</th>
                <th>所属系部</th>
                <th>状态</th>
                <th style="width:140px;">操作</th>
            </tr>
            </thead>
            <tbody>
            <% int idx = (currentPage - 1) * 10; %>
            <% for (Map<String, Object> row : subjectList) { %>
            <% idx++;
                Integer isDeleted = row.get("is_deleted") != null ? ((Number) row.get("is_deleted")).intValue() : 0;
                boolean deleted = isDeleted == 1;
            %>
            <tr class="<%= deleted ? "deleted" : "" %>">
                <td><%= idx %></td>
                <td><%= row.get("subject_code") %></td>
                <td><%= row.get("subject_name") %></td>
                <td><%= row.get("credit") %></td>
                <td><%= row.get("dept_name") != null ? row.get("dept_name") : "-" %></td>
                <td>
                    <% if (deleted) { %>
                    <span class="status-deleted">已删除</span>
                    <% } else { %>
                    <span class="status-normal">正常</span>
                    <% } %>
                </td>
                <td>
                    <% if (deleted) { %>
                    <button class="btn-disabled" disabled>编辑</button>
                    <button class="btn-disabled" disabled>删除</button>
                    <% } else { %>
                    <a href="<%= ctx %>/admin/subjects?action=edit&id=<%= row.get("id") %>" class="btn btn-edit">编辑</a>
                    <a href="javascript:void(0);" onclick="confirmDelete(<%= row.get("id") %>, '<%= row.get("subject_name") %>')" class="btn btn-delete">删除</a>
                    <% } %>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>

    <!-- 分页 -->
    <% if (totalPages > 1) { %>
    <div class="pagination">
        <% if (currentPage > 1) { %>
        <a href="<%= ctx %>/admin/subjects?page=1">首页</a>
        <a href="<%= ctx %>/admin/subjects?page=<%= currentPage - 1 %>">上一页</a>
        <% } else { %>
        <span class="disabled">首页</span>
        <span class="disabled">上一页</span>
        <% } %>

        <span class="current"><%= currentPage %> / <%= totalPages %></span>

        <% if (currentPage < totalPages) { %>
        <a href="<%= ctx %>/admin/subjects?page=<%= currentPage + 1 %>">下一页</a>
        <a href="<%= ctx %>/admin/subjects?page=<%= totalPages %>">末页</a>
        <% } else { %>
        <span class="disabled">下一页</span>
        <span class="disabled">末页</span>
        <% } %>
    </div>
    <% } %>
</div>

<script>
    function confirmDelete(subjectId, subjectName) {
        if (confirm('确定要删除科目【' + subjectName + '】吗？\n删除后该科目将被标记为已删除状态。')) {
            window.location.href = '<%= ctx %>/admin/subjects?action=delete&id=' + subjectId;
        }
    }
</script>
</body>
</html>
