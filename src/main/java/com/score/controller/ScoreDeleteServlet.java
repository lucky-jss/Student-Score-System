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
 * 成绩单条删除 Servlet，仅教师角色可用。
 * 访问路径：/score/delete
 * 处理逻辑删除（is_deleted = 1），非物理删除。
 * 注意：删除成功后，触发器 tr_scores_after_delete 会自动记录审计日志到 audit_log 表，
 * 代码无需额外处理审计逻辑。
 */
@WebServlet("/score/delete")
public class ScoreDeleteServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();

        // ==================== 权限校验 ====================
        User currentUser = (User) session.getAttribute("user");
        String role = (String) session.getAttribute("role");
        if (currentUser == null || !"teacher".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        // ==================== 接收参数 ====================
        String scoreIdStr = req.getParameter("scoreId");

        // ==================== 参数校验 ====================
        if (isBlank(scoreIdStr)) {
            req.setAttribute("error", "参数不完整");
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            return;
        }

        int scoreId;
        try {
            scoreId = Integer.parseInt(scoreIdStr.trim());
        } catch (NumberFormatException e) {
            req.setAttribute("error", "参数格式不正确");
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            return;
        }

        try {
            // ==================== 执行逻辑删除 ====================
            boolean deleted = DB.deleteScoreById(scoreId, currentUser.getId());

            if (deleted) {
                // 触发器 tr_scores_after_delete 会自动写入 audit_log
                resp.sendRedirect(req.getContextPath() + "/teacher/score_list?success=deleted");
            } else {
                req.setAttribute("error", "删除失败：记录不存在或您无权删除该成绩");
                req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            }

        } catch (SQLException e) {
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}