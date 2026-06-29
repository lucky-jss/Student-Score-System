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

    // ==================== 获取数据 ====================
    Boolean isEdit = (Boolean) request.getAttribute("isEdit");
    Map<String, Object> subject = (Map<String, Object>) request.getAttribute("subject");
    List<Map<String, Object>> departments = (List<Map<String, Object>>) request.getAttribute("departments");
    String error = (String) request.getAttribute("error");

    if (isEdit == null) isEdit = false;
    if (departments == null) departments = new ArrayList<>();

    // 编辑模式回显数据
    Integer subjectId = null;
    String subjectCode = "";
    String subjectName = "";
    String credit = "";
    Integer selectedDeptId = null;

    if (isEdit && subject != null) {
        subjectId = (Integer) subject.get("id");
        subjectCode = (String) subject.get("subject_code");
        subjectName = (String) subject.get("subject_name");
        credit = subject.get("credit") != null ? subject.get("credit").toString() : "";
        selectedDeptId = (Integer) subject.get("department_id");
    }

    // 校验失败时的表单回显（优先使用 request 中的值）
    String reqId = (String) request.getAttribute("id");
    String reqCode = (String) request.getAttribute("subjectCode");
    String reqName = (String) request.getAttribute("subjectName");
    String reqCredit = (String) request.getAttribute("credit");
    String reqDeptId = (String) request.getAttribute("departmentId");

    if (reqCode != null) subjectCode = reqCode;
    if (reqName != null) subjectName = reqName;
    if (reqCredit != null) credit = reqCredit;
    if (reqDeptId != null) selectedDeptId = Integer.parseInt(reqDeptId);
    if (reqId != null) {
        isEdit = true;
        subjectId = Integer.parseInt(reqId);
    }

    String ctx = request.getContextPath();
    String pageTitle = isEdit ? "编辑科目" : "添加科目";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %> - 管理员控制台</title>
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
            max-width: 600px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .form-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            padding: 30px;
        }
        .form-card h2 {
            font-size: 18px;
            color: #333;
            margin-bottom: 24px;
            padding-bottom: 12px;
            border-bottom: 1px solid #f0f0f0;
        }
        .alert-error {
            padding: 12px 18px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            background: #ffebee;
            color: #c62828;
            border-left: 4px solid #e53935;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            font-size: 14px;
            color: #555;
            margin-bottom: 8px;
            font-weight: 500;
        }
        .form-group label .required {
            color: #e53935;
            margin-left: 4px;
        }
        .form-group input[type="text"],
        .form-group input[type="number"],
        .form-group select {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            font-family: inherit;
        }
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        .form-actions {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
        }
        .btn {
            padding: 10px 24px;
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
        .btn-secondary { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
    </style>
</head>
<body>
<div class="header">
    <h1>管理员控制台 - <%= pageTitle %></h1>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/subjects">返回列表</a>
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <div class="form-card">
        <h2><%= pageTitle %></h2>

        <% if (error != null) { %>
        <div class="alert alert-error">&#10008; <%= error %></div>
        <% } %>

        <form action="<%= ctx %>/admin/subjects" method="post">
            <% if (isEdit && subjectId != null) { %>
            <input type="hidden" name="id" value="<%= subjectId %>">
            <% } %>

            <div class="form-group">
                <label>科目编码 <span class="required">*</span></label>
                <input type="text" name="subjectCode" value="<%= subjectCode %>" placeholder="如 CS105" required>
            </div>

            <div class="form-group">
                <label>科目名称 <span class="required">*</span></label>
                <input type="text" name="subjectName" value="<%= subjectName %>" placeholder="如 数据库原理" required>
            </div>

            <div class="form-group">
                <label>学分 <span class="required">*</span></label>
                <input type="number" name="credit" value="<%= credit %>" step="0.5" min="0.5" placeholder="如 3.5" required>
            </div>

            <div class="form-group">
                <label>所属系部 <span class="required">*</span></label>
                <select name="departmentId" required>
                    <option value="">请选择系部</option>
                    <% for (Map<String, Object> d : departments) { %>
                    <option value="<%= d.get("id") %>" <%= selectedDeptId != null && selectedDeptId.equals(d.get("id")) ? "selected" : "" %>>
                        <%= d.get("dept_name") %>
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="form-actions">
                <button type="submit" class="btn btn-primary"><%= isEdit ? "保存修改" : "确认添加" %></button>
                <a href="<%= ctx %>/admin/subjects" class="btn btn-secondary">取消</a>
            </div>
        </form>
    </div>
</div>
</body>
</html>
