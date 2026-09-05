CREATE TABLE IF NOT EXISTS profiles (
    id TEXT PRIMARY KEY,
    kind TEXT NOT NULL,
    created_at TEXT NOT NULL,
    account_binding TEXT
);

CREATE TABLE IF NOT EXISTS attempts (
    attempt_id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL REFERENCES profiles(id),
    payload_json TEXT NOT NULL,
    submission_hash TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS completions (
    event_id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL REFERENCES profiles(id),
    lesson_id TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS counters (
    profile_id TEXT NOT NULL,
    sense_id TEXT NOT NULL,
    capability TEXT NOT NULL,
    total_count INTEGER NOT NULL,
    correct_count INTEGER NOT NULL,
    PRIMARY KEY (profile_id, sense_id, capability),
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS profile_device_sequences (
    profile_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    last_sequence INTEGER NOT NULL,
    PRIMARY KEY (profile_id, device_id),
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_attempts_profile_created ON attempts(profile_id, created_at);
CREATE INDEX IF NOT EXISTS idx_attempts_profile_hash ON attempts(profile_id, submission_hash);
CREATE INDEX IF NOT EXISTS idx_attempts_profile_sense ON attempts(profile_id, json_extract(payload_json, '$.sense_id'));
CREATE INDEX IF NOT EXISTS idx_completions_profile_created ON completions(profile_id, created_at);
CREATE INDEX IF NOT EXISTS idx_counters_profile_sense ON counters(profile_id, sense_id);
