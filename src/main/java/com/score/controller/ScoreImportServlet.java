package com.score.controller;

import com.score.dao.DB;
import com.score.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 成绩批量导入 Servlet。
 * 访问路径：/score/import
 * 支持 POST 导入 CSV、GET 下载模板。
 */
@WebServlet("/score/import")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 1024 * 1024 * 10, maxRequestSize = 1024 * 1024 * 15)
public class ScoreImportServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String role = (String) session.getAttribute("role");
        if (!"teacher".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        if ("template".equals(action)) {
            downloadTemplate(resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/teacher/import_score.jsp");
        }
    }

    /**
     * 下载 CSV 模板文件。
     */
    private void downloadTemplate(HttpServletResponse resp) throws IOException {
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"score_template.csv\"");
        // UTF-8 BOM，确保 Excel 正确识别中文
        resp.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        String template = "student_no,subject_code,score\n";
        resp.getOutputStream().write(template.getBytes(StandardCharsets.UTF_8));
        resp.getOutputStream().flush();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        User currentUser = (User) session.getAttribute("user");
        String role = (String) session.getAttribute("role");
        if (currentUser == null || !"teacher".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String semesterIdStr = req.getParameter("semesterId");
        if (semesterIdStr == null || semesterIdStr.trim().isEmpty()) {
            session.setAttribute("error", "请选择学期");
            resp.sendRedirect(req.getContextPath() + "/teacher/import_score.jsp");
            return;
        }

        int semesterId;
        try {
            semesterId = Integer.parseInt(semesterIdStr.trim());
        } catch (NumberFormatException e) {
            session.setAttribute("error", "学期参数无效");
            resp.sendRedirect(req.getContextPath() + "/teacher/import_score.jsp");
            return;
        }

        Part filePart = req.getPart("csvFile");
        if (filePart == null || filePart.getSize() == 0) {
            session.setAttribute("error", "请上传 CSV 文件");
            resp.sendRedirect(req.getContextPath() + "/teacher/import_score.jsp");
            return;
        }

        String fileName = filePart.getSubmittedFileName();
        if (fileName == null || !fileName.toLowerCase().endsWith(".csv")) {
            session.setAttribute("error", "请上传 .csv 格式的文件");
            resp.sendRedirect(req.getContextPath() + "/teacher/import_score.jsp");
            return;
        }

        List<String> errors = new ArrayList<>();
        int successCount = 0;
        int totalRows = 0;
        int lineNumber = 0;

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(filePart.getInputStream(), StandardCharsets.UTF_8))) {
            DB.beginTransaction();

            String line;
            boolean firstLine = true;
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                line = line.trim();
                if (line.isEmpty()) {
                    continue;
                }

                // 跳过表头
                if (firstLine) {
                    firstLine = false;
                    continue;
                }

                totalRows++;

                // 解析 CSV 列（简单格式，不处理引号内逗号）
                String[] cols = line.split(",", -1);
                if (cols.length < 3) {
                    errors.add("第 " + lineNumber + " 行：列数不足，需要 student_no, subject_code, score");
                    continue;
                }

                String studentNo = cols[0].trim();
                String subjectCode = cols[1].trim();
                String scoreStr = cols[2].trim();

                if (studentNo.isEmpty() || subjectCode.isEmpty() || scoreStr.isEmpty()) {
                    errors.add("第 " + lineNumber + " 行：存在空值");
                    continue;
                }

                double score;
                try {
                    score = Double.parseDouble(scoreStr);
                } catch (NumberFormatException e) {
                    errors.add("第 " + lineNumber + " 行：分数格式错误 \"" + scoreStr + "\"");
                    continue;
                }

                if (score < 0 || score > 100) {
                    errors.add("第 " + lineNumber + " 行：分数 " + score + " 超出 0-100 范围");
                    continue;
                }

                Integer studentId = DB.getStudentIdByNo(studentNo);
                if (studentId == null) {
                    errors.add("第 " + lineNumber + " 行：学号 \"" + studentNo + "\" 不存在或已停用");
                    continue;
                }

                Integer subjectId = DB.getSubjectIdByCode(subjectCode);
                if (subjectId == null) {
                    errors.add("第 " + lineNumber + " 行：科目编码 \"" + subjectCode + "\" 不存在");
                    continue;
                }

                boolean ok = DB.importScore(studentId, subjectId, semesterId, score, currentUser.getId());
                if (ok) {
                    successCount++;
                } else {
                    errors.add("第 " + lineNumber + " 行：数据库操作失败");
                }
            }

            DB.commitTransaction();
        } catch (SQLException e) {
            try {
                DB.rollbackTransaction();
            } catch (SQLException ignored) {
            }
            errors.add(0, "系统错误（事务已回滚）：" + e.getMessage());
            successCount = 0;
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }

        int failCount = totalRows - successCount;
        req.setAttribute("successCount", successCount);
        req.setAttribute("failCount", failCount);
        req.setAttribute("errors", errors);
        req.getRequestDispatcher("/teacher/import_result.jsp").forward(req, resp);
    }
}
