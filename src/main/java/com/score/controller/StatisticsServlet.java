package com.score.controller;

import com.score.service.StatisticsService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
// ... 其他不变

import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/statistics/*")
public class StatisticsServlet extends HttpServlet {

    private ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        String pathInfo = request.getPathInfo();

        try {
            Map<String, Object> result = new HashMap<>();

            if (pathInfo == null || pathInfo.equals("/")) {
                result.put("error", "请指定统计类型");
                response.getWriter().write(objectMapper.writeValueAsString(result));
                return;
            }

            Integer semesterId = getIntParameter(request, "semesterId");

            switch (pathInfo) {
                case "/department":
                    List<Map<String, Object>> deptStats = StatisticsService.getDepartmentStatistics(semesterId);
                    result.put("data", deptStats);
                    result.put("count", deptStats.size());
                    break;

                case "/major":
                    Integer deptId = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> majorStats = StatisticsService.getMajorStatistics(semesterId, deptId);
                    result.put("data", majorStats);
                    result.put("count", majorStats.size());
                    break;

                case "/class":
                    Integer majorId = getIntParameter(request, "majorId");
                    Integer deptIdForClass = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> classStats = StatisticsService.getClassStatistics(semesterId, majorId, deptIdForClass);
                    result.put("data", classStats);
                    result.put("count", classStats.size());
                    break;

                case "/subject":
                    Integer deptIdForSubject = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> subjectStats = StatisticsService.getSubjectStatistics(semesterId, deptIdForSubject);
                    result.put("data", subjectStats);
                    result.put("count", subjectStats.size());
                    break;

                case "/ranking":
                    Integer classId = getIntParameter(request, "classId");
                    Integer deptIdForRank = getIntParameter(request, "departmentId");
                    Integer majorIdForRank = getIntParameter(request, "majorId");
                    List<Map<String, Object>> ranking = StatisticsService.getStudentRanking(classId, semesterId, deptIdForRank, majorIdForRank);
                    result.put("data", ranking);
                    result.put("count", ranking.size());
                    break;

                case "/grade-distribution":
                    Integer deptIdForGrade = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> gradeDist = StatisticsService.getGradeDistribution(semesterId, deptIdForGrade);
                    result.put("data", gradeDist);
                    result.put("count", gradeDist.size());
                    break;

                case "/gpa":
                    Integer studentId = getIntParameter(request, "studentId");
                    List<Map<String, Object>> gpa = StatisticsService.calculateGPA(studentId, semesterId);
                    result.put("data", gpa);
                    result.put("count", gpa.size());
                    break;

                case "/gpa-batch":
                    Integer deptIdForGpa = getIntParameter(request, "departmentId");
                    Integer majorIdForGpa = getIntParameter(request, "majorId");
                    Integer classIdForGpa = getIntParameter(request, "classId");
                    List<Map<String, Object>> batchGpa = StatisticsService.getBatchGpa(semesterId, deptIdForGpa, majorIdForGpa, classIdForGpa);
                    result.put("data", batchGpa);
                    result.put("count", batchGpa.size());
                    break;

                case "/quartile":
                    Integer subjectId = getIntParameter(request, "subjectId");
                    Integer deptIdForQuartile = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> quartile = StatisticsService.getQuartileAnalysis(subjectId, semesterId, deptIdForQuartile);
                    result.put("data", quartile);
                    result.put("count", quartile.size());
                    break;

                case "/score-distribution":
                    Integer deptIdForScoreDist = getIntParameter(request, "departmentId");
                    List<Map<String, Object>> scoreDist = StatisticsService.getScoreDistribution(semesterId, deptIdForScoreDist);
                    result.put("data", scoreDist);
                    result.put("count", scoreDist.size());
                    break;

                case "/detailed-ranking":
                    Integer detailClassId = getIntParameter(request, "classId");
                    Integer deptIdForDetail = getIntParameter(request, "departmentId");
                    Integer majorIdForDetail = getIntParameter(request, "majorId");
                    List<Map<String, Object>> detailedRanking = StatisticsService.getStudentScoreRanking(detailClassId, semesterId, deptIdForDetail, majorIdForDetail);
                    result.put("data", detailedRanking);
                    result.put("count", detailedRanking.size());
                    break;

                default:
                    result.put("error", "未知的统计类型: " + pathInfo);
            }

            response.getWriter().write(objectMapper.writeValueAsString(result));

        } catch (SQLException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "数据库查询失败: " + e.getMessage());
            response.getWriter().write(objectMapper.writeValueAsString(error));
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private Integer getIntParameter(HttpServletRequest request, String paramName) {
        String param = request.getParameter(paramName);
        if (param == null || param.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(param);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
