<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="com.score.model.Student" %>
<%@ page import="com.score.model.Subject" %>
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

    // ==================== 加载下拉列表数据 ====================
    List<Student> students = new ArrayList<>();
    List<Subject> subjects = new ArrayList<>();
    List<Semester> semesters = new ArrayList<>();
    String loadError = null;

    try {
        students = DB.getStudentsByDepartment(currentUser.getDepartmentId());
        subjects = DB.getSubjects();
        semesters = DB.getSemesters();
    } catch (SQLException e) {
        loadError = "数据加载失败：" + e.getMessage();
    } finally {
        try { DB.closeConnection(); } catch (SQLException ignored) {}
    }

    // 获取 Servlet 传递的错误信息
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>录入成绩 - 教师工作台</title>
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
        .header h1 {
            font-size: 18px;
            font-weight: 500;
        }
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
        .header .nav-links a:hover {
            background: rgba(255,255,255,0.3);
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            padding: 0 20px;
        }
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
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        .form-group label .required {
            color: #e53935;
        }
        .form-group select,
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group select:focus,
        .form-group input:focus {
            outline: none;
            border-color: #42a5f5;
        }
        .btn-submit {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #42a5f5 0%, #1e88e5 100%);
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        .btn-submit:hover {
            opacity: 0.9;
        }
        .error-msg {
            background: #ffebee;
            color: #c62828;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #c62828;
        }
        .info-msg {
            background: #e3f2fd;
            color: #1565c0;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid #1565c0;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>教师工作台 - 录入成绩</h1>
    <div class="nav-links">
        <a href="<%= request.getContextPath() %>/teacher/index.jsp">返回首页</a>
        <a href="<%= request.getContextPath() %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <div class="form-card">
        <h2>录入学生成绩</h2>

        <% if (loadError != null) { %>
        <div class="error-msg"><%= loadError %></div>
        <% } %>
        <% if (error != null) { %>
        <div class="error-msg"><%= error %></div>
        <% } %>

        <% if (students.isEmpty()) { %>
        <div class="info-msg">当前系部下没有在读学生，无法录入成绩。</div>
        <% } else { %>
        <form action="<%= request.getContextPath() %>/score/input" method="post">
            <div class="form-group">
                <label for="studentId">学生 <span class="required">*</span></label>
                <select id="studentId" name="studentId" required>
                    <option value="">请选择学生</option>
                    <% for (Student s : students) { %>
                    <option value="<%= s.getId() %>">
                        <%= s.getName() %> (<%= s.getStudentNo() %>)
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="form-group">
                <label for="subjectId">科目 <span class="required">*</span></label>
                <select id="subjectId" name="subjectId" required>
                    <option value="">请选择科目</option>
                    <% for (Subject sub : subjects) { %>
                    <option value="<%= sub.getId() %>">
                        <%= sub.getSubjectName() %> (<%= sub.getSubjectCode() %>)
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="form-group">
                <label for="semesterId">学期 <span class="required">*</span></label>
                <select id="semesterId" name="semesterId" required>
                    <option value="">请选择学期</option>
                    <% for (Semester sem : semesters) { %>
                    <option value="<%= sem.getId() %>">
                        <%= sem.getSemesterName() %>
                        <%= sem.getIsCurrent() ? "【当前学期】" : "" %>
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="form-group">
                <label for="score">成绩 <span class="required">*</span></label>
                <input type="number" id="score" name="score" min="0" max="100" step="0.01"
                       placeholder="请输入成绩（0-100）" required>
            </div>

            <button type="submit" class="btn-submit">提交成绩</button>
        </form>
        <% } %>
    </div>
</div>
</body>
</html>