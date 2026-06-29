package com.score.controller;

import com.score.dao.DB;
import com.score.model.Student;
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
 * 学生成绩查询 Servlet，支持分页、学期筛选、排名显示。
 * 访问路径：/student/query
 */
@WebServlet("/student/query")
public class ScoreQueryServlet extends HttpServlet {

    /** 默认每页条数 */
    private static final int DEFAULT_PAGE_SIZE = 10;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();

        // ==================== 权限校验 ====================
        Student student = (Student) session.getAttribute("student");
        String role = (String) session.getAttribute("role");
        if (student == null || !"student".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        // ==================== 接收参数 ====================
        // 学期ID：默认为当前学期
        int semesterId;
        String semesterIdParam = req.getParameter("semesterId");
        if (semesterIdParam != null && !semesterIdParam.trim().isEmpty()) {
            semesterId = Integer.parseInt(semesterIdParam.trim());
        } else {
            try {
                semesterId = DB.getCurrentSemesterId();
            } catch (SQLException e) {
                semesterId = -1;
            }
        }

        // 页码：默认第1页
        int page = 1;
        String pageParam = req.getParameter("page");
        if (pageParam != null && !pageParam.trim().isEmpty()) {
            try {
                page = Integer.parseInt(pageParam.trim());
                if (page < 1) page = 1;
            } catch (NumberFormatException ignored) {
            }
        }

        // 每页条数：默认10
        int pageSize = DEFAULT_PAGE_SIZE;
        String sizeParam = req.getParameter("size");
        if (sizeParam != null && !sizeParam.trim().isEmpty()) {
            try {
                pageSize = Integer.parseInt(sizeParam.trim());
                if (pageSize < 1) pageSize = DEFAULT_PAGE_SIZE;
                if (pageSize > 100) pageSize = 100;
            } catch (NumberFormatException ignored) {
            }
        }

        try {
            // ==================== 查询成绩数据（含排名） ====================
            PageResult<Map<String, Object>> pageResult =
                    DB.getStudentScoresWithRank(student.getId(), semesterId, page, pageSize);

            // ==================== 查询学期列表 ====================
            List<Map<String, Object>> semesterList = DB.getSemestersRaw();

            // ==================== 查询班级名称 ====================
            String className = DB.getClassName(student.getClassId());

            // ==================== 传递数据到 JSP ====================
            req.setAttribute("scoreList", pageResult.getList());
            req.setAttribute("pageResult", pageResult);
            req.setAttribute("semesterList", semesterList);
            req.setAttribute("selectedSemesterId", semesterId);
            req.setAttribute("studentName", student.getName());
            req.setAttribute("studentNo", student.getStudentNo());
            req.setAttribute("className", className);

            req.getRequestDispatcher("/student/query.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("error", "查询失败：" + e.getMessage());
            try {
                req.getRequestDispatcher("/student/query.jsp").forward(req, resp);
            } catch (Exception ignored) {
            }
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }
}