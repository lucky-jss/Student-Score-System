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
import java.util.List;
import java.util.Map;

/**
 * 管理员等级分值设置 Servlet。
 * 访问路径：/admin/grading
 * 支持查询、新增、编辑、删除等级分值规则。
 */
@WebServlet("/admin/grading")
public class GradingSettingServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();

        // ==================== 权限校验 ====================
        User currentUser = (User) session.getAttribute("user");
        String role = (String) session.getAttribute("role");
        if (currentUser == null || !"admin".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {
                case "delete":
                    handleDelete(req, resp);
                    break;
                case "list":
                default:
                    showList(req, resp);
                    break;
            }
        } catch (SQLException e) {
            session.setAttribute("error", "系统错误：" + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        // ==================== 权限校验 ====================
        User currentUser = (User) session.getAttribute("user");
        String role = (String) session.getAttribute("role");
        if (currentUser == null || !"admin".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        try {
            doSave(req, resp);
        } catch (SQLException e) {
            session.setAttribute("error", "保存失败：" + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    // ==================== 显示列表 ====================
    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        List<Map<String, Object>> gradingList = DB.getGradingSettings();
        req.setAttribute("gradingList", gradingList);
        req.getRequestDispatcher("/admin/grading_setting.jsp").forward(req, resp);
    }

    // ==================== 保存（新增/编辑）====================
    private void doSave(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        String grade = req.getParameter("grade");
        String minScoreStr = req.getParameter("minScore");
        String maxScoreStr = req.getParameter("maxScore");
        String gpaStr = req.getParameter("gpa");

        HttpSession session = req.getSession();

        // 参数校验
        if (isBlank(grade) || isBlank(minScoreStr) || isBlank(maxScoreStr) || isBlank(gpaStr)) {
            session.setAttribute("error", "所有字段均为必填项");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        double minScore, maxScore, gpa;
        try {
            minScore = Double.parseDouble(minScoreStr.trim());
            maxScore = Double.parseDouble(maxScoreStr.trim());
            gpa = Double.parseDouble(gpaStr.trim());

            if (minScore < 0 || minScore > 100 || maxScore < 0 || maxScore > 100) {
                session.setAttribute("error", "分数必须在 0-100 之间");
                resp.sendRedirect(req.getContextPath() + "/admin/grading");
                return;
            }
            if (minScore >= maxScore) {
                session.setAttribute("error", "最低分必须小于最高分");
                resp.sendRedirect(req.getContextPath() + "/admin/grading");
                return;
            }
            if (gpa < 0 || gpa > 5) {
                session.setAttribute("error", "绩点必须在 0.00-5.00 之间");
                resp.sendRedirect(req.getContextPath() + "/admin/grading");
                return;
            }
        } catch (NumberFormatException e) {
            session.setAttribute("error", "分数或绩点格式不正确");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        grade = grade.trim().toUpperCase();
        if (!grade.matches("[ABCDF]")) {
            session.setAttribute("error", "等级只能是 A/B/C/D/F 之一");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        boolean isEdit = !isBlank(idStr);
        Integer settingId = isEdit ? Integer.parseInt(idStr.trim()) : null;

        // 检查等级唯一性
        if (DB.isGradeExists(grade, settingId)) {
            session.setAttribute("error", "等级 " + grade + " 的规则已存在");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        // 检查分数区间是否与现有规则重叠
        if (DB.isGradeRangeOverlap(settingId, minScore, maxScore)) {
            session.setAttribute("error", "分数区间与现有规则重叠，请调整");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        if (isEdit) {
            int rows = DB.updateGradingSetting(settingId, grade, minScore, maxScore, gpa);
            if (rows > 0) {
                session.setAttribute("success", "规则修改成功！");
            } else {
                session.setAttribute("error", "规则修改失败：记录不存在");
            }
        } else {
            int newId = DB.addGradingSetting(grade, minScore, maxScore, gpa);
            if (newId > 0) {
                session.setAttribute("success", "规则添加成功！");
            } else {
                session.setAttribute("error", "规则添加失败");
            }
        }

        resp.sendRedirect(req.getContextPath() + "/admin/grading");
    }

    // ==================== 删除 ====================
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        HttpSession session = req.getSession();

        if (isBlank(idStr)) {
            session.setAttribute("error", "参数不完整");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        // 检查是否至少保留一条规则
        int activeCount = DB.getActiveGradingSettingCount();
        if (activeCount <= 1) {
            session.setAttribute("error", "至少保留一条等级规则，禁止删除最后一条");
            resp.sendRedirect(req.getContextPath() + "/admin/grading");
            return;
        }

        int settingId = Integer.parseInt(idStr.trim());
        int rows = DB.deleteGradingSetting(settingId);
        if (rows > 0) {
            session.setAttribute("success", "规则已删除");
        } else {
            session.setAttribute("error", "删除失败：记录不存在");
        }
        resp.sendRedirect(req.getContextPath() + "/admin/grading");
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}
