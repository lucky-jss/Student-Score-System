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
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 成绩录入 Servlet，仅教师角色可用。
 * 访问路径：/score/input
 */
@WebServlet("/score/input")
public class ScoreInputServlet extends HttpServlet {

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
        String studentIdStr = req.getParameter("studentId");
        String subjectIdStr = req.getParameter("subjectId");
        String semesterIdStr = req.getParameter("semesterId");
        String scoreStr = req.getParameter("score");

        // ==================== 参数校验 ====================
        if (isBlank(studentIdStr) || isBlank(subjectIdStr)
                || isBlank(semesterIdStr) || isBlank(scoreStr)) {
            req.setAttribute("error", "所有字段均为必填项");
            req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
            return;
        }

        int studentId;
        int subjectId;
        int semesterId;
        BigDecimal score;

        try {
            studentId = Integer.parseInt(studentIdStr.trim());
            subjectId = Integer.parseInt(subjectIdStr.trim());
            semesterId = Integer.parseInt(semesterIdStr.trim());
            score = new BigDecimal(scoreStr.trim());
        } catch (NumberFormatException e) {
            req.setAttribute("error", "参数格式不正确");
            req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
            return;
        }

        // 成绩范围校验
        if (score.compareTo(BigDecimal.ZERO) < 0 || score.compareTo(new BigDecimal("100")) > 0) {
            req.setAttribute("error", "成绩必须在 0-100 之间");
            req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
            return;
        }

        try {
            // ==================== 业务校验 ====================
            // 1. 检查学生是否存在且有效
            if (!isStudentValid(studentId)) {
                req.setAttribute("error", "所选学生不存在或已失效");
                req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
                return;
            }

            // 2. 检查科目是否存在且有效
            if (!isSubjectValid(subjectId)) {
                req.setAttribute("error", "所选科目不存在或已失效");
                req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
                return;
            }

            // 3. 检查学期是否存在且有效
            if (!isSemesterValid(semesterId)) {
                req.setAttribute("error", "所选学期不存在或已失效");
                req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
                return;
            }

            // 4. 检查是否已有成绩（防止重复录入）
            if (DB.isScoreExists(studentId, subjectId, semesterId)) {
                req.setAttribute("error", "该学生该科目在本学期已有成绩，请勿重复录入");
                req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
                return;
            }

            // ==================== 事务：插入成绩 ====================
            DB.beginTransaction();

            int rows = DB.executeUpdate(
                    "INSERT INTO scores (student_id, subject_id, semester_id, score, recorded_by, recorded_at) " +
                            "VALUES (?, ?, ?, ?, ?, NOW())",
                    studentId, subjectId, semesterId, score, currentUser.getId()
            );

            if (rows > 0) {
                DB.commitTransaction();
                session.setAttribute("success", "成绩录入成功！");
                resp.sendRedirect(req.getContextPath() + "/teacher/index.jsp");
            } else {
                DB.rollbackTransaction();
                req.setAttribute("error", "成绩录入失败，请稍后重试");
                req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
            }

        } catch (SQLException e) {
            // 发生异常时回滚事务
            try {
                DB.rollbackTransaction();
            } catch (SQLException ignored) {
            }
            req.setAttribute("error", "系统错误：" + e.getMessage());
            req.getRequestDispatcher("/teacher/input_score.jsp").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * 检查学生是否存在且有效（未删除、在读状态）。
     */
    private boolean isStudentValid(int studentId) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT 1 FROM students WHERE id = ? AND is_deleted = 0 AND status = 1",
                studentId
        );
        return !rows.isEmpty();
    }

    /**
     * 检查科目是否存在且有效（未删除）。
     */
    private boolean isSubjectValid(int subjectId) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT 1 FROM subjects WHERE id = ? AND is_deleted = 0",
                subjectId
        );
        return !rows.isEmpty();
    }

    /**
     * 检查学期是否存在且有效（未删除）。
     */
    private boolean isSemesterValid(int semesterId) throws SQLException {
        List<Map<String, Object>> rows = DB.executeQuery(
                "SELECT 1 FROM semesters WHERE id = ? AND is_deleted = 0",
                semesterId
        );
        return !rows.isEmpty();
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}