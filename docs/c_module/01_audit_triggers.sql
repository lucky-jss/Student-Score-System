-- =========================================
-- C模块：成绩审计触发器（INSERT）
-- =========================================

DROP TRIGGER IF EXISTS trg_scores_insert;
DELIMITER //
CREATE TRIGGER trg_scores_insert AFTER INSERT ON scores FOR EACH ROW
    INSERT INTO audit_log (
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        ip_address
    )
    VALUES (
               COALESCE(NEW.recorded_by, @current_user_id, 0),
               'INSERT',
               'scores',
               NEW.id,
               NULL,
               JSON_OBJECT(
                       'student_id', NEW.student_id,
                       'subject_id', NEW.subject_id,
                       'semester_id', NEW.semester_id,
                       'score', NEW.score,
                       'grade', NEW.grade
               ),
               '127.0.0.1'
           ) //
DELIMITER ;
-- =========================================
-- C模块：成绩审计触发器（UPDATE）
-- =========================================

DROP TRIGGER IF EXISTS trg_scores_update;
DELIMITER //
CREATE TRIGGER trg_scores_update AFTER UPDATE ON scores FOR EACH ROW
    INSERT INTO audit_log (
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        ip_address
    )
    VALUES (
               COALESCE(NEW.recorded_by, @current_user_id, 0),
               'UPDATE',
               'scores',
               NEW.id,
               JSON_OBJECT(
                       'student_id', OLD.student_id,
                       'subject_id', OLD.subject_id,
                       'semester_id', OLD.semester_id,
                       'score', OLD.score,
                       'grade', OLD.grade
               ),
               JSON_OBJECT(
                       'student_id', NEW.student_id,
                       'subject_id', NEW.subject_id,
                       'semester_id', NEW.semester_id,
                       'score', NEW.score,
                       'grade', NEW.grade
               ),
               '127.0.0.1'
           ) //
DELIMITER ;
-- =========================================
-- C模块：成绩审计触发器（DELETE）
-- =========================================

DROP TRIGGER IF EXISTS trg_scores_delete;
DELIMITER //
CREATE TRIGGER trg_scores_delete AFTER DELETE ON scores FOR EACH ROW
    INSERT INTO audit_log (
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        ip_address
    )
    VALUES (
               COALESCE(OLD.recorded_by, @current_user_id, 0),
               'DELETE',
               'scores',
               OLD.id,
               JSON_OBJECT(
                       'student_id', OLD.student_id,
                       'subject_id', OLD.subject_id,
                       'semester_id', OLD.semester_id,
                       'score', OLD.score,
                       'grade', OLD.grade
               ),
               NULL,
               '127.0.0.1'
           ) //
DELIMITER ;