<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="java.util.*" %>

<%
    // ==================== 权限检查 ====================
    User currentUser = (User) session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    if (currentUser == null || !"admin".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ==================== 获取数据 ====================
    List<Map<String, Object>> gradingList = (List<Map<String, Object>>) request.getAttribute("gradingList");
    if (gradingList == null) gradingList = new ArrayList<>();

    // 操作结果消息
    String sessionSuccess = (String) session.getAttribute("success");
    String sessionError = (String) session.getAttribute("error");
    if (sessionSuccess != null) session.removeAttribute("success");
    if (sessionError != null) session.removeAttribute("error");

    // 编辑模式数据
    String editId = request.getParameter("editId");
    Map<String, Object> editItem = null;
    if (editId != null && !editId.isEmpty()) {
        for (Map<String, Object> item : gradingList) {
            if (editId.equals(String.valueOf(item.get("id")))) {
                editItem = item;
                break;
            }
        }
    }

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>等级分值设置 - 管理员控制台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 16px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 18px; font-weight: 500; }
        .header .nav-links a {
            color: #fff;
            text-decoration: none;
            margin-left: 16px;
            font-size: 14px;
            padding: 6px 14px;
            background: rgba(255,255,255,0.2);
            border-radius: 4px;
            transition: background 0.3s;
        }
        .header .nav-links a:hover { background: rgba(255,255,255,0.3); }
        .container {
            max-width: 900px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .alert {
            padding: 12px 18px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
        .alert-error { background: #ffebee; color: #c62828; border-left: 4px solid #e53935; }

        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .toolbar h2 { font-size: 18px; color: #333; }
        .btn {
            padding: 8px 18px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: opacity 0.3s;
        }
        .btn:hover { opacity: 0.85; }
        .btn-primary { background: #667eea; color: #fff; }
        .btn-edit { background: #42a5f5; color: #fff; padding: 4px 12px; font-size: 13px; border: none; border-radius: 6px; cursor: pointer; }
        .btn-delete { background: #e53935; color: #fff; padding: 4px 12px; font-size: 13px; border: none; border-radius: 6px; cursor: pointer; }
        .btn-delete:hover { background: #c62828; }
        .btn-disabled { background: #ccc; color: #999; cursor: not-allowed; padding: 4px 12px; font-size: 13px; border: none; border-radius: 6px; }

        .table-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        .table-card table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        .table-card th {
            background: #f5f7fa;
            padding: 12px 14px;
            font-size: 13px;
            color: #666;
            font-weight: 600;
            text-align: center;
            border-bottom: 2px solid #e0e0e0;
        }
        .table-card td {
            padding: 12px 14px;
            color: #333;
            text-align: center;
            border-bottom: 1px solid #f0f0f0;
        }
        .table-card tr:nth-child(even) { background: #fafbfc; }
        .table-card tr:hover { background: #e8f4fd; }
        .table-card tr.deleted { background: #f5f5f5; color: #999; }
        .table-card tr.deleted td { color: #999; }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #bbb;
            font-size: 16px;
        }
        .status-normal { color: #2e7d32; font-weight: 500; }
        .status-deleted { color: #999; }
        .grade-badge {
            display: inline-block;
            padding: 2px 12px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
        }
        .grade-a { background: #e8f5e9; color: #2e7d32; }
        .grade-b { background: #e3f2fd; color: #1565c0; }
        .grade-c { background: #fff8e1; color: #f57f17; }
        .grade-d { background: #ffebee; color: #c62828; }
        .grade-f { background: #f3e5f5; color: #7b1fa2; }

        /* 模态框 */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .modal-overlay.active { display: flex; }
        .modal {
            background: #fff;
            border-radius: 10px;
            width: 100%;
            max-width: 450px;
            padding: 24px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        }
        .modal h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 12px;
            border-bottom: 1px solid #f0f0f0;
        }
        .form-group {
            margin-bottom: 16px;
        }
        .form-group label {
            display: block;
            font-size: 13px;
            color: #555;
            margin-bottom: 6px;
            font-weight: 500;
        }
        .form-group label .required { color: #e53935; margin-left: 2px; }
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 8px 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            font-family: inherit;
        }
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        .modal-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 20px;
            padding-top: 16px;
            border-top: 1px solid #f0f0f0;
        }
        .btn-cancel { background: #f5f5f5; color: #666; border: 1px solid #ddd; }
        .btn-submit { background: #667eea; color: #fff; }

        .help-text {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>管理员控制台 - 等级分值设置</h1>
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
        <h2>等级分值规则（共 <%= gradingList.size() %> 条）</h2>
        <button class="btn btn-primary" onclick="openModal()">&#43; 添加规则</button>
    </div>

    <div class="table-card">
        <% if (gradingList.isEmpty()) { %>
        <div class="empty-state">暂无等级分值规则，请点击"添加规则"创建</div>
        <% } else { %>
        <table>
            <thead>
            <tr>
                <th>等级</th>
                <th>最低分</th>
                <th>最高分</th>
                <th>绩点</th>
                <th>状态</th>
                <th style="width:140px;">操作</th>
            </tr>
            </thead>
            <tbody>
            <% for (Map<String, Object> row : gradingList) {
                String grade = (String) row.get("grade");
                Integer isDeleted = row.get("is_deleted") != null ? ((Number) row.get("is_deleted")).intValue() : 0;
                boolean deleted = isDeleted == 1;
                String badgeClass = "grade-" + grade.toLowerCase();
            %>
            <tr class="<%= deleted ? "deleted" : "" %>">
                <td><span class="grade-badge <%= badgeClass %>"><%= grade %></span></td>
                <td><%= row.get("min_score") %></td>
                <td><%= row.get("max_score") %></td>
                <td><%= row.get("gpa") %></td>
                <td>
                    <% if (deleted) { %>
                    <span class="status-deleted">已删除</span>
                    <% } else { %>
                    <span class="status-normal">正常</span>
                    <% } %>
                </td>
                <td>
                    <% if (deleted) { %>
                    <button class="btn-disabled" disabled>编辑</button>
                    <button class="btn-disabled" disabled>删除</button>
                    <% } else { %>
                    <button class="btn btn-edit" onclick="openEditModal('<%= row.get("id") %>', '<%= grade %>', '<%= row.get("min_score") %>', '<%= row.get("max_score") %>', '<%= row.get("gpa") %>')">编辑</button>
                    <button class="btn btn-delete" onclick="confirmDelete('<%= row.get("id") %>', '<%= grade %>')">删除</button>
                    <% } %>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>
</div>

<!-- 模态框 -->
<div class="modal-overlay" id="modalOverlay">
    <div class="modal">
        <h3 id="modalTitle">添加规则</h3>
        <form id="gradingForm" action="<%= ctx %>/admin/grading" method="post">
            <input type="hidden" name="id" id="formId" value="">

            <div class="form-group">
                <label>等级 <span class="required">*</span></label>
                <select name="grade" id="formGrade" required>
                    <option value="">请选择</option>
                    <option value="A">A</option>
                    <option value="B">B</option>
                    <option value="C">C</option>
                    <option value="D">D</option>
                    <option value="F">F</option>
                </select>
            </div>

            <div class="form-group">
                <label>最低分 <span class="required">*</span></label>
                <input type="number" name="minScore" id="formMinScore" step="0.01" min="0" max="100" required>
                <div class="help-text">0 ~ 100，必须小于最高分</div>
            </div>

            <div class="form-group">
                <label>最高分 <span class="required">*</span></label>
                <input type="number" name="maxScore" id="formMaxScore" step="0.01" min="0" max="100" required>
                <div class="help-text">0 ~ 100，必须大于最低分</div>
            </div>

            <div class="form-group">
                <label>绩点 <span class="required">*</span></label>
                <input type="number" name="gpa" id="formGpa" step="0.01" min="0" max="5" required>
                <div class="help-text">0.00 ~ 5.00</div>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-cancel" onclick="closeModal()">取消</button>
                <button type="submit" class="btn btn-submit" id="submitBtn">确认添加</button>
            </div>
        </form>
    </div>
</div>

<script>
    var modalOverlay = document.getElementById('modalOverlay');
    var modalTitle = document.getElementById('modalTitle');
    var formId = document.getElementById('formId');
    var formGrade = document.getElementById('formGrade');
    var formMinScore = document.getElementById('formMinScore');
    var formMaxScore = document.getElementById('formMaxScore');
    var formGpa = document.getElementById('formGpa');
    var submitBtn = document.getElementById('submitBtn');

    function openModal() {
        modalTitle.textContent = '添加规则';
        formId.value = '';
        formGrade.value = '';
        formMinScore.value = '';
        formMaxScore.value = '';
        formGpa.value = '';
        formGrade.disabled = false;
        submitBtn.textContent = '确认添加';
        modalOverlay.classList.add('active');
    }

    function openEditModal(id, grade, minScore, maxScore, gpa) {
        modalTitle.textContent = '编辑规则';
        formId.value = id;
        formGrade.value = grade;
        formMinScore.value = minScore;
        formMaxScore.value = maxScore;
        formGpa.value = gpa;
        formGrade.disabled = true;
        submitBtn.textContent = '保存修改';
        modalOverlay.classList.add('active');
    }

    function closeModal() {
        modalOverlay.classList.remove('active');
    }

    function confirmDelete(id, grade) {
        if (confirm('确定要删除等级【' + grade + '】的规则吗？')) {
            window.location.href = '<%= ctx %>/admin/grading?action=delete&id=' + id;
        }
    }

    // 点击遮罩层关闭模态框
    modalOverlay.addEventListener('click', function(e) {
        if (e.target === modalOverlay) {
            closeModal();
        }
    });

    // 表单校验
    document.getElementById('gradingForm').addEventListener('submit', function(e) {
        var minScore = parseFloat(formMinScore.value);
        var maxScore = parseFloat(formMaxScore.value);
        if (minScore >= maxScore) {
            alert('最低分必须小于最高分');
            e.preventDefault();
            return false;
        }
    });
</script>
</body>
</html>
