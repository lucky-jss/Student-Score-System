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
import java.util.Map;

/**
 * 成绩修改 Servlet，仅教师角色可用。
 * 访问路径：/score/update
 * 注意：修改成功后，触发器 tr_scores_after_update 会自动记录审计日志到 audit_log 表，
 * 代码无需额外处理审计逻辑。
 */
@WebServlet("/score/update")
public class ScoreUpdateServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
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
        String newScoreStr = req.getParameter("newScore");

        // ==================== 参数校验 ====================
        if (isBlank(scoreIdStr) || isBlank(newScoreStr)) {
            req.setAttribute("error", "参数不完整");
            req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
            return;
        }

        int scoreId;
        double newScore;
        try {
            scoreId = Integer.parseInt(scoreIdStr.trim());
            newScore = Double.parseDouble(newScoreStr.trim());
        } catch (NumberFormatException e) {
            req.setAttribute("error", "参数格式不正确");
            req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
            return;
        }

        // 成绩范围校验
        if (newScore < 0 || newScore > 100) {
            req.setAttribute("error", "成绩必须在 0-100 之间");
            req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
            return;
        }

        try {
            // ==================== 权限校验：验证该成绩是否属于当前教师 ====================
            Map<String, Object> scoreInfo = DB.getScoreById(scoreId);
            if (scoreInfo == null) {
                req.setAttribute("error", "成绩记录不存在或已被删除");
                req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
                return;
            }

            if (!isScoreBelongsToTeacher(scoreId, currentUser.getId())) {
                req.setAttribute("error", "您无权修改该成绩记录");
                req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
                return;
            }

            // ==================== 根据新分数计算等级 ====================
            String newGradeLevel = DB.getGradeLevel(newScore);

            // ==================== 事务：更新成绩（同时更新 score 和 grade_level） ====================
            DB.beginTransaction();

            // 修复：同时更新 score 和 grade_level 字段
            boolean updated = DB.updateScore(scoreId, newScore, newGradeLevel);

            if (updated) {
                DB.commitTransaction();
                // 触发器 tr_scores_after_update 会自动写入 audit_log
                session.setAttribute("success", "成绩修改成功！等级已同步更新为：" + newGradeLevel);
                resp.sendRedirect(req.getContextPath() + "/teacher/score_list.jsp");
            } else {
                DB.rollbackTransaction();
                req.setAttribute("error", "成绩修改失败，请稍后重试");
                req.getRequestDispatcher("/teacher/score_edit.jsp?id=" + scoreId).forward(req, resp);
            }

        } catch (SQLException e) {
            try {
                DB.rollbackTransaction();
            } catch (SQLException ignored) {
            }
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/teacher/score_edit.jsp?id=" + scoreId).forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * 验证指定成绩是否由指定教师录入。
     */
    private boolean isScoreBelongsToTeacher(int scoreId, int teacherId) throws SQLException {
        String sql = "SELECT 1 FROM scores WHERE id = ? AND recorded_by = ? AND is_deleted = 0";
        return !DB.executeQuery(sql, scoreId, teacherId).isEmpty();
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}