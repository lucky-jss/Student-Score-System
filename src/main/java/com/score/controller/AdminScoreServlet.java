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
 * 管理员成绩查询 Servlet，仅管理员角色可用。
 * 访问路径：/admin/scores
 * 支持多条件组合筛选、分页展示。
 */
@WebServlet("/admin/scores")
public class AdminScoreServlet extends HttpServlet {

    private static final int PAGE_SIZE = 15;

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

        // ==================== 接收筛选参数 ====================
        int departmentId = parseIntParam(req.getParameter("departmentId"), -1);
        int majorId = parseIntParam(req.getParameter("majorId"), -1);
        int classId = parseIntParam(req.getParameter("classId"), -1);
        int subjectId = parseIntParam(req.getParameter("subjectId"), -1);
        int semesterId = parseIntParam(req.getParameter("semesterId"), -1);
        int page = parseIntParam(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        try {
            // ==================== 加载筛选下拉列表数据 ====================
            List<Map<String, Object>> departments = DB.getDepartments();
            List<Map<String, Object>> majors = DB.getMajorsByDepartment(departmentId);
            List<Map<String, Object>> classes = DB.getClassesByMajor(majorId);
            List<Map<String, Object>> subjects = DB.getSubjectsForAdmin();
            List<Map<String, Object>> semesters = DB.getSemestersForAdmin();

            // ==================== 查询成绩列表（分页） ====================
            PageResult<Object> pageResult = new PageResult<>();
            List<Map<String, Object>> scoreList = DB.getAdminScores(
                    departmentId, majorId, classId, subjectId, semesterId,
                    page, PAGE_SIZE, pageResult
            );

            // ==================== 传递数据到 JSP ====================
            req.setAttribute("scoreList", scoreList);
            req.setAttribute("totalRecords", pageResult.getTotalRecords());
            req.setAttribute("totalPages", pageResult.getTotalPages());
            req.setAttribute("currentPage", pageResult.getCurrentPage());

            req.setAttribute("departments", departments);
            req.setAttribute("majors", majors);
            req.setAttribute("classes", classes);
            req.setAttribute("subjects", subjects);
            req.setAttribute("semesters", semesters);

            req.setAttribute("selectedDepartmentId", departmentId);
            req.setAttribute("selectedMajorId", majorId);
            req.setAttribute("selectedClassId", classId);
            req.setAttribute("selectedSubjectId", subjectId);
            req.setAttribute("selectedSemesterId", semesterId);

            req.getRequestDispatcher("/admin/scores.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("error", "数据加载失败：" + e.getMessage());
            req.getRequestDispatcher("/admin/scores.jsp").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * 解析整数参数，解析失败返回默认值。
     */
    private int parseIntParam(String param, int defaultValue) {
        if (param == null || param.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(param.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}