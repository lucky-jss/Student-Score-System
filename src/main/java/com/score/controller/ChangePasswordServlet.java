package com.score.controller;

import com.score.dao.DB;
import com.score.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 修改密码 Servlet，所有已登录用户可用。
 * 访问路径：/change-password
 * 仅接受 POST 请求。
 */
@WebServlet("/change-password")
public class ChangePasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        // ==================== 权限校验 ====================
        User currentUser = (User) session.getAttribute("user");
        if (currentUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String currentPassword = req.getParameter("currentPassword");
        String newPassword = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");

        // ==================== 参数校验 ====================
        if (isBlank(currentPassword) || isBlank(newPassword) || isBlank(confirmPassword)) {
            req.setAttribute("error", "请填写所有密码字段");
            req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
            return;
        }

        // 新密码长度校验
        if (newPassword.length() < 6) {
            req.setAttribute("error", "新密码长度不能少于 6 位");
            req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
            return;
        }

        // 新密码与确认密码一致性校验
        if (!newPassword.equals(confirmPassword)) {
            req.setAttribute("error", "新密码与确认密码不一致");
            req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
            return;
        }

        // 不能与原密码相同
        if (currentPassword.equals(newPassword)) {
            req.setAttribute("error", "新密码不能与当前密码相同");
            req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
            return;
        }

        try {
            // ==================== 验证当前密码 ====================
            if (!currentPassword.equals(currentUser.getPasswordHash())) {
                req.setAttribute("error", "当前密码不正确");
                req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
                return;
            }

            // ==================== 更新密码（明文存储） ====================
            int rows = DB.updatePassword(currentUser.getId(), newPassword);

            if (rows > 0) {
                // 更新 session 中的 User 对象密码缓存
                currentUser.setPasswordHash(newPassword);

                // 清除 Session，跳转登录页
                session.invalidate();
                resp.sendRedirect(req.getContextPath() + "/login.jsp?msg=password_changed");
            } else {
                req.setAttribute("error", "密码修改失败，请重试");
                req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
            }

        } catch (SQLException e) {
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/change_password.jsp").forward(req, resp);
        } finally {
            try { DB.closeConnection(); } catch (SQLException ignored) {}
        }
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}
