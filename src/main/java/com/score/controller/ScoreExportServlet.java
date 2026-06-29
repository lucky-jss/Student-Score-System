package com.score.controller;

import com.score.dao.DB;
import com.score.model.Student;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * 学生成绩导出 Servlet，导出当前筛选条件下的所有成绩为 CSV 格式。
 * 访问路径：/student/export
 */
@WebServlet("/student/export")
public class ScoreExportServlet extends HttpServlet {

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
        int semesterId = -1;
        String semesterIdParam = req.getParameter("semesterId");
        if (semesterIdParam != null && !semesterIdParam.trim().isEmpty()) {
            semesterId = Integer.parseInt(semesterIdParam.trim());
        }

        try {
            // ==================== 查询数据 ====================
            List<Map<String, Object>> scoreList = DB.getStudentScoresForExport(student.getId(), semesterId);

            // ==================== 设置响应头 ====================
            String dateStr = new SimpleDateFormat("yyyyMMdd").format(new Date());
            String fileName = java.net.URLEncoder.encode(
                    "成绩_" + student.getStudentNo() + "_" + dateStr + ".csv", StandardCharsets.UTF_8);

            resp.setContentType("text/csv;charset=UTF-8");
            resp.setHeader("Content-Disposition", "attachment; filename=" + fileName);

            // ==================== 写入 CSV ====================
            // 写入 BOM，确保 Excel 打开时正确识别 UTF-8
            try (PrintWriter writer = new PrintWriter(
                    new OutputStreamWriter(resp.getOutputStream(), StandardCharsets.UTF_8))) {

                // 写入 BOM
                writer.write("\uFEFF");

                // 写入表头
                writer.println("学期,科目,分数,等级,录入时间");

                // 写入数据行
                for (Map<String, Object> row : scoreList) {
                    StringBuilder line = new StringBuilder();
                    line.append(escapeCsv(row.get("semester_name")));
                    line.append(",").append(escapeCsv(row.get("subject_name")));
                    line.append(",").append(row.get("score") != null ? row.get("score") : "");
                    line.append(",").append(escapeCsv(row.get("grade_level")));
                    line.append(",").append(row.get("recorded_at") != null ? row.get("recorded_at") : "");
                    writer.println(line);
                }

                writer.flush();
            }

        } catch (SQLException e) {
            resp.setContentType("text/html;charset=UTF-8");
            resp.getWriter().println("<script>alert('导出失败：" + e.getMessage() + "');history.back();</script>");
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * CSV 字段转义，防止逗号、引号、换行导致格式错乱。
     */
    private String escapeCsv(Object value) {
        if (value == null) return "";
        String str = value.toString();
        if (str.contains(",") || str.contains("\"") || str.contains("\n")) {
            return "\"" + str.replace("\"", "\"\"") + "\"";
        }
        return str;
    }
}