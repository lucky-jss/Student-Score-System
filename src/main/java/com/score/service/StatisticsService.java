package com.score.service;

import com.score.dao.DB;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class StatisticsService {

    public static List<Map<String, Object>> getDepartmentStatistics(Integer semesterId) throws SQLException {
        String sql = "{call sp_stat_by_department(?)}";
        return DB.callProcedureQuery(sql, semesterId);
    }

    public static List<Map<String, Object>> getMajorStatistics(Integer semesterId, Integer departmentId) throws SQLException {
        String sql = "{call sp_stat_by_major(?, ?)}";
        return DB.callProcedureQuery(sql, semesterId, departmentId);
    }

    public static List<Map<String, Object>> getClassStatistics(Integer semesterId, Integer majorId, Integer departmentId) throws SQLException {
        String sql = "{call sp_stat_by_class(?, ?, ?)}";
        return DB.callProcedureQuery(sql, semesterId, majorId, departmentId);
    }

    public static List<Map<String, Object>> getSubjectStatistics(Integer semesterId, Integer departmentId) throws SQLException {
        String sql = "{call sp_stat_by_subject(?, ?)}";
        return DB.callProcedureQuery(sql, semesterId, departmentId);
    }

    public static List<Map<String, Object>> getStudentRanking(Integer classId, Integer semesterId, Integer departmentId, Integer majorId) throws SQLException {
        String sql = "{call sp_student_ranking(?, ?, ?, ?)}";
        return DB.callProcedureQuery(sql, classId, semesterId, departmentId, majorId);
    }

    public static List<Map<String, Object>> getGradeDistribution(Integer semesterId, Integer departmentId) throws SQLException {
        String sql = "{call sp_score_grade_distribution(?, ?)}";
        return DB.callProcedureQuery(sql, semesterId, departmentId);
    }

    public static List<Map<String, Object>> calculateGPA(Integer studentId, Integer semesterId) throws SQLException {
        String sql = "{call sp_calculate_gpa(?, ?)}";
        return DB.callProcedureQuery(sql, studentId, semesterId);
    }

    public static List<Map<String, Object>> getQuartileAnalysis(Integer subjectId, Integer semesterId, Integer departmentId) throws SQLException {
        String sql = "{call sp_score_quartile_analysis(?, ?, ?)}";
        return DB.callProcedureQuery(sql, subjectId, semesterId, departmentId);
    }

    public static List<Map<String, Object>> getBatchGpa(Integer semesterId, Integer departmentId, Integer majorId, Integer classId) throws SQLException {
        String sql = "{call sp_batch_gpa_stat(?, ?, ?, ?)}";
        return DB.callProcedureQuery(sql, semesterId, departmentId, majorId, classId);
    }

    public static List<Map<String, Object>> getStudentScoreRanking(Integer classId, Integer semesterId, Integer departmentId, Integer majorId) throws SQLException {
        String sql = "SELECT " +
                "t.student_id, " +
                "t.student_no, " +
                "t.name, " +
                "t.class_name, " +
                "t.avg_score, " +
                "RANK() OVER (PARTITION BY t.class_id ORDER BY t.avg_score DESC) AS rank_with_gap, " +
                "DENSE_RANK() OVER (PARTITION BY t.class_id ORDER BY t.avg_score DESC) AS dense_rank_num, " +
                "ROW_NUMBER() OVER (PARTITION BY t.class_id ORDER BY t.avg_score DESC) AS row_num, " +
                "PERCENT_RANK() OVER (PARTITION BY t.class_id ORDER BY t.avg_score DESC) * 100 AS percentile_in_class " +
                "FROM (" +
                "    SELECT " +
                "        s.id AS student_id, " +
                "        s.student_no, " +
                "        s.name, " +
                "        c.id AS class_id, " +
                "        c.class_name, " +
                "        ROUND(AVG(sc.score), 2) AS avg_score " +
                "    FROM students s " +
                "    LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0 " +
                "    LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0 " +
                "    LEFT JOIN scores sc ON s.id = sc.student_id AND sc.is_deleted = 0 " +
                "    WHERE s.is_deleted = 0 AND s.status = 1 " +
                "    AND (? IS NULL OR s.class_id = ?) " +
                "    AND (? IS NULL OR sc.semester_id = ?) " +
                "    AND (? IS NULL OR m.department_id = ?) " +
                "    AND (? IS NULL OR c.major_id = ?) " +
                "    GROUP BY s.id, s.student_no, s.name, c.id, c.class_name " +
                ") t " +
                "ORDER BY t.class_id, t.avg_score DESC";
        return DB.executeQuery(sql, classId, classId, semesterId, semesterId, departmentId, departmentId, majorId, majorId);
    }

    public static List<Map<String, Object>> getScoreDistribution(Integer semesterId, Integer departmentId) throws SQLException {
        String sql = "SELECT " +
                "ntile_group, " +
                "CONCAT('区间', ntile_group) AS group_name, " +
                "MIN(score) AS min_score, " +
                "MAX(score) AS max_score, " +
                "ROUND(AVG(score), 2) AS avg_score, " +
                "COUNT(*) AS count " +
                "FROM ( " +
                "    SELECT " +
                "        sc.score, " +
                "        NTILE(5) OVER (ORDER BY sc.score) AS ntile_group " +
                "    FROM scores sc " +
                "    LEFT JOIN students s ON sc.student_id = s.id AND s.is_deleted = 0 " +
                "    LEFT JOIN classes c ON s.class_id = c.id AND c.is_deleted = 0 " +
                "    LEFT JOIN majors m ON c.major_id = m.id AND m.is_deleted = 0 " +
                "    WHERE sc.is_deleted = 0 " +
                "    AND (? IS NULL OR sc.semester_id = ?) " +
                "    AND (? IS NULL OR m.department_id = ?) " +
                ") AS score_groups " +
                "GROUP BY ntile_group " +
                "ORDER BY ntile_group";
        return DB.executeQuery(sql, semesterId, semesterId, departmentId, departmentId);
    }
}
