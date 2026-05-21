ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY student_select_own_profile
ON profiles
FOR SELECT
USING (
    auth.uid() = auth_user_id
);

CREATE POLICY student_update_own_profile
ON profiles
FOR UPDATE
USING (
    auth.uid() = auth_user_id
);

CREATE POLICY authenticated_read_questions
ON questions
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY student_manage_own_sessions
ON exam_sessions
FOR ALL
USING (
    student_id IN (
        SELECT id
        FROM profiles
        WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY student_manage_own_answers
ON answers
FOR ALL
USING (
    session_id IN (
        SELECT es.id
        FROM exam_sessions es
        JOIN profiles p
        ON p.id = es.student_id
        WHERE p.auth_user_id = auth.uid()
    )
);

CREATE POLICY student_view_own_enrollments
ON enrollments
FOR SELECT
USING (
    student_id IN (
        SELECT id
        FROM profiles
        WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY school_admin_view_school
ON schools
FOR SELECT
USING (
    admin_id IN (
        SELECT id
        FROM profiles
        WHERE auth_user_id = auth.uid()
        AND role = 'school_admin'
    )
);

CREATE POLICY school_admin_view_students
ON enrollments
FOR SELECT
USING (
    school_id IN (
        SELECT s.id
        FROM schools s
        JOIN profiles p
        ON p.id = s.admin_id
        WHERE p.auth_user_id = auth.uid()
    )
);

CREATE POLICY school_admin_view_sessions
ON exam_sessions
FOR SELECT
USING (
    student_id IN (
        SELECT e.student_id
        FROM enrollments e
        JOIN schools s
        ON s.id = e.school_id
        JOIN profiles p
        ON p.id = s.admin_id
        WHERE p.auth_user_id = auth.uid()
    )
);

CREATE POLICY school_admin_view_answers
ON answers
FOR SELECT
USING (
    session_id IN (
        SELECT es.id
        FROM exam_sessions es
        WHERE es.student_id IN (
            SELECT e.student_id
            FROM enrollments e
            JOIN schools s
            ON s.id = e.school_id
            JOIN profiles p
            ON p.id = s.admin_id
            WHERE p.auth_user_id = auth.uid()
        )
    )
);