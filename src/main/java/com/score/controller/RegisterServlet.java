package com.score.controller;

import com.score.dao.DB;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 学生注册 Servlet。
 * 访问路径：/register
 */
@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // GET 请求直接转发到注册页面
        req.getRequestDispatcher("/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String studentNo = req.getParameter("studentNo");
        String name = req.getParameter("name");
        String password = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");
        String classIdStr = req.getParameter("classId");
        String gender = req.getParameter("gender");

        // 基础校验
        if (studentNo == null || studentNo.trim().isEmpty()
                || name == null || name.trim().isEmpty()
                || password == null || password.isEmpty()
                || confirmPassword == null || confirmPassword.isEmpty()
                || classIdStr == null || classIdStr.isEmpty()
                || gender == null || gender.isEmpty()) {
            req.setAttribute("error", "所有字段均为必填项");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        studentNo = studentNo.trim();
        name = name.trim();

        // 密码一致性校验
        if (!password.equals(confirmPassword)) {
            req.setAttribute("error", "两次输入的密码不一致");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // 密码长度校验
        if (password.length() < 6) {
            req.setAttribute("error", "密码长度不能少于 6 位");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        int classId;
        try {
            classId = Integer.parseInt(classIdStr);
        } catch (NumberFormatException e) {
            req.setAttribute("error", "班级选择无效");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        try {
            // 检查学号是否已存在
            if (isStudentNoExists(studentNo)) {
                req.setAttribute("error", "学号已存在，请直接登录");
                req.getRequestDispatcher("/register.jsp").forward(req, resp);
                return;
            }

            // BCrypt 加密密码
            String passwordHash = BCrypt.hashpw(password, BCrypt.gensalt(12));

            // 插入学生记录
            int rows = DB.executeUpdate(
                    "INSERT INTO students (student_no, name, class_id, password_hash, gender, status) " +
                            "VALUES (?, ?, ?, ?, ?, 1)",
                    studentNo, name, classId, passwordHash, gender
            );

            if (rows > 0) {
                // 注册成功，重定向到登录页并携带成功消息
                req.getSession().setAttribute("success", "注册成功，请登录");
                resp.sendRedirect(req.getContextPath() + "/login.jsp");
            } else {
                req.setAttribute("error", "注册失败，请稍后重试");
                req.getRequestDispatcher("/register.jsp").forward(req, resp);
            }

        } catch (SQLException e) {
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * 检查学号是否已存在。
     *
     * @param studentNo 学号
     * @return true=已存在，false=不存在
     * @throws SQLException 查询失败时抛出
     */
    private boolean isStudentNoExists(String studentNo) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT 1 FROM students WHERE student_no = ? AND is_deleted = 0",
                studentNo
        );
        return !rows.isEmpty();
    }
}