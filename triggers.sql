CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO profiles (
        auth_user_id,
        full_name,
        role
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            'Novo Usuário'
        ),
        'student'
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_profile_for_user();

CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE exam_sessions
    SET
        total_questions = total_questions + 1,

        total_correct =
            total_correct +
            CASE
                WHEN NEW.is_correct = true THEN 1
                ELSE 0
            END

    WHERE id = NEW.session_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_session_stats
AFTER INSERT ON answers
FOR EACH ROW
EXECUTE FUNCTION update_session_stats();