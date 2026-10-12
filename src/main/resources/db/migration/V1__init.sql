-- V1__init.sql
-- Schema inicial do auth-service (ver docs/erd.md)
-- Compatível com PostgreSQL e H2 (modo PostgreSQL).

-- ============================================================
-- ACCOUNT: identidade e estado da conta
-- ============================================================
CREATE TABLE account (
    id               UUID                     NOT NULL,
    email            VARCHAR(254)             NOT NULL,
    email_verified   BOOLEAN                  NOT NULL DEFAULT FALSE,
    phone            VARCHAR(255),
    phone_verified   BOOLEAN                  NOT NULL DEFAULT FALSE,
    status           VARCHAR(20)              NOT NULL DEFAULT 'PENDING',
    failed_attempts  INT                      NOT NULL DEFAULT 0,
    locked_until     TIMESTAMP WITH TIME ZONE,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_account PRIMARY KEY (id),
    CONSTRAINT uk_account_email UNIQUE (email),
    CONSTRAINT ck_account_status
        CHECK (status IN ('PENDING', 'ACTIVE', 'LOCKED', 'DISABLED'))
);

-- ============================================================
-- CREDENTIAL: segredo da conta (1:1)
-- ============================================================
CREATE TABLE credential (
    account_id           UUID                     NOT NULL,
    password_hash        VARCHAR(255)             NOT NULL,
    password_changed_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_credential PRIMARY KEY (account_id),
    CONSTRAINT fk_credential_account
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE
);

-- ============================================================
-- PROFILE: dados pessoais (1:0..1)
-- ============================================================
CREATE TABLE profile (
    account_id  UUID         NOT NULL,
    full_name   VARCHAR(150) NOT NULL,
    birth_date  DATE,
    locale      VARCHAR(10)  NOT NULL DEFAULT 'pt-BR',
    CONSTRAINT pk_profile PRIMARY KEY (account_id),
    CONSTRAINT fk_profile_account
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE
);

-- ============================================================
-- ROLE: papéis (tabela de referência)
-- ============================================================
CREATE TABLE role (
    id    INT GENERATED ALWAYS AS IDENTITY,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_role PRIMARY KEY (id),
    CONSTRAINT uk_role_name UNIQUE (name)
);

-- ============================================================
-- ACCOUNT_ROLE: N:N entre conta e papel
-- ============================================================
CREATE TABLE account_role (
    account_id  UUID NOT NULL,
    role_id     INT  NOT NULL,
    CONSTRAINT pk_account_role PRIMARY KEY (account_id, role_id),
    CONSTRAINT fk_account_role_account
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE,
    CONSTRAINT fk_account_role_role
        FOREIGN KEY (role_id) REFERENCES role (id)
);

-- ============================================================
-- REFRESH_TOKEN: só o hash (SHA-256 hex) é guardado
-- ============================================================
CREATE TABLE refresh_token (
    id          UUID                     NOT NULL,
    account_id  UUID                     NOT NULL,
    token_hash  CHAR(64)                 NOT NULL,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at  TIMESTAMP WITH TIME ZONE,
    replaced_by UUID,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_refresh_token PRIMARY KEY (id),
    CONSTRAINT uk_refresh_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_refresh_token_account
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE,
    CONSTRAINT fk_refresh_token_replaced_by
        FOREIGN KEY (replaced_by) REFERENCES refresh_token (id)
);

CREATE INDEX idx_refresh_token_account ON refresh_token (account_id);

-- ============================================================
-- VERIFICATION_TOKEN: verificação de e-mail e reset de senha
-- ============================================================
CREATE TABLE verification_token (
    id          UUID                     NOT NULL,
    account_id  UUID                     NOT NULL,
    type        VARCHAR(30)              NOT NULL,
    token_hash  CHAR(64)                 NOT NULL,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at     TIMESTAMP WITH TIME ZONE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_verification_token PRIMARY KEY (id),
    CONSTRAINT uk_verification_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_verification_token_account
        FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE,
    CONSTRAINT ck_verification_token_type
        CHECK (type IN ('EMAIL_VERIFY', 'PASSWORD_RESET'))
);

CREATE INDEX idx_verification_token_account_type
    ON verification_token (account_id, type);

-- ============================================================
-- AUDIT_EVENT: histórico de segurança
-- Sem FK de propósito: login com e-mail inexistente não tem conta,
-- e o histórico deve sobreviver à exclusão da conta.
-- ============================================================
CREATE TABLE audit_event (
    id          UUID                     NOT NULL,
    account_id  UUID,
    event_type  VARCHAR(50)              NOT NULL,
    ip          VARCHAR(45),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_audit_event PRIMARY KEY (id)
);

CREATE INDEX idx_audit_event_account_created
    ON audit_event (account_id, created_at);

-- ============================================================
-- Seed: papéis iniciais (o Spring adiciona o prefixo ROLE_ sozinho)
-- ============================================================
INSERT INTO role (name) VALUES ('USER');
INSERT INTO role (name) VALUES ('ADMIN');