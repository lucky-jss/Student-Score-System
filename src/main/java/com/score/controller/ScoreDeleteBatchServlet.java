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
 * 成绩批量删除 Servlet，仅教师角色可用。
 * 访问路径：/score/deleteBatch
 * 使用事务控制保证原子性：全部成功则提交，任何一条失败则回滚。
 * 注意：每条删除都会独立触发 tr_scores_after_delete 触发器，自动记录审计日志。
 */
@WebServlet("/score/deleteBatch")
public class ScoreDeleteBatchServlet extends HttpServlet {

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
        String[] scoreIdStrs = req.getParameterValues("scoreIds");

        // ==================== 参数校验 ====================
        if (scoreIdStrs == null || scoreIdStrs.length == 0) {
            req.setAttribute("error", "请至少选择一条成绩");
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            return;
        }

        // 解析成绩ID数组
        int[] scoreIds = new int[scoreIdStrs.length];
        try {
            for (int i = 0; i < scoreIdStrs.length; i++) {
                scoreIds[i] = Integer.parseInt(scoreIdStrs[i].trim());
            }
        } catch (NumberFormatException e) {
            req.setAttribute("error", "参数格式不正确");
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            return;
        }

        try {
            // ==================== 事务：批量逻辑删除 ====================
            DB.beginTransaction();

            int deletedCount = DB.deleteScoresBatch(scoreIds, currentUser.getId());

            if (deletedCount == scoreIds.length) {
                // 全部删除成功
                DB.commitTransaction();
                // 触发器 tr_scores_after_delete 会自动写入 audit_log
                resp.sendRedirect(req.getContextPath() + "/teacher/score_list?success=batch_deleted&count=" + deletedCount);
            } else if (deletedCount > 0) {
                // 部分成功（理论上不应发生，因为 deleteScoresBatch 逐条验证权限）
                DB.rollbackTransaction();
                req.setAttribute("error", "批量删除失败：部分记录无权限删除，操作已回滚");
                req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            } else {
                // 全部失败
                DB.rollbackTransaction();
                req.setAttribute("error", "批量删除失败：所选记录不存在或您无权删除");
                req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
            }

        } catch (SQLException e) {
            try {
                DB.rollbackTransaction();
            } catch (SQLException ignored) {
            }
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/teacher/score_list").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }
}