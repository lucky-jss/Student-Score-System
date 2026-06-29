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
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * 管理员成绩导出 Servlet，仅管理员角色可用。
 * 访问路径：/admin/scores/export
 * 导出当前筛选条件下的所有成绩为 CSV 格式（UTF-8 BOM）。
 */
@WebServlet("/admin/scores/export")
public class AdminScoreExportServlet extends HttpServlet {

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

        try {
            // ==================== 查询成绩数据（不分页） ====================
            List<Map<String, Object>> scoreList = DB.getAdminScoresForExport(
                    departmentId, majorId, classId, subjectId, semesterId
            );

            // ==================== 生成 CSV 文件 ====================
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String filename = "全校成绩_" + timestamp + ".csv";

            resp.setContentType("text/csv;charset=UTF-8");
            resp.setHeader("Content-Disposition", "attachment; filename=" + filename);

            // 写入 UTF-8 BOM，解决 Excel 打开中文乱码
            resp.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            resp.getOutputStream().flush();

            PrintWriter writer = new PrintWriter(new java.io.OutputStreamWriter(resp.getOutputStream(), StandardCharsets.UTF_8));

            // CSV 表头
            writer.println("学号,姓名,班级,系部,专业,科目,学期,分数,等级,录入人,录入时间");

            // CSV 数据行
            for (Map<String, Object> row : scoreList) {
                writer.println(
                        escapeCsv(row.get("student_no")) + "," +
                                escapeCsv(row.get("student_name")) + "," +
                                escapeCsv(row.get("class_name")) + "," +
                                escapeCsv(row.get("department_name")) + "," +
                                escapeCsv(row.get("major_name")) + "," +
                                escapeCsv(row.get("subject_name")) + "," +
                                escapeCsv(row.get("semester_name")) + "," +
                                escapeCsv(row.get("score")) + "," +
                                escapeCsv(row.get("grade_level")) + "," +
                                escapeCsv(row.get("entered_by")) + "," +
                                escapeCsv(row.get("recorded_at"))
                );
            }

            writer.flush();
            writer.close();

        } catch (SQLException e) {
            resp.setContentType("text/html;charset=UTF-8");
            PrintWriter writer = resp.getWriter();
            writer.println("<html><body><h3>导出失败：" + e.getMessage() + "</h3></body></html>");
            writer.close();
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

    /**
     * 转义 CSV 字段值，处理逗号和引号。
     */
    private String escapeCsv(Object value) {
        if (value == null) {
            return "";
        }
        String str = value.toString();
        if (str.contains(",") || str.contains("\"") || str.contains("\n")) {
            str = str.replace("\"", "\"\"");
            return "\"" + str + "\"";
        }
        return str;
    }
}
