package com.score.controller;

import com.score.dao.DB;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 测试 Servlet，用于验证项目环境是否正常。
 * 访问路径：/test
 */
@WebServlet("/test")
public class TestServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        out.println("<!DOCTYPE html>");
        out.println("<html><head><title>环境测试</title></head><body>");
        out.println("<h1>score-system 环境测试</h1>");

        try {
            // 查询 departments 表所有数据
            List<Map<String, Object>> departments = DB.executeQuery(
                    "SELECT id, dept_code, dept_name, description FROM departments WHERE is_deleted = 0"
            );

            out.println("<h2>departments 表数据（共 " + departments.size() + " 条）</h2>");
            out.println("<table border='1' cellpadding='8'>");
            out.println("<tr><th>ID</th><th>编码</th><th>名称</th><th>描述</th></tr>");

            for (Map<String, Object> row : departments) {
                out.println("<tr>");
                out.println("<td>" + row.get("id") + "</td>");
                out.println("<td>" + row.get("dept_code") + "</td>");
                out.println("<td>" + row.get("dept_name") + "</td>");
                out.println("<td>" + row.get("description") + "</td>");
                out.println("</tr>");
            }

            out.println("</table>");
            out.println("<p style='color:green;'>✅ 数据库连接正常，查询成功！</p>");

        } catch (SQLException e) {
            out.println("<p style='color:red;'>❌ 数据库操作失败：" + e.getMessage() + "</p>");
            e.printStackTrace(out);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }

        out.println("</body></html>");
    }
}