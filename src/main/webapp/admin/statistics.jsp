<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.score.dao.DB" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    // 权限校验：只有管理员能访问
    String role = (String) session.getAttribute("role");
    if (!"admin".equals(role)) {
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
    <title>统计看板 - 管理员控制台</title>
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
        .tab-btn:hover { color: #667eea; background: #f5f7fa; }
        .tab-btn.active {
            color: #667eea;
            border-bottom: 2px solid #667eea;
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
        .filter-bar select:focus { outline: none; border-color: #667eea; }
        .btn-query {
            padding: 8px 20px;
            background: #667eea;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
        }
        .btn-query:hover { background: #5a6fd6; }

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
        .data-table tbody tr:hover { background: #eef0ff; }

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
            border-top-color: #667eea;
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
        <a href="<%= ctx %>/admin/index.jsp">返回首页</a>
        <a href="<%= ctx %>/logout">退出登录</a>
    </div>
</div>

<div class="container">
    <!-- Tab 栏 -->
    <div class="tab-bar" id="tabBar">
        <button class="tab-btn active" data-tab="department">系部统计</button>
        <button class="tab-btn" data-tab="major">专业统计</button>
        <button class="tab-btn" data-tab="class">班级统计</button>
        <button class="tab-btn" data-tab="subject">科目统计</button>
        <button class="tab-btn" data-tab="grade-distribution">等级分布</button>
        <button class="tab-btn" data-tab="score-distribution">分数分布</button>
        <button class="tab-btn" data-tab="gpa">GPA 统计</button>
        <button class="tab-btn" data-tab="ranking">排名</button>
        <button class="tab-btn" data-tab="quartile">四分位分析</button>
        <button class="tab-btn" data-tab="detailed-ranking">详细排名</button>
    </div>

    <!-- 内容区 -->
    <div class="tab-content">

        <!-- 系部统计 -->
        <div class="tab-panel active" id="panel-department">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="department-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <button class="btn-query" onclick="loadDepartment()">查询</button>
            </div>
            <div class="record-count" id="count-department"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-department"></table></div>
        </div>

        <!-- 专业统计 -->
        <div class="tab-panel" id="panel-major">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="major-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <label>选择系部：</label>
                <select id="major-dept-select">
                    <option value="">-- 全部系部 --</option>
                </select>
                <button class="btn-query" onclick="loadMajor()">查询</button>
            </div>
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
                <label>选择系部：</label>
                <select id="class-dept-select" onchange="onDeptChange('class')">
                    <option value="">-- 全部系部 --</option>
                </select>
                <label>选择专业：</label>
                <select id="class-major-select">
                    <option value="">-- 全部专业 --</option>
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
                <label>选择系部：</label>
                <select id="subject-dept-select">
                    <option value="">-- 全部系部 --</option>
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
                <label>选择系部：</label>
                <select id="grade-distribution-dept-select">
                    <option value="">-- 全部系部 --</option>
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
                <label>选择系部：</label>
                <select id="score-distribution-dept-select">
                    <option value="">-- 全部系部 --</option>
                </select>
                <button class="btn-query" onclick="loadScoreDistribution()">查询</button>
            </div>
            <div class="record-count" id="count-score-distribution"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-score-distribution"></table></div>
        </div>

        <!-- GPA 统计 -->
        <div class="tab-panel" id="panel-gpa">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="gpa-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <label>选择系部：</label>
                <select id="gpa-dept-select" onchange="loadMajorForGpa()">
                    <option value="">-- 全部系部 --</option>
                </select>
                <label>选择专业：</label>
                <select id="gpa-major-select" onchange="loadClassForGpa()">
                    <option value="">-- 全部专业 --</option>
                </select>
                <label>选择班级：</label>
                <select id="gpa-class-select">
                    <option value="">-- 全部班级 --</option>
                </select>
                <button class="btn-query" onclick="loadGpa()">查询</button>
                <button class="btn-query" style="background:#52c41a" onclick="exportGpaCsv()">导出CSV</button>
            </div>
            <div class="record-count" id="count-gpa"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-gpa"></table></div>
        </div>

        <!-- 排名 -->
        <div class="tab-panel" id="panel-ranking">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="ranking-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <label>选择系部：</label>
                <select id="ranking-dept-select" onchange="onDeptChange('ranking')">
                    <option value="">-- 全部系部 --</option>
                </select>
                <label>选择专业：</label>
                <select id="ranking-major-select" onchange="onMajorChange('ranking')">
                    <option value="">-- 全部专业 --</option>
                </select>
                <label>选择班级：</label>
                <select id="ranking-class-select">
                    <option value="">-- 全部班级 --</option>
                </select>
                <button class="btn-query" onclick="loadRanking()">查询</button>
            </div>
            <div class="record-count" id="count-ranking"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-ranking"></table></div>
        </div>

        <!-- 四分位分析 -->
        <div class="tab-panel" id="panel-quartile">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="quartile-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <label>选择系部：</label>
                <select id="quartile-dept-select">
                    <option value="">-- 全部系部 --</option>
                </select>
                <button class="btn-query" onclick="loadQuartile()">查询</button>
            </div>
            <div class="record-count" id="count-quartile"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-quartile"></table></div>
        </div>

        <!-- 详细排名 -->
        <div class="tab-panel" id="panel-detailed-ranking">
            <div class="filter-bar">
                <label>选择学期：</label>
                <select id="detailed-ranking-semester-select">
                    <option value="">-- 全部学期 --</option>
                    <% for (Map<String, Object> sem : semesterList) { %>
                    <option value="<%= sem.get("id") %>" <%= ((Number)sem.get("id")).intValue() == currentSemesterId ? "selected" : "" %>><%= sem.get("semester_name") %></option>
                    <% } %>
                </select>
                <label>选择系部：</label>
                <select id="detailed-ranking-dept-select" onchange="onDeptChange('detailed-ranking')">
                    <option value="">-- 全部系部 --</option>
                </select>
                <label>选择专业：</label>
                <select id="detailed-ranking-major-select" onchange="onMajorChange('detailed-ranking')">
                    <option value="">-- 全部专业 --</option>
                </select>
                <label>选择班级：</label>
                <select id="detailed-ranking-class-select">
                    <option value="">-- 全部班级 --</option>
                </select>
                <button class="btn-query" onclick="loadDetailedRanking()">查询</button>
            </div>
            <div class="record-count" id="count-detailed-ranking"></div>
            <div class="data-table-wrap"><table class="data-table" id="table-detailed-ranking"></table></div>
        </div>

    </div>
</div>

<script>
    var ctx = '<%= ctx %>';
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
        // 切换按钮样式
        var btns = document.querySelectorAll('.tab-btn');
        for (var i = 0; i < btns.length; i++) {
            btns[i].classList.toggle('active', btns[i].getAttribute('data-tab') === tab);
        }
        // 切换面板
        var panels = document.querySelectorAll('.tab-panel');
        for (var i = 0; i < panels.length; i++) {
            panels[i].classList.toggle('active', panels[i].id === 'panel-' + tab);
        }
        // 首次切换时加载数据
        if (!loadedTabs[tab]) {
            loadTab(tab);
        }
    }

    // ==================== 加载 Tab 数据 ====================
    function loadTab(tab) {
        switch(tab) {
            case 'department': loadDepartmentOptions([tab + '-dept-select']); loadDepartment(); break;
            case 'major': loadDepartmentOptions([tab + '-dept-select']); loadMajor(); break;
            case 'class': loadDepartmentOptions([tab + '-dept-select']); loadClass(); break;
            case 'subject': loadDepartmentOptions([tab + '-dept-select']); loadSubject(); break;
            case 'grade-distribution': loadDepartmentOptions([tab + '-dept-select']); loadGradeDistribution(); break;
            case 'score-distribution': loadDepartmentOptions([tab + '-dept-select']); loadScoreDistribution(); break;
            case 'gpa': loadDepartmentOptions([tab + '-dept-select']); loadGpa(); break;
            case 'ranking': loadDepartmentOptions([tab + '-dept-select']); loadRanking(); break;
            case 'quartile': loadDepartmentOptions([tab + '-dept-select']); loadQuartile(); break;
            case 'detailed-ranking': loadDepartmentOptions([tab + '-dept-select']); loadDetailedRanking(); break;
        }
    }

    // ==================== 通用数据加载 ====================
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

    // ==================== 通用 API 路径构建 ====================
    function buildApiPath(tab) {
        var params = [];
        var semesterSel = document.getElementById(tab + '-semester-select');
        if (semesterSel && semesterSel.value) {
            params.push('semesterId=' + semesterSel.value);
        }
        var deptSel = document.getElementById(tab + '-dept-select');
        if (deptSel && deptSel.value) {
            params.push('departmentId=' + deptSel.value);
        }
        var majorSel = document.getElementById(tab + '-major-select');
        if (majorSel && majorSel.value) {
            params.push('majorId=' + majorSel.value);
        }
        var classSel = document.getElementById(tab + '-class-select');
        if (classSel && classSel.value) {
            params.push('classId=' + classSel.value);
        }
        var path = '/' + tab;
        if (tab === 'gpa') path = '/gpa-batch';
        if (params.length > 0) path += '?' + params.join('&');
        return path;
    }

    // ==================== 各 Tab 加载方法 ====================
    function loadDepartment() {
        fetchApi(buildApiPath('department'));
    }

    function loadMajor() {
        fetchApi(buildApiPath('major'));
    }

    function loadClass() {
        fetchApi(buildApiPath('class'));
    }

    function loadSubject() {
        fetchApi(buildApiPath('subject'));
    }

    function loadGradeDistribution() {
        fetchApi(buildApiPath('grade-distribution'));
    }

    function loadScoreDistribution() {
        fetchApi(buildApiPath('score-distribution'));
    }

    function loadGpa() {
        fetchApi(buildApiPath('gpa'));
    }

    function loadRanking() {
        fetchApi(buildApiPath('ranking'));
    }

    function loadQuartile() {
        fetchApi(buildApiPath('quartile'));
    }

    function loadDetailedRanking() {
        fetchApi(buildApiPath('detailed-ranking'));
    }

    // ==================== 下拉选项加载 ====================
    function loadDepartmentOptions(selectIds) {
        if (!selectIds) selectIds = [];
        if (window._deptOptionsLoaded) {
            fillDeptSelectsByIds(selectIds, window._deptOptions);
            return;
        }
        fetch(ctx + '/statistics/department')
            .then(function(res) { return res.json(); })
            .then(function(json) {
                window._deptOptionsLoaded = true;
                window._deptOptions = json.data || [];
                fillDeptSelectsByIds(selectIds, window._deptOptions);
            })
            .catch(function() {});
    }

    function fillDeptSelectsByIds(ids, depts) {
        for (var s = 0; s < ids.length; s++) {
            var sel = document.getElementById(ids[s]);
            if (!sel || sel.dataset.filled) continue;
            var html = '<option value="">-- 全部系部 --</option>';
            for (var i = 0; i < depts.length; i++) {
                var name = depts[i].department_name || depts[i].name || depts[i].dept_name || depts[i].department_id;
                var id = depts[i].department_id || depts[i].id;
                html += '<option value="' + id + '">' + escapeHtml(name) + '</option>';
            }
            sel.innerHTML = html;
            sel.dataset.filled = '1';
        }
    }

    function onDeptChange(tab) {
        var majorSel = document.getElementById(tab + '-major-select');
        var classSel = document.getElementById(tab + '-class-select');
        var deptId = document.getElementById(tab + '-dept-select').value;
        if (majorSel) {
            if (!deptId) {
                majorSel.innerHTML = '<option value="">-- 全部专业 --</option>';
            } else {
                fetch(ctx + '/statistics/major?departmentId=' + deptId)
                    .then(function(res) { return res.json(); })
                    .then(function(json) {
                        var data = json.data || [];
                        var html = '<option value="">-- 全部专业 --</option>';
                        for (var i = 0; i < data.length; i++) {
                            var name = data[i].major_name || data[i].name || data[i].major_id;
                            var id = data[i].major_id || data[i].id;
                            html += '<option value="' + id + '">' + escapeHtml(name) + '</option>';
                        }
                        majorSel.innerHTML = html;
                    })
                    .catch(function() {});
            }
        }
        if (classSel) {
            classSel.innerHTML = '<option value="">-- 全部班级 --</option>';
        }
    }

    function onMajorChange(tab) {
        var classSel = document.getElementById(tab + '-class-select');
        var deptId = document.getElementById(tab + '-dept-select').value;
        var majorId = document.getElementById(tab + '-major-select').value;
        if (!classSel) return;
        if (!majorId) {
            if (deptId) {
                fetch(ctx + '/statistics/class?departmentId=' + deptId)
                    .then(function(res) { return res.json(); })
                    .then(function(json) {
                        var data = json.data || [];
                        var html = '<option value="">-- 全部班级 --</option>';
                        for (var i = 0; i < data.length; i++) {
                            var name = data[i].class_name || data[i].class_id;
                            var id = data[i].class_id || data[i].id;
                            html += '<option value="' + id + '">' + escapeHtml(name) + '</option>';
                        }
                        classSel.innerHTML = html;
                    })
                    .catch(function() {});
            } else {
                classSel.innerHTML = '<option value="">-- 全部班级 --</option>';
            }
            return;
        }
        fetch(ctx + '/statistics/class?departmentId=' + deptId + '&majorId=' + majorId)
            .then(function(res) { return res.json(); })
            .then(function(json) {
                var data = json.data || [];
                var html = '<option value="">-- 全部班级 --</option>';
                for (var i = 0; i < data.length; i++) {
                    var name = data[i].class_name || data[i].class_id;
                    var id = data[i].class_id || data[i].id;
                    html += '<option value="' + id + '">' + escapeHtml(name) + '</option>';
                }
                classSel.innerHTML = html;
            })
            .catch(function() {});
    }

    function exportGpaCsv() {
        var table = document.getElementById('table-gpa');
        var rows = table.querySelectorAll('tbody tr');
        if (rows.length === 0 || rows[0].querySelector('.status-msg')) {
            alert('暂无数据可导出，请先查询');
            return;
        }
        var csv = '\uFEFF'; // BOM for Excel
        var ths = table.querySelectorAll('thead th');
        var headerArr = [];
        for (var i = 0; i < ths.length; i++) {
            headerArr.push('"' + ths[i].textContent.replace(/"/g, '""') + '"');
        }
        csv += headerArr.join(',') + '\n';
        for (var r = 0; r < rows.length; r++) {
            var tds = rows[r].querySelectorAll('td');
            var rowArr = [];
            for (var c = 0; c < tds.length; c++) {
                rowArr.push('"' + tds[c].textContent.replace(/"/g, '""') + '"');
            }
            csv += rowArr.join(',') + '\n';
        }
        var blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
        var link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = 'GPA统计_' + new Date().toISOString().slice(0, 10) + '.csv';
        link.click();
    }

    // ==================== 初始化 ====================
    document.addEventListener('DOMContentLoaded', function() {
        loadTab('department');
    });
</script>
</body>
</html>
