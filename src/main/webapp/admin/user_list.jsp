<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>

<%
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> userList = (List<Map<String, Object>>) request.getAttribute("userList");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Long totalRecords = (Long) request.getAttribute("totalRecords");
    List<Map<String, Object>> departments = (List<Map<String, Object>>) request.getAttribute("departments");

    if (userList == null) userList = new ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (totalRecords == null) totalRecords = 0L;

    String sessionSuccess = (String) session.getAttribute("success");
    String sessionError = (String) session.getAttribute("error");
    if (sessionSuccess != null) session.removeAttribute("success");
    if (sessionError != null) session.removeAttribute("error");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户管理 - 管理员控制台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", "PingFang SC", sans-serif; background: #f5f7fa; min-height: 100vh; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 16px 40px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header h1 { font-size: 18px; font-weight: 500; }
        .header .nav-links a { color: #fff; text-decoration: none; margin-left: 16px; font-size: 14px; padding: 6px 14px; background: rgba(255,255,255,0.2); border-radius: 4px; transition: background 0.3s; }
        .header .nav-links a:hover { background: rgba(255,255,255,0.3); }
        .container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
        .alert { padding: 12px 18px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }
        .alert-success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }
        .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .toolbar h2 { font-size: 18px; color: #333; }
        .btn { padding: 8px 18px; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; text-decoration: none; display: inline-block; transition: opacity 0.3s; }
        .btn:hover { opacity: 0.85; }
        .btn-primary { background: #667eea; color: #fff; }
        .btn-sm { padding: 4px 10px; font-size: 12px; border-radius: 4px; border: none; cursor: pointer; }
        .btn-edit { background: #42a5f5; color: #fff; }
        .btn-toggle-on { background: #66bb6a; color: #fff; }
        .btn-toggle-off { background: #ffa726; color: #fff; }
        .btn-reset { background: #ab47bc; color: #fff; }
        .btn-delete { background: #e53935; color: #fff; }
        .table-card { background: #fff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); overflow: hidden; }
        .table-card table { width: 100%; border-collapse: collapse; font-size: 14px; }
        .table-card th { background: #f5f7fa; padding: 12px 10px; font-size: 13px; color: #666; font-weight: 600; text-align: center; border-bottom: 2px solid #e0e0e0; }
        .table-card td { padding: 12px 10px; color: #333; text-align: center; border-bottom: 1px solid #f0f0f0; }
        .table-card tr:nth-child(even) { background: #fafbfc; }
        .table-card tr:hover { background: #e8f4fd; }
        .empty-state { text-align: center; padding: 60px 20px; color: #bbb; font-size: 16px; }
        .status-tag { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 500; }
        .status-active { background: #e8f5e9; color: #2e7d32; }
        .status-disabled { background: #f5f5f5; color: #999; }
        .role-tag { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 500; }
        .role-admin { background: #f3e5f5; color: #7b1fa2; }
        .role-teacher { background: #e3f2fd; color: #1565c0; }
        .action-btns { display: flex; gap: 4px; justify-content: center; flex-wrap: wrap; }
        .pagination { display: flex; justify-content: center; align-items: center; gap: 6px; padding: 16px; background: #fff; border-top: 1px solid #f0f0f0; }
        .pagination a, .pagination span { padding: 6px 12px; border-radius: 4px; font-size: 13px; text-decoration: none; color: #667eea; border: 1px solid #e0e0e0; transition: all 0.3s; }
        .pagination a:hover { background: #667eea; color: #fff; border-color: #667eea; }
        .pagination .current { background: #667eea; color: #fff; border-color: #667eea; }
        .pagination .disabled { color: #bbb; cursor: not-allowed; }

        /* 模态框 */
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; justify-content: center; align-items: center; }
        .modal-overlay.active { display: flex; }
        .modal { background: #fff; border-radius: 10px; width: 100%; max-width: 480px; padding: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.15); max-height: 90vh; overflow-y: auto; }
        .modal h3 { font-size: 16px; color: #333; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 1px solid #f0f0f0; }
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; font-size: 13px; color: #555; margin-bottom: 6px; font-weight: 500; }
        .form-group label .required { color: #e53935; margin-left: 2px; }
        .form-group input, .form-group select { width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; font-family: inherit; }
        .form-group input:focus, .form-group select:focus { outline: none; border-color: #667eea; }
        .form-group input:disabled, .form-group select:disabled { background: #f5f5f5; color: #999; }
        .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; padding-top: 16px; border-top: 1px solid #f0f0f0; }
        .btn-cancel { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .btn-submit { background: #667eea; color: #fff; }
        .help-text { font-size: 12px; color: #999; margin-top: 4px; }
    </style>
</head>
<body>
<div class="header">
    <h1>管理员控制台 - 用户管理</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <% if (sessionSuccess != null) { %>
    <div class="alert alert-success">&#10004; <%= sessionSuccess %></div>
    <% } %>
    <% if (sessionError != null) { %>
    <div class="alert alert-error">&#10008; <%= sessionError %></div>
    <% } %>

    <div class="toolbar">
        <h2>用户列表（共 <%= totalRecords %> 条）</h2>
        <button class="btn btn-primary" onclick="openAddModal()">&#43; 添加用户</button>
    </div>

    <div class="table-card">
        <% if (userList.isEmpty()) { %>
        <div class="empty-state">暂无用户记录</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th style="width:50px;">序号</th>
                <th>用户名</th>
                <th>真实姓名</th>
                <th>角色</th>
                <th>所属系部</th>
                <th>状态</th>
                <th style="width:220px;">操作</th>
            </tr>
            </thead>
            <tbody>
            <% int idx = (currentPage - 1) * 10;
                int currentUserId = currentUser.getId();
            %>
            <% for (Map<String, Object> row : userList) { %>
            <% idx++;
                String uRole = (String) row.get("role");
                Integer uStatus = row.get("status") != null ? ((Number) row.get("status")).intValue() : 1;
                Integer uId = ((Number) row.get("id")).intValue();
                boolean isSelf = uId == currentUserId;
                boolean enabled = uStatus == 1;
            %>
            <tr>
                <td><%= idx %></td>
                <td><%= row.get("username") %></td>
                <td><%= row.get("real_name") %></td>
                <td><span class="role-tag <%= "admin".equals(uRole) ? "role-admin" : "role-teacher" %>"><%= "admin".equals(uRole) ? "管理员" : "教师" %></span></td>
                <td><%= row.get("dept_name") != null ? row.get("dept_name") : "-" %></td>
                <td><span class="status-tag <%= enabled ? "status-active" : "status-disabled" %>"><%= enabled ? "启用" : "禁用" %></span></td>
                <td>
                    <div class="action-btns">
                        <button class="btn btn-sm btn-edit" onclick='openEditModal(<%= uId %>, "<%= row.get("username") %>", "<%= row.get("real_name") %>", "<%= uRole %>", <%= row.get("department_id") != null ? row.get("department_id") : "null" %>, <%= uStatus %>)'>编辑</button>
                        <% if (!isSelf) { %>
                        <a href="<%= ctx %>/admin/users?action=toggle&id=<%= uId %>" class="btn btn-sm <%= enabled ? "btn-toggle-off" : "btn-toggle-on" %>"><%= enabled ? "禁用" : "启用" %></a>
                        <% } %>
                        <button class="btn btn-sm btn-reset" onclick="confirmResetPassword(<%= uId %>, '<%= row.get("real_name") %>')">重置密码</button>
                        <% if (!isSelf) { %>
                        <button class="btn btn-sm btn-delete" onclick="confirmDelete(<%= uId %>, '<%= row.get("real_name") %>')">删除</button>
                        <% } %>
                    </div>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>

    <% if (totalPages > 1) { %>
    <div class="pagination">
        <% if (currentPage > 1) { %>
        <a href="<%= ctx %>/admin/users?page=1">首页</a>
        <a href="<%= ctx %>/admin/users?page=<%= currentPage - 1 %>">上一页</a>
        <% } else { %>
        <span class="disabled">首页</span>
        <span class="disabled">上一页</span>
        <% } %>
        <span class="current"><%= currentPage %> / <%= totalPages %></span>
        <% if (currentPage < totalPages) { %>
        <a href="<%= ctx %>/admin/users?page=<%= currentPage + 1 %>">下一页</a>
        <a href="<%= ctx %>/admin/users?page=<%= totalPages %>">末页</a>
        <% } else { %>
        <span class="disabled">下一页</span>
        <span class="disabled">末页</span>
        <% } %>
    </div>
    <% } %>
</div>

<!-- 模态框 -->
<div class="modal-overlay" id="modalOverlay">
    <div class="modal">
        <h3 id="modalTitle">添加用户</h3>
        <form id="userForm" action="<%= ctx %>/admin/users" method="post">
            <input type="hidden" name="id" id="formId" value="">

            <div class="form-group">
                <label>用户名 <span class="required">*</span></label>
                <input type="text" name="username" id="formUsername" placeholder="3-20位字母或数字">
                <div class="help-text" id="usernameHelp">添加后不可修改</div>
            </div>

            <div class="form-group">
                <label>真实姓名 <span class="required">*</span></label>
                <input type="text" name="realName" id="formRealName" required>
            </div>

            <div class="form-group">
                <label>角色 <span class="required">*</span></label>
                <select name="userRole" id="formRole" required>
                    <option value="">请选择</option>
                    <option value="admin">管理员</option>
                    <option value="teacher">教师</option>
                </select>
            </div>

            <div class="form-group" id="deptGroup">
                <label>所属系部 <span class="required" id="deptRequired">*</span></label>
                <select name="departmentId" id="formDept">
                    <option value="">请选择系部</option>
                    <%-- 动态加载，此处放占位 --%>
                </select>
                <div class="help-text" id="deptHelp">教师必须关联所属系部</div>
            </div>

            <div class="form-group" id="statusGroup" style="display:none;">
                <label>状态</label>
                <select name="userStatus" id="formStatus">
                    <option value="1">启用</option>
                    <option value="0">禁用</option>
                </select>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-cancel" onclick="closeModal()">取消</button>
                <button type="submit" class="btn btn-submit" id="submitBtn">确认添加</button>
            </div>
        </form>
    </div>
</div>

<script>
    // 系部数据（从页面中获取，避免额外请求）
    var departments = <%= request.getAttribute("departments") != null ? request.getAttribute("departments") : "[]" %>;

    function loadDepartments() {
        var select = document.getElementById('formDept');
        if (departments.length === 0) {
            // 通过 API 获取
            fetch('<%= ctx %>/admin/users?action=list')
                .then(function() {
                    // 如果没有预加载，直接用空列表
                });
            return;
        }
        select.innerHTML = '<option value="">请选择系部</option>';
        departments.forEach(function(d) {
            var opt = document.createElement('option');
            opt.value = d.id;
            opt.textContent = d.dept_name;
            select.appendChild(opt);
        });
    }

    function openAddModal() {
        document.getElementById('modalTitle').textContent = '添加用户';
        document.getElementById('formId').value = '';
        document.getElementById('formUsername').value = '';
        document.getElementById('formUsername').disabled = false;
        document.getElementById('usernameHelp').textContent = '添加后不可修改';
        document.getElementById('formRealName').value = '';
        document.getElementById('formRole').value = '';
        document.getElementById('formDept').value = '';
        document.getElementById('deptRequired').style.display = 'inline';
        document.getElementById('statusGroup').style.display = 'none';
        document.getElementById('submitBtn').textContent = '确认添加';
        loadDepartments();
        updateDeptVisibility();
        document.getElementById('modalOverlay').classList.add('active');
    }

    function openEditModal(id, username, realName, userRole, deptId, status) {
        document.getElementById('modalTitle').textContent = '编辑用户';
        document.getElementById('formId').value = id;
        document.getElementById('formUsername').value = username;
        document.getElementById('formUsername').disabled = true;
        document.getElementById('usernameHelp').textContent = '用户名不可修改';
        document.getElementById('formRealName').value = realName;
        document.getElementById('formRole').value = userRole;
        document.getElementById('formDept').value = deptId === null ? '' : deptId;
        document.getElementById('statusGroup').style.display = 'block';
        document.getElementById('formStatus').value = status;
        document.getElementById('submitBtn').textContent = '保存修改';
        loadDepartments();
        updateDeptVisibility();
        document.getElementById('modalOverlay').classList.add('active');
    }

    function closeModal() {
        document.getElementById('modalOverlay').classList.remove('active');
    }

    function updateDeptVisibility() {
        var role = document.getElementById('formRole').value;
        var deptGroup = document.getElementById('deptGroup');
        if (role === 'teacher') {
            deptGroup.style.display = 'block';
            document.getElementById('deptRequired').style.display = 'inline';
        } else {
            deptGroup.style.display = 'none';
        }
    }

    document.getElementById('formRole').addEventListener('change', updateDeptVisibility);

    function confirmResetPassword(id, name) {
        if (confirm('确定要将用户【' + name + '】的密码重置为 123456 吗？')) {
            window.location.href = '<%= ctx %>/admin/users?action=resetpwd&id=' + id;
        }
    }

    function confirmDelete(id, name) {
        if (confirm('确定要删除用户【' + name + '】吗？\n删除后该账号将无法登录。')) {
            window.location.href = '<%= ctx %>/admin/users?action=delete&id=' + id;
        }
    }

    document.getElementById('modalOverlay').addEventListener('click', function(e) {
        if (e.target === document.getElementById('modalOverlay')) closeModal();
    });
</script>
</body>
</html>
