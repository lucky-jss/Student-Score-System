package com.score.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 等级分值设置实体类，对应 grading_settings 表。
 */
public class GradingSetting {

    private Integer id;
    private Integer subjectId;
    private Integer semesterId;
    private String grade;
    private BigDecimal minScore;
    private BigDecimal maxScore;
    private BigDecimal gpa;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public GradingSetting() {
    }

    public GradingSetting(Integer id, Integer subjectId, Integer semesterId, String grade,
                          BigDecimal minScore, BigDecimal maxScore, BigDecimal gpa,
                          Boolean isDeleted, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.subjectId = subjectId;
        this.semesterId = semesterId;
        this.grade = grade;
        this.minScore = minScore;
        this.maxScore = maxScore;
        this.gpa = gpa;
        this.isDeleted = isDeleted;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getSubjectId() {
        return subjectId;
    }

    public void setSubjectId(Integer subjectId) {
        this.subjectId = subjectId;
    }

    public Integer getSemesterId() {
        return semesterId;
    }

    public void setSemesterId(Integer semesterId) {
        this.semesterId = semesterId;
    }

    public String getGrade() {
        return grade;
    }

    public void setGrade(String grade) {
        this.grade = grade;
    }

    public BigDecimal getMinScore() {
        return minScore;
    }

    public void setMinScore(BigDecimal minScore) {
        this.minScore = minScore;
    }

    public BigDecimal getMaxScore() {
        return maxScore;
    }

    public void setMaxScore(BigDecimal maxScore) {
        this.maxScore = maxScore;
    }

    public BigDecimal getGpa() {
        return gpa;
    }

    public void setGpa(BigDecimal gpa) {
        this.gpa = gpa;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "GradingSetting{" +
                "id=" + id +
                ", subjectId=" + subjectId +
                ", semesterId=" + semesterId +
                ", grade='" + grade + '\'' +
                ", minScore=" + minScore +
                ", maxScore=" + maxScore +
                ", gpa=" + gpa +
                ", isDeleted=" + isDeleted +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}