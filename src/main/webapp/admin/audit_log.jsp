<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取 Servlet 传递的数据 ====================
    List<Map<String, Object>> logList = (List<Map<String, Object>>) request.getAttribute("logList");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Long totalRecords = (Long) request.getAttribute("totalRecords");
    String filterAction = (String) request.getAttribute("action");
    String filterStartDate = (String) request.getAttribute("startDate");
    String filterEndDate = (String) request.getAttribute("endDate");

    if (logList == null) logList = new ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (totalRecords == null) totalRecords = 0L;
    if (filterAction == null) filterAction = "";
    if (filterStartDate == null) filterStartDate = "";
    if (filterEndDate == null) filterEndDate = "";

    String ctx = request.getContextPath();

    // 构建筛选参数的查询字符串（用于分页链接）
    StringBuilder queryParams = new StringBuilder();
    if (!filterAction.isEmpty()) queryParams.append("&action=").append(filterAction);
    if (!filterStartDate.isEmpty()) queryParams.append("&startDate=").append(filterStartDate);
    if (!filterEndDate.isEmpty()) queryParams.append("&endDate=").append(filterEndDate);
    String queryStr = queryParams.toString();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>审计日志 - 管理员控制台</title>
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
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 12px;
        }
        .toolbar h2 { font-size: 18px; color: #333; }
        .record-count {
            font-size: 13px;
            color: #999;
        }

        /* 筛选栏 */
        .filter-bar {
            background: #fff;
            padding: 16px 20px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
            margin-bottom: 20px;
            display: flex;
            gap: 16px;
            align-items: center;
            flex-wrap: wrap;
        }
        .filter-bar label {
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        .filter-bar select,
        .filter-bar input[type="date"] {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .filter-bar select:focus,
        .filter-bar input:focus {
            outline: none;
            border-color: #667eea;
        }
        .btn-query {
            padding: 8px 20px;
            background: #667eea;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
        }
        .btn-query:hover { background: #5a6fd6; }
        .btn-reset {
            padding: 8px 20px;
            background: #f5f7fa;
            color: #555;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
        }
        .btn-reset:hover { background: #e3f2fd; }

        /* 表格 */
        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .data-table th {
            background: #f5f7fa;
            padding: 12px 14px;
            font-size: 13px;
            color: #666;
            font-weight: 600;
            text-align: center;
            border-bottom: 2px solid #e0e0e0;
            white-space: nowrap;
        }
        .data-table td {
            padding: 10px 14px;
            text-align: center;
            border-bottom: 1px solid #f0f0f0;
            color: #333;
        }
        .data-table tbody tr:nth-child(even) { background: #fafbfc; }
        .data-table tbody tr:hover { background: #eef0ff; }

        /* 操作类型标签 */
        .tag {
            display: inline-block;
            padding: 2px 10px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 600;
        }
        .tag-insert { background: #e8f5e9; color: #2e7d32; }
        .tag-update { background: #fff3e0; color: #e65100; }
        .tag-delete { background: #ffebee; color: #c62828; }

        /* 数据列 */
        .data-cell {
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            text-align: left;
            font-size: 12px;
            color: #666;
            cursor: help;
        }

        /* 空状态 */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 15px;
        }

        /* 分页 */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 6px;
            padding: 20px;
        }
        .pagination a,
        .pagination span {
            padding: 6px 14px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 13px;
            text-decoration: none;
            color: #555;
            transition: all 0.2s;
        }
        .pagination a:hover { background: #e8f0fe; border-color: #667eea; color: #667eea; }
        .pagination .active {
            background: #667eea;
            color: #fff;
            border-color: #667eea;
        }
        .pagination .disabled {
            color: #ccc;
            cursor: not-allowed;
            pointer-events: none;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>审计日志</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <div class="toolbar">
        <h2>审计日志</h2>
        <div class="record-count">共 <%= totalRecords %> 条记录</div>
    </div>

    <!-- 筛选栏 -->
    <form action="<%= ctx %>/admin/audit-log" method="get" id="filterForm">
        <div class="filter-bar">
            <label>操作类型：</label>
            <select name="action">
                <option value="">全部</option>
                <option value="INSERT" <% if ("INSERT".equals(filterAction)) { %>selected<% } %>>INSERT</option>
                <option value="UPDATE" <% if ("UPDATE".equals(filterAction)) { %>selected<% } %>>UPDATE</option>
                <option value="DELETE" <% if ("DELETE".equals(filterAction)) { %>selected<% } %>>DELETE</option>
            </select>
            <label>起始日期：</label>
            <input type="date" name="startDate" value="<%= filterStartDate %>">
            <label>结束日期：</label>
            <input type="date" name="endDate" value="<%= filterEndDate %>">
            <button type="submit" class="btn-query">查询</button>
            <a href="<%= ctx %>/admin/audit-log" class="btn-reset" style="display:inline-block;">重置</a>
        </div>
    </form>

    <!-- 表格 -->
    <div class="table-card">
        <table class="data-table">
            <thead>
            <tr>
                <th style="width:50px;">序号</th>
                <th style="width:80px;">操作类型</th>
                <th style="width:90px;">操作人</th>
                <th style="width:100px;">操作表</th>
                <th style="width:70px;">记录ID</th>
                <th style="width:220px;">修改前数据</th>
                <th style="width:220px;">修改后数据</th>
                <th style="width:160px;">操作时间</th>
            </tr>
            </thead>
            <tbody>
            <% if (logList.isEmpty()) { %>
            <tr>
                <td colspan="8" class="empty-state">暂无审计日志记录</td>
            </tr>
            <% } else {
                int startIndex = (currentPage - 1) * 15;
                for (int i = 0; i < logList.size(); i++) {
                    Map<String, Object> log = logList.get(i);
                    String actionType = (String) log.get("action");
                    String tableName = (String) log.get("table_name");
                    Object recordId = log.get("record_id");
                    String oldData = (String) log.get("old_data");
                    String newData = (String) log.get("new_data");
                    Object actionTime = log.get("created_at");
                    String timeStr = "";
                    if (actionTime != null) {
                        if (actionTime instanceof java.sql.Timestamp) {
                            timeStr = ((java.sql.Timestamp) actionTime).toString();
                        } else {
                            timeStr = actionTime.toString();
                        }
                    }

                    String tagClass = "tag-insert";
                    if ("UPDATE".equals(actionType)) tagClass = "tag-update";
                    else if ("DELETE".equals(actionType)) tagClass = "tag-delete";

                    String oldTitle = (oldData != null && oldData.length() > 0) ? oldData.replace("\"", "&quot;") : "";
                    String newTitle = (newData != null && newData.length() > 0) ? newData.replace("\"", "&quot;") : "";
            %>
            <tr>
                <td><%= startIndex + i + 1 %></td>
                <td><span class="tag <%= tagClass %>"><%= actionType %></span></td>
                <td><%= log.get("operator_name") != null ? escapeHtml(log.get("operator_name").toString()) : "系统" %></td>
                <td><%= tableName != null ? tableName : "-" %></td>
                <td><%= recordId != null ? recordId : "-" %></td>
                <td class="data-cell" title="<%= oldTitle %>" style="text-align:left;"><%= (oldData != null && !oldData.isEmpty()) ? escapeHtml(oldData) : "-" %></td>
                <td class="data-cell" title="<%= newTitle %>" style="text-align:left;"><%= (newData != null && !newData.isEmpty()) ? escapeHtml(newData) : "-" %></td>
                <td><%= timeStr %></td>
            </tr>
            <% }
            } %>
            </tbody>
        </table>

        <!-- 分页 -->
        <% if (totalPages > 1) { %>
        <div class="pagination">
            <% if (currentPage > 1) { %>
            <a href="<%= ctx %>/admin/audit-log?page=1<%= queryStr %>">首页</a>
            <a href="<%= ctx %>/admin/audit-log?page=<%= currentPage - 1 %><%= queryStr %>">上一页</a>
            <% } else { %>
            <span class="disabled">首页</span>
            <span class="disabled">上一页</span>
            <% } %>

            <%-- 页码按钮（最多显示 7 个） --%>
            <%
                int startPage = Math.max(1, currentPage - 3);
                int endPage = Math.min(totalPages, currentPage + 3);
                if (endPage - startPage < 6) {
                    if (startPage == 1) {
                        endPage = Math.min(totalPages, startPage + 6);
                    } else if (endPage == totalPages) {
                        startPage = Math.max(1, endPage - 6);
                    }
                }
                for (int p = startPage; p <= endPage; p++) {
                    if (p == currentPage) {
            %>
            <span class="active"><%= p %></span>
            <% } else { %>
            <a href="<%= ctx %>/admin/audit-log?page=<%= p %><%= queryStr %>"><%= p %></a>
            <% }
            } %>

            <% if (currentPage < totalPages) { %>
            <a href="<%= ctx %>/admin/audit-log?page=<%= currentPage + 1 %><%= queryStr %>">下一页</a>
            <a href="<%= ctx %>/admin/audit-log?page=<%= totalPages %><%= queryStr %>">末页</a>
            <% } else { %>
            <span class="disabled">下一页</span>
            <span class="disabled">末页</span>
            <% } %>
        </div>
        <% } %>
    </div>
</div>

<%!
    // JSP 声明：HTML 转义工具方法
    private String escapeHtml(String str) {
        if (str == null) return "";
        return str.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
%>
</body>
</html>
