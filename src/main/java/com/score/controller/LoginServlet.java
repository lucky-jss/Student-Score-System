package com.score.controller;

import com.score.dao.DB;
import com.score.model.User;
import com.score.model.Student;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 登录 Servlet，支持教师/管理员登录和学生登录。
 * 访问路径：/login
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // GET 请求直接转发到登录页面
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty() || password == null || password.isEmpty()) {
            req.setAttribute("error", "用户名和密码不能为空");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        username = username.trim();

        try {
            // 先尝试在 users 表中查找（教师/管理员）
            User user = findUser(username);
            if (user != null) {
                // 验证密码（明文比对）
                if (password.equals(user.getPasswordHash())) {
                    // 密码验证通过
                    HttpSession session = req.getSession();
                    session.setAttribute("user", user);
                    session.setAttribute("role", user.getRole());
                    session.setAttribute("realName", user.getRealName());

                    // 更新最后登录时间
                    DB.executeUpdate("UPDATE users SET last_login_at = NOW() WHERE id = ?", user.getId());

                    // 设置 MySQL 会话变量，供触发器记录操作人
                    DB.executeUpdate("SET @current_user_id = ?", user.getId());

                    // 根据角色跳转
                    String target = switch (user.getRole()) {
                        case "admin" -> "/admin/index.jsp";
                        case "teacher" -> "/teacher/index.jsp";
                        default -> "/login.jsp";
                    };
                    resp.sendRedirect(req.getContextPath() + target);
                    return;
                } else {
                    req.setAttribute("error", "密码错误");
                    req.getRequestDispatcher("/login.jsp").forward(req, resp);
                    return;
                }
            }

            // users 表中未找到，尝试在 students 表中查找（学生登录）
            Student student = findStudent(username);
            if (student != null) {
                // 验证密码（明文比对）
                if (password.equals(student.getPasswordHash())) {
                    // 学生密码验证通过
                    HttpSession session = req.getSession();
                    session.setAttribute("student", student);
                    session.setAttribute("role", "student");
                    session.setAttribute("realName", student.getName());

                    resp.sendRedirect(req.getContextPath() + "/student/index.jsp");
                    return;
                } else {
                    req.setAttribute("error", "密码错误");
                    req.getRequestDispatcher("/login.jsp").forward(req, resp);
                    return;
                }
            }

            // 用户名不存在
            req.setAttribute("error", "用户名或学号不存在");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * 在 users 表中查找用户。
     *
     * @param username 用户名
     * @return User 对象，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    private User findUser(String username) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT id, username, password_hash, real_name, role, department_id, status, last_login_at " +
                        "FROM users WHERE username = ? AND is_deleted = 0 AND status = 1",
                username
        );
        if (rows.isEmpty()) {
            return null;
        }
        Map<String, Object> row = rows.get(0);
        User user = new User();
        user.setId((Integer) row.get("id"));
        user.setUsername((String) row.get("username"));
        user.setPasswordHash((String) row.get("password_hash"));
        user.setRealName((String) row.get("real_name"));
        user.setRole((String) row.get("role"));
        user.setDepartmentId((Integer) row.get("department_id"));
        user.setStatus((Integer) row.get("status"));
        Object lastLogin = row.get("last_login_at");
        if (lastLogin != null) {
            if (lastLogin instanceof java.sql.Timestamp) {
                user.setLastLoginAt(((java.sql.Timestamp) lastLogin).toLocalDateTime());
            } else if (lastLogin instanceof java.time.LocalDateTime) {
                user.setLastLoginAt((java.time.LocalDateTime) lastLogin);
            } else {
                user.setLastLoginAt(null);
            }
        } else {
            user.setLastLoginAt(null);
        }
        return user;
    }

    /**
     * 在 students 表中查找学生。
     *
     * @param studentNo 学号
     * @return Student 对象，未找到返回 null
     * @throws SQLException 查询失败时抛出
     */
    private Student findStudent(String studentNo) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT id, student_no, name, class_id, password_hash, gender, birth_date, phone, email, status " +
                        "FROM students WHERE student_no = ? AND is_deleted = 0 AND status = 1",
                studentNo
        );
        if (rows.isEmpty()) {
            return null;
        }
        Map<String, Object> row = rows.get(0);
        Student student = new Student();
        student.setId((Integer) row.get("id"));
        student.setStudentNo((String) row.get("student_no"));
        student.setName((String) row.get("name"));
        student.setClassId((Integer) row.get("class_id"));
        student.setPasswordHash((String) row.get("password_hash"));
        student.setGender((String) row.get("gender"));
        if (row.get("birth_date") != null) {
            student.setBirthDate(((java.sql.Date) row.get("birth_date")).toLocalDate());
        }
        student.setPhone((String) row.get("phone"));
        student.setEmail((String) row.get("email"));
        student.setStatus((Integer) row.get("status"));
        return student;
    }
}