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
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 管理员用户管理 Servlet。
 * 访问路径：/admin/users
 * 支持列表查询、新增、编辑、启用/禁用、重置密码、删除用户。
 */
@WebServlet("/admin/users")
public class UserManageServlet extends HttpServlet {

    private static final int PAGE_SIZE = 10;
    private static final String DEFAULT_PASSWORD = "123456";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();

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
                case "toggle":
                    handleToggle(req, resp);
                    break;
                case "resetpwd":
                    handleResetPassword(req, resp);
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
            session.setAttribute("error", "系统错误：" + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } finally {
            try { DB.closeConnection(); } catch (SQLException ignored) {}
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

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
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } finally {
            try { DB.closeConnection(); } catch (SQLException ignored) {}
        }
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        int page = parseIntParam(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        PageResult<Map<String, Object>> pageResult = new PageResult<>();
        List<Map<String, Object>> userList = DB.getUsersPaged(page, PAGE_SIZE, pageResult);

        req.setAttribute("userList", userList);
        req.setAttribute("currentPage", pageResult.getCurrentPage());
        req.setAttribute("totalPages", pageResult.getTotalPages());
        req.setAttribute("totalRecords", pageResult.getTotalRecords());

        // 系部列表（模态框下拉用）
        List<Map<String, Object>> departments = DB.getDepartments();
        req.setAttribute("departments", departments);

        req.getRequestDispatcher("/admin/user_list.jsp").forward(req, resp);
    }

    private void doSave(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        String idStr = req.getParameter("id");
        String username = req.getParameter("username");
        String realName = req.getParameter("realName");
        String userRole = req.getParameter("userRole");
        String departmentIdStr = req.getParameter("departmentId");
        String statusStr = req.getParameter("userStatus");

        HttpSession session = req.getSession();

        // 参数校验
        if (isBlank(realName) || isBlank(userRole)) {
            session.setAttribute("error", "真实姓名和角色为必填项");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        boolean isEdit = !isBlank(idStr);
        Integer userId = isEdit ? Integer.parseInt(idStr.trim()) : null;

        // 新增时用户名必填
        if (!isEdit && isBlank(username)) {
            session.setAttribute("error", "用户名为必填项");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        // 用户名格式校验
        if (!isBlank(username) && !username.trim().matches("^[a-zA-Z0-9]{3,20}$")) {
            session.setAttribute("error", "用户名必须为3-20位字母或数字");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        // 角色校验
        if (!userRole.equals("admin") && !userRole.equals("teacher")) {
            session.setAttribute("error", "角色只能为 admin 或 teacher");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        // 教师必须关联系部
        Integer departmentId = isBlank(departmentIdStr) ? null : Integer.parseInt(departmentIdStr.trim());
        if ("teacher".equals(userRole) && departmentId == null) {
            session.setAttribute("error", "教师必须关联所属系部");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        int status = isBlank(statusStr) ? 1 : Integer.parseInt(statusStr.trim());
        if (status != 0 && status != 1) status = 1;

        // 用户名唯一性检查
        if (!isBlank(username)) {
            if (DB.isUsernameExists(username.trim(), userId)) {
                session.setAttribute("error", "用户名已存在：" + username);
                resp.sendRedirect(req.getContextPath() + "/admin/users");
                return;
            }
        }

        if (isEdit) {
            int rows = DB.updateUser(userId, realName.trim(), userRole, departmentId, status);
            if (rows > 0) {
                session.setAttribute("success", "用户修改成功！");
            } else {
                session.setAttribute("error", "用户修改失败：记录不存在");
            }
        } else {
            String passwordHash = BCrypt.hashpw(DEFAULT_PASSWORD, BCrypt.gensalt(12));
            int newId = DB.addUser(username.trim(), passwordHash, realName.trim(), userRole, departmentId);
            if (newId > 0) {
                session.setAttribute("success", "用户添加成功！初始密码为 " + DEFAULT_PASSWORD);
            } else {
                session.setAttribute("error", "用户添加失败");
            }
        }

        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    private void handleToggle(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        HttpSession session = req.getSession();
        String idStr = req.getParameter("id");
        if (isBlank(idStr)) {
            session.setAttribute("error", "参数不完整");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }
        int userId = Integer.parseInt(idStr.trim());

        // 不能禁用自己
        User currentUser = (User) session.getAttribute("user");
        if (currentUser.getId() == userId) {
            session.setAttribute("error", "不能禁用自己的账号");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        int rows = DB.toggleUserStatus(userId);
        if (rows > 0) {
            session.setAttribute("success", "用户状态已切换");
        } else {
            session.setAttribute("error", "操作失败：用户不存在");
        }
        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    private void handleResetPassword(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        HttpSession session = req.getSession();
        String idStr = req.getParameter("id");
        if (isBlank(idStr)) {
            session.setAttribute("error", "参数不完整");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }
        int userId = Integer.parseInt(idStr.trim());

        String passwordHash = BCrypt.hashpw(DEFAULT_PASSWORD, BCrypt.gensalt(12));
        int rows = DB.resetUserPassword(userId, passwordHash);
        if (rows > 0) {
            session.setAttribute("success", "密码已重置为 " + DEFAULT_PASSWORD);
        } else {
            session.setAttribute("error", "重置失败：用户不存在");
        }
        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, SQLException {
        HttpSession session = req.getSession();
        String idStr = req.getParameter("id");
        if (isBlank(idStr)) {
            session.setAttribute("error", "参数不完整");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }
        int userId = Integer.parseInt(idStr.trim());

        // 不能删除自己
        User currentUser = (User) session.getAttribute("user");
        if (currentUser.getId() == userId) {
            session.setAttribute("error", "不能删除自己的账号");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        int rows = DB.deleteUser(userId);
        if (rows > 0) {
            session.setAttribute("success", "用户已删除");
        } else {
            session.setAttribute("error", "删除失败：用户不存在");
        }
        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    private int parseIntParam(String param, int defaultValue) {
        if (param == null || param.trim().isEmpty()) return defaultValue;
        try { return Integer.parseInt(param.trim()); }
        catch (NumberFormatException e) { return defaultValue; }
    }

    private boolean isBlank(String str) {
        return str == null || str.trim().isEmpty();
    }
}
