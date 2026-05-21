CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM (
    'student',
    'school_admin',
    'global_admin'
);

CREATE TYPE session_status AS ENUM (
    'in_progress',
    'completed'
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    auth_user_id UUID UNIQUE NOT NULL,

    full_name TEXT NOT NULL,

    role user_role NOT NULL DEFAULT 'student',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,

    cnpj TEXT UNIQUE NOT NULL,

    admin_id UUID NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_school_admin
        FOREIGN KEY (admin_id)
        REFERENCES profiles(id),

    CONSTRAINT chk_cnpj_length
        CHECK (char_length(cnpj) = 14)
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    student_id UUID NOT NULL,

    school_id UUID NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_enrollment_school
        FOREIGN KEY (school_id)
        REFERENCES schools(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_student_school
        UNIQUE (student_id, school_id)
);

CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    internal_number INTEGER UNIQUE NOT NULL,

    statement JSONB NOT NULL,

    alternatives JSONB NOT NULL,

    correct_answer INTEGER NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE exam_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    student_id UUID NOT NULL,

    started_at TIMESTAMPTZ DEFAULT NOW(),

    finished_at TIMESTAMPTZ,

    status session_status NOT NULL DEFAULT 'in_progress',

    total_questions INTEGER NOT NULL DEFAULT 0,

    total_correct INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_session_student
        FOREIGN KEY (student_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_totals
        CHECK (total_correct <= total_questions)
);

CREATE TABLE answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    session_id UUID NOT NULL,

    question_id UUID NOT NULL,

    chosen_alternative INTEGER NOT NULL,

    is_correct BOOLEAN NOT NULL,

    answered_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_answer_session
        FOREIGN KEY (session_id)
        REFERENCES exam_sessions(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_answer_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_session_question
        UNIQUE (session_id, question_id)
);

CREATE INDEX idx_answers_session
ON answers(session_id);

CREATE INDEX idx_answers_question
ON answers(question_id);

CREATE INDEX idx_sessions_student
ON exam_sessions(student_id);

CREATE INDEX idx_enrollments_student
ON enrollments(student_id);

CREATE INDEX idx_enrollments_school
ON enrollments(school_id);