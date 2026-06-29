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
 * 管理员科目管理 Servlet。
 * 访问路径：/admin/subjects
 * 支持列表查询、新增、编辑、删除科目。
 */
@WebServlet("/admin/subjects")
public class SubjectManageServlet extends HttpServlet {

    private static final int PAGE_SIZE = 10;

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
                case "add":
                    showAddForm(req, resp);
                    break;
                case "edit":
                    showEditForm(req, resp);
                    break;
                case "delete":
                    handleDelete(req, resp);
                    break;
                case "list":
                default:
                    showList(req, resp);
                    break;
            }
        } catch (SQLException e) {
            req.setAttribute("error", "系统错误：" + e.getMessage());
            try {
                showList(req, resp);
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
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
            req.setAttribute("error", "保存失败：" + e.getMessage());
            try {
                List<Map<String, Object>> departments = DB.getDepartments();
                req.setAttribute("departments", departments);
            } catch (SQLException ignored) {
            }
            req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
        } finally {
            try {
                DB.closeConnection();
            } catch (SQLException ignored) {
            }
        }
    }

    // ==================== 显示列表 ====================
    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        int page = parseIntParam(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        PageResult<Map<String, Object>> pageResult = new PageResult<>();
        List<Map<String, Object>> subjectList = DB.getSubjectsPaged(page, PAGE_SIZE, pageResult);

        req.setAttribute("subjectList", subjectList);
        req.setAttribute("pageResult", pageResult);
        req.setAttribute("currentPage", pageResult.getCurrentPage());
        req.setAttribute("totalPages", pageResult.getTotalPages());
        req.setAttribute("totalRecords", pageResult.getTotalRecords());

        req.getRequestDispatcher("/admin/subject_list.jsp").forward(req, resp);
    }

    // ==================== 显示新增表单 ====================
    private void showAddForm(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        List<Map<String, Object>> departments = DB.getDepartments();
        req.setAttribute("departments", departments);
        req.setAttribute("isEdit", false);
        req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
    }

    // ==================== 显示编辑表单 ====================
    private void showEditForm(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        if (isBlank(idStr)) {
            resp.sendRedirect(req.getContextPath() + "/admin/subjects");
            return;
        }

        int subjectId = Integer.parseInt(idStr.trim());
        Map<String, Object> subject = DB.getSubjectById(subjectId);
        if (subject == null) {
            req.setAttribute("error", "科目不存在");
            showList(req, resp);
            return;
        }

        List<Map<String, Object>> departments = DB.getDepartments();
        req.setAttribute("departments", departments);
        req.setAttribute("subject", subject);
        req.setAttribute("isEdit", true);
        req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
    }

    // ==================== 保存（新增/编辑）====================
    private void doSave(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        String subjectCode = req.getParameter("subjectCode");
        String subjectName = req.getParameter("subjectName");
        String creditStr = req.getParameter("credit");
        String departmentIdStr = req.getParameter("departmentId");

        // 参数校验
        if (isBlank(subjectCode) || isBlank(subjectName) || isBlank(creditStr) || isBlank(departmentIdStr)) {
            req.setAttribute("error", "所有字段均为必填项");
            preserveFormData(req, idStr, subjectCode, subjectName, creditStr, departmentIdStr);
            req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
            return;
        }

        double credit;
        int departmentId;
        try {
            credit = Double.parseDouble(creditStr.trim());
            departmentId = Integer.parseInt(departmentIdStr.trim());
            if (credit <= 0) {
                req.setAttribute("error", "学分必须大于 0");
                preserveFormData(req, idStr, subjectCode, subjectName, creditStr, departmentIdStr);
                req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
                return;
            }
        } catch (NumberFormatException e) {
            req.setAttribute("error", "学分或系部ID格式不正确");
            preserveFormData(req, idStr, subjectCode, subjectName, creditStr, departmentIdStr);
            req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
            return;
        }

        subjectCode = subjectCode.trim();
        subjectName = subjectName.trim();

        boolean isEdit = !isBlank(idStr);
        Integer subjectId = isEdit ? Integer.parseInt(idStr.trim()) : null;

        // 检查科目编码唯一性
        if (DB.isSubjectCodeExists(subjectCode, subjectId)) {
            req.setAttribute("error", "科目编码已存在：" + subjectCode);
            preserveFormData(req, idStr, subjectCode, subjectName, creditStr, departmentIdStr);
            req.getRequestDispatcher("/admin/subject_form.jsp").forward(req, resp);
            return;
        }

        if (isEdit) {
            // 更新
            int rows = DB.updateSubject(subjectId, subjectCode, subjectName, credit, departmentId);
            if (rows > 0) {
                req.getSession().setAttribute("success", "科目修改成功！");
            } else {
                req.getSession().setAttribute("error", "科目修改失败：记录不存在");
            }
        } else {
            // 新增
            int newId = DB.addSubject(subjectCode, subjectName, credit, departmentId);
            if (newId > 0) {
                req.getSession().setAttribute("success", "科目添加成功！");
            } else {
                req.getSession().setAttribute("error", "科目添加失败");
            }
        }

        resp.sendRedirect(req.getContextPath() + "/admin/subjects");
    }

    // ==================== 删除 ====================
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        if (isBlank(idStr)) {
            req.getSession().setAttribute("error", "参数不完整");
            resp.sendRedirect(req.getContextPath() + "/admin/subjects");
            return;
        }

        int subjectId = Integer.parseInt(idStr.trim());
        int rows = DB.deleteSubject(subjectId);
        if (rows > 0) {
            req.getSession().setAttribute("success", "科目已删除");
        } else {
            req.getSession().setAttribute("error", "删除失败：记录不存在");
        }
        resp.sendRedirect(req.getContextPath() + "/admin/subjects");
    }

    // ==================== 保留表单数据（校验失败时回显）====================
    private void preserveFormData(HttpServletRequest req, String idStr, String subjectCode,
                                  String subjectName, String creditStr, String departmentIdStr) throws SQLException {
        req.setAttribute("id", idStr);
        req.setAttribute("subjectCode", subjectCode);
        req.setAttribute("subjectName", subjectName);
        req.setAttribute("credit", creditStr);
        req.setAttribute("departmentId", departmentIdStr);
        req.setAttribute("isEdit", !isBlank(idStr));
        List<Map<String, Object>> departments = DB.getDepartments();
        req.setAttribute("departments", departments);
    }

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

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}
