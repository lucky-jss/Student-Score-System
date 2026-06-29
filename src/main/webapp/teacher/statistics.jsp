<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.model.User" %>
<%@ page import="com.score.dao.DB" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    // 权限校验：管理员和教师均可访问
    String role = (String) session.getAttribute("role");
    if (!"admin".equals(role) && !"teacher".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String ctx = request.getContextPath();

    // 获取学期列表和当前学期ID
    List<Map<String, Object>> semesterList = null;
    int currentSemesterId = -1;
    try {
        semesterList = DB.getSemestersRaw();
        currentSemesterId = DB.getCurrentSemesterId();
    } catch (Exception e) {
        semesterList = new java.util.ArrayList<>();
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>统计看板 - 教师工作台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #42a5f5 0%, #1e88e5 100%);
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
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* Tab 样式 */
        .tab-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            background: #fff;
            border-radius: 12px 12px 0 0;
            padding: 12px 16px 0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        .tab-btn {
            padding: 10px 18px;
            border: none;
            background: transparent;
            color: #666;
            font-size: 14px;
            cursor: pointer;
            border-radius: 8px 8px 0 0;
            transition: all 0.2s;
            border-bottom: 2px solid transparent;
        }
        .tab-btn:hover { color: #42a5f5; background: #f5f7fa; }
        .tab-btn.active {
            color: #42a5f5;
            border-bottom: 2px solid #42a5f5;
            background: #f5f7fa;
            font-weight: 600;
        }

        /* 内容区 */
        .tab-content {
            background: #fff;
            border-radius: 0 0 12px 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
            min-height: 400px;
        }
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        /* 筛选区域 */
        .filter-bar {
            display: flex;
            gap: 16px;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .filter-bar label {
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        .filter-bar select {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 160px;
        }
        .filter-bar select:focus { outline: none; border-color: #42a5f5; }
        .btn-query {
            padding: 8px 20px;
            background: #42a5f5;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
        }
        .btn-query:hover { background: #1e88e5; }

        /* 表格 */
        .data-table-wrap { overflow-x: auto; }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        .data-table th {
            background: #f5f7fa;
            padding: 12px 14px;
            text-align: center;
            font-size: 13px;
            color: #666;
            font-weight: 600;
            border: 1px solid #e8e8e8;
            white-space: nowrap;
        }
        .data-table td {
            padding: 10px 14px;
            text-align: center;
            border: 1px solid #e8e8e8;
            color: #333;
        }
        .data-table tbody tr:nth-child(even) { background: #fafbfc; }
        .data-table tbody tr:hover { background: #e3f2fd; }

        /* 状态 */
        .status-msg {
            text-align: center;
            padding: 60px 20px;
            font-size: 15px;
        }
        .status-msg.loading { color: #888; }
        .status-msg.error { color: #c62828; }
        .status-msg.empty { color: #bbb; }
        .loading-spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #e0e0e0;
            border-top-color: #42a5f5;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            vertical-align: middle;
            margin-right: 8px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        .record-count {
            text-align: right;
            font-size: 13px;
            color: #999;
            margin-bottom: 12px;
        }
    </style>
</head>
<body>
<div class="header">
    <h1>统计看板</h1>
    <div class="nav-links">
        <a href="<%= ctx %>/teacher/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <!-- Tab 栏（6 个） -->
    <div class="tab-bar" id="tabBar">
        <button class="tab-btn active" data-tab="department">系部统计</button>
        <button class="tab-btn" data-tab="major">专业统计</button>
        <button class="tab-btn" data-tab="class">班级统计</button>
        <button class="tab-btn" data-tab="subject">科目统计</button>
        <button class="tab-btn" data-tab="grade-distribution">等级分布</button>
        <button class="tab-btn" data-tab="score-distribution">分数分布</button>
    </div>

    <!-- 内容区 -->
    <div class="tab-content">

        <!-- 系部统计 -->
        <div class="tab-panel active" id="panel-department">
            <div class="record-count" id="count-department"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-department"></table></div>
        </div>

        <!-- 专业统计 -->
        <div class="tab-panel" id="panel-major">
            <div class="record-count" id="count-major"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-major"></table></div>
        </div>

        <!-- 班级统计 -->
        <div class="tab-panel" id="panel-class">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="class-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <button class="btn-query" onclick="loadClass()">查询</button>
            </div>
            <div class="record-count" id="count-class"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-class"></table></div>
        </div>

        <!-- 科目统计 -->
        <div class="tab-panel" id="panel-subject">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="subject-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <button class="btn-query" onclick="loadSubject()">查询</button>
            </div>
            <div class="record-count" id="count-subject"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-subject"></table></div>
        </div>

        <!-- 等级分布 -->
        <div class="tab-panel" id="panel-grade-distribution">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="grade-distribution-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <button class="btn-query" onclick="loadGradeDistribution()">查询</button>
            </div>
            <div class="record-count" id="count-grade-distribution"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-grade-distribution"></table></div>
        </div>

        <!-- 分数分布 -->
        <div class="tab-panel" id="panel-score-distribution">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="score-distribution-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <button class="btn-query" onclick="loadScoreDistribution()">查询</button>
            </div>
            <div class="record-count" id="count-score-distribution"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-score-distribution"></table></div>
        </div>

    </div>
</div>

<script>
    var ctx = '<%= ctx %>';
    var teacherDeptId = <%= session.getAttribute("user") != null ? ((com.score.model.User)session.getAttribute("user")).getDepartmentId() : 0 %>;
    var currentTab = 'department';
    var loadedTabs = {};

    // ==================== Tab 切换 ====================
    document.getElementById('tabBar').addEventListener('click', function(e) {
        var btn = e.target.closest('.tab-btn');
        if (!btn) return;
        var tab = btn.getAttribute('data-tab');
        switchTab(tab);
    });

    function switchTab(tab) {
        currentTab = tab;
        var btns = document.querySelectorAll('.tab-btn');
        for (var i = 0; i < btns.length; i++) {
            btns[i].classList.toggle('active', btns[i].getAttribute('data-tab') === tab);
        }
        var panels = document.querySelectorAll('.tab-panel');
        for (var i = 0; i < panels.length; i++) {
            panels[i].classList.toggle('active', panels[i].id === 'panel-' + tab);
        }
        if (!loadedTabs[tab]) {
            loadTab(tab);
        }
    }

    // ==================== 加载 Tab 数据 ====================
    function loadTab(tab) {
        switch(tab) {
            case 'department': loadDepartment(); break;
            case 'major': loadMajor(); break;
            case 'class': loadClass(); break;
            case 'subject': loadSubject(); break;
            case 'grade-distribution': loadGradeDistribution(); break;
            case 'score-distribution': loadScoreDistribution(); break;
        }
    }

    // ==================== 通用数据加载（带系部过滤） ====================
    function fetchApi(apiPath, callback) {
        var tableId = 'table-' + currentTab;
        var countId = 'count-' + currentTab;
        var table = document.getElementById(tableId);
        var countEl = document.getElementById(countId);
        table.innerHTML = '<tr><td colspan="100" class="status-msg loading"><span class="loading-spinner"></span>加载中...</td></tr>';
        countEl.textContent = '';

        var url = ctx + '/statistics' + apiPath;
        fetch(url)
            .then(function(res) { return res.json(); })
            .then(function(json) {
                loadedTabs[currentTab] = true;
                if (json.error) {
                    table.innerHTML = '<tr><td colspan="100" class="status-msg error">' + escapeHtml(json.error) + '</td></tr>';
                    return;
                }
                var data = json.data || [];
                data = filterByDept(data, currentTab);
                countEl.textContent = '共 ' + data.length + ' 条记录';
                if (data.length === 0) {
                    table.innerHTML = '<tr><td colspan="100" class="status-msg empty">暂无数据</td></tr>';
                    return;
                }
                renderTable(table, data);
                if (callback) callback(data);
            })
            .catch(function(err) {
                table.innerHTML = '<tr><td colspan="100" class="status-msg error">请求失败：' + escapeHtml(err.message) + '</td></tr>';
            });
    }

    function filterByDept(data, tab) {
        if (teacherDeptId <= 0) return data;
        // 系部统计：后端 /department 不支持 departmentId 参数，前端兜底过滤
        if (tab === 'department') {
            var deptIdStr = String(teacherDeptId);
            return data.filter(function(row) {
                return String(row.department_id || row.id) === deptIdStr;
            });
        }
        // 其他 Tab 后端 API 已支持 departmentId 参数过滤，无需前端二次过滤
        return data;
    }

    function renderTable(table, data) {
        var cols = Object.keys(data[0]);
        var html = '<thead><tr>';
        for (var i = 0; i < cols.length; i++) {
            html += '<th>' + formatColName(cols[i]) + '</th>';
        }
        html += '</tr></thead><tbody>';
        for (var r = 0; r < data.length; r++) {
            html += '<tr>';
            for (var c = 0; c < cols.length; c++) {
                var val = data[r][cols[c]];
                html += '<td>' + (val !== null && val !== undefined ? escapeHtml(String(val)) : '-') + '</td>';
            }
            html += '</tr>';
        }
        html += '</tbody>';
        table.innerHTML = html;
    }

    function formatColName(col) {
        var map = {
            'department_id': '系部ID', 'department_name': '系部名称',
            'major_id': '专业ID', 'major_name': '专业名称', 'major_code': '专业编码',
            'class_id': '班级ID', 'class_name': '班级名称',
            'subject_id': '科目ID', 'subject_name': '科目名称', 'subject_code': '科目编码', 'credit': '学分',
            'semester_id': '学期ID', 'semester_name': '学期名称',
            'student_id': '学生ID', 'student_no': '学号', 'student_name': '姓名', 'name': '姓名',
            'class_name': '班级', 'gender': '性别',
            'score': '分数', 'avg_score': '平均分', 'max_score': '最高分', 'min_score': '最低分',
            'total_score': '总分', 'count': '人数', 'student_count': '学生数', 'score_count': '成绩数',
            'grade': '等级', 'grade_count': '人数',
            'score_range': '分数段', 'range_count': '人数',
            'gpa': 'GPA', 'total_credits': '总学分',
            'rank': '排名', 'grade_rank': '年级排名', 'class_rank': '班级排名',
            'dense_rank': '密集排名', 'row_num': '行号',
            'q1': 'Q1(25%)', 'q2': 'Q2(中位数)', 'q3': 'Q3(75%)',
            'iqr': '四分位距', 'lower_bound': '下界', 'upper_bound': '上界',
            'subject_count': '科目数', 'avg': '平均分', 'min': '最低分', 'max': '最高分'
        };
        return map[col] || col.replace(/_/g, ' ');
    }

    function escapeHtml(str) {
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    }

    // ==================== 各 Tab 加载方法 ====================
    function loadDepartment() {
        if (teacherDeptId > 0) {
            fetchApi('/department?departmentId=' + teacherDeptId);
        } else {
            fetchApi('/department');
        }
    }

    function loadMajor() {
        fetchApi('/major?departmentId=' + teacherDeptId);
    }

    function loadClass() {
        var semesterId = document.getElementById('class-semester-select').value;
        var params = 'departmentId=' + teacherDeptId;
        if (semesterId) params += '&semesterId=' + semesterId;
        fetchApi('/class?' + params);
    }

    function loadSubject() {
        var semesterId = document.getElementById('subject-semester-select').value;
        var params = 'departmentId=' + teacherDeptId;
        if (semesterId) params += '&semesterId=' + semesterId;
        fetchApi('/subject?' + params);
    }

    function loadGradeDistribution() {
        var semesterId = document.getElementById('grade-distribution-semester-select').value;
        var params = 'departmentId=' + teacherDeptId;
        if (semesterId) params += '&semesterId=' + semesterId;
        fetchApi('/grade-distribution?' + params);
    }

    function loadScoreDistribution() {
        var semesterId = document.getElementById('score-distribution-semester-select').value;
        var params = 'departmentId=' + teacherDeptId;
        if (semesterId) params += '&semesterId=' + semesterId;
        fetchApi('/score-distribution?' + params);
    }

    // ==================== 初始化 ====================
    document.addEventListener('DOMContentLoaded', function() {
        loadTab('department');
    });
</script>
</body>
</html>
