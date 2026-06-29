<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="com.score.dao.DB" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.SQLException" %>
<%
    String error = (String) request.getAttribute("error");

    // 查询班级列表供选择
    List<Map<String, Object>> classList = new ArrayList<>();
    try {
        classList = DB.executeQuery(
                "SELECT c.id, c.class_name, m.major_name " +
                        "FROM classes c " +
                        "JOIN majors m ON c.major_id = m.id " +
                        "WHERE c.is_deleted = 0 " +
                        "ORDER BY c.class_code"
        );
    } catch (SQLException e) {
        // 忽略错误，班级列表为空时显示提示
    } finally {
        try { DB.closeConnection(); } catch (SQLException ignored) {}
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学生注册 - 学生成绩在线发布系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .register-container {
            background: #fff;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 450px;
        }
        .register-title {
            text-align: center;
            font-size: 22px;
            color: #333;
            margin-bottom: 8px;
        }
        .register-subtitle {
            text-align: center;
            font-size: 14px;
            color: #888;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 18px;
        }
        .form-group label {
            display: block;
            margin-bottom: 6px;
            font-size: 14px;
            color: #555;
        }
        .form-group label .required {
            color: #c00;
        }
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        .gender-group {
            display: flex;
            gap: 20px;
        }
        .gender-group label {
            display: flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            font-weight: normal;
        }
        .gender-group input[type="radio"] {
            width: auto;
        }
        .btn-register {
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
        .btn-register:hover {
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
        .login-link {
            text-align: center;
            margin-top: 20px;
            font-size: 14px;
            color: #666;
        }
        .login-link a {
            color: #667eea;
            text-decoration: none;
        }
        .login-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
<div class="register-container">
    <h1 class="register-title">学生注册</h1>
    <p class="register-subtitle">Student Registration</p>

    <% if (error != null) { %>
    <div class="error-msg"><%= error %></div>
    <% } %>

    <form action="<%= request.getContextPath() %>/register" method="post">
        <div class="form-group">
            <label for="studentNo">学号 <span class="required">*</span></label>
            <input type="text" id="studentNo" name="studentNo" placeholder="请输入学号" required>
        </div>
        <div class="form-group">
            <label for="name">姓名 <span class="required">*</span></label>
            <input type="text" id="name" name="name" placeholder="请输入真实姓名" required>
        </div>
        <div class="form-group">
            <label for="password">密码 <span class="required">*</span></label>
            <input type="password" id="password" name="password" placeholder="至少6位字符" required>
        </div>
        <div class="form-group">
            <label for="confirmPassword">确认密码 <span class="required">*</span></label>
            <input type="password" id="confirmPassword" name="confirmPassword" placeholder="请再次输入密码" required>
        </div>
        <div class="form-group">
            <label for="classId">所属班级 <span class="required">*</span></label>
            <select id="classId" name="classId" required>
                <option value="">请选择班级</option>
                <% for (Map<String, Object> c : classList) { %>
                <option value="<%= c.get("id") %>">
                    <%= c.get("class_name") %> (<%= c.get("major_name") %>)
                </option>
                <% } %>
            </select>
        </div>
        <div class="form-group">
            <label>性别 <span class="required">*</span></label>
            <div class="gender-group">
                <label>
                    <input type="radio" name="gender" value="男" required> 男
                </label>
                <label>
                    <input type="radio" name="gender" value="女" required> 女
                </label>
            </div>
        </div>
        <button type="submit" class="btn-register">注 册</button>
    </form>

    <div class="login-link">
        已有账号？<a href="<%= request.getContextPath() %>/login.jsp">立即登录</a>
    </div>
</div>
</body>
</html>