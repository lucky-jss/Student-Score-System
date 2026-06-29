package com.score.controller;

import com.score.dao.DB;
import com.score.model.User;
import com.score.util.PageResult;
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
 * 审计日志查看 Servlet。
 * 访问路径：/admin/audit-log
 * 仅管理员可访问，支持按操作类型和时间范围筛选，分页展示。
 */
@WebServlet("/admin/audit-log")
public class AuditLogServlet extends HttpServlet {

    private static final int PAGE_SIZE = 15;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();

        User currentUser = (User) session.getAttribute("user");
        String role = (String) session.getAttribute("role");
        if (currentUser == null || !"admin".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        // 获取筛选参数
        String action = req.getParameter("action");
        String startDate = req.getParameter("startDate");
        String endDate = req.getParameter("endDate");

        // 获取分页参数
        int page = 1;
        String pageParam = req.getParameter("page");
        if (pageParam != null && !pageParam.trim().isEmpty()) {
            try {
                page = Integer.parseInt(pageParam.trim());
            } catch (NumberFormatException ignored) {
            }
        }

        try {
            PageResult<Map<String, Object>> pageResult = new PageResult<>();
            List<Map<String, Object>> logList = DB.getAuditLogs(action, startDate, endDate, page, PAGE_SIZE, pageResult);

            req.setAttribute("logList", logList);
            req.setAttribute("currentPage", pageResult.getCurrentPage());
            req.setAttribute("totalPages", pageResult.getTotalPages());
            req.setAttribute("totalRecords", pageResult.getTotalRecords());

            // 回传筛选参数
            req.setAttribute("action", action);
            req.setAttribute("startDate", startDate);
            req.setAttribute("endDate", endDate);

            req.getRequestDispatcher("/admin/audit_log.jsp").forward(req, resp);
        } catch (SQLException e) {
            session.setAttribute("error", "查询失败：" + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/admin/index.jsp");
        } finally {
            try { DB.closeConnection(); } catch (SQLException ignored) {}
        }
    }
}
