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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 教师成绩列表 Servlet，支持多条件筛选。
 * 访问路径：/teacher/score_list
 * 支持筛选条件：班级、专业、科目、关键词（姓名/学号）
 */
@WebServlet("/teacher/score_list")
public class ScoreListServlet extends HttpServlet {

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

        // ==================== 接收筛选参数 ====================
        String keyword = req.getParameter("keyword");
        String classIdStr = req.getParameter("classId");
        String majorIdStr = req.getParameter("majorId");
        String subjectIdStr = req.getParameter("subjectId");

        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.isEmpty()) keyword = null;
        }
        int classId = parseIntParam(classIdStr, 0);
        int majorId = parseIntParam(majorIdStr, 0);
        int subjectId = parseIntParam(subjectIdStr, 0);

        try {
            // ==================== 加载下拉选项 ====================
            int deptId = currentUser.getDepartmentId() != null ? currentUser.getDepartmentId() : 0;

            // 专业列表（该系部下）
            List<Map<String, Object>> majors = new ArrayList<>();
            if (deptId > 0) {
                majors = DB.getMajorsByDepartment(deptId);
            }

            // 班级列表（该系部下所有专业对应的班级）
            List<Map<String, Object>> classes = DB.executeQuery(
                    "SELECT c.id, c.class_name, m.major_name " +
                            "FROM classes c " +
                            "JOIN majors m ON c.major_id = m.id " +
                            "WHERE m.department_id = ? AND c.is_deleted = 0 AND m.is_deleted = 0 " +
                            "ORDER BY m.major_name, c.class_name",
                    deptId
            );

            // 科目列表（该系部下）
            List<Map<String, Object>> subjects = DB.executeQuery(
                    "SELECT id, subject_name FROM subjects WHERE department_id = ? AND is_deleted = 0 ORDER BY subject_name",
                    deptId
            );

            // ==================== 查询成绩列表（使用多条件筛选） ====================
            List<Map<String, Object>> scoreList = DB.getTeacherScoresWithFilter(
                    currentUser.getId(), classId, majorId, subjectId, keyword);

            // ==================== 传递数据到 JSP ====================
            req.setAttribute("scoreList", scoreList);
            req.setAttribute("majors", majors);
            req.setAttribute("classes", classes);
            req.setAttribute("subjects", subjects);
            req.setAttribute("keyword", keyword);
            req.setAttribute("classId", classId);
            req.setAttribute("majorId", majorId);
            req.setAttribute("subjectId", subjectId);

            req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("error", "数据加载失败：" + e.getMessage());
            req.getRequestDispatcher("/teacher/score_list.jsp").forward(req, resp);
        } finally {
            try { DB.closeConnection(); } catch (SQLException ignored) {}
        }
    }

    private int parseIntParam(String param, int defaultValue) {
        if (param == null || param.trim().isEmpty()) return defaultValue;
        try { return Integer.parseInt(param.trim()); }
        catch (NumberFormatException e) { return defaultValue; }
    }
}
