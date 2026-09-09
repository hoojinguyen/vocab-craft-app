-- VocabCraft Content SQLite DDL (dataset_schema_version = 1)
-- Spec: docs/superpowers/specs/2026-09-05-shared-learning-contract-design.md §4-§5

PRAGMA foreign_keys = ON;

CREATE TABLE entries (
    id TEXT PRIMARY KEY,
    headword TEXT NOT NULL,
    lookup_key TEXT NOT NULL,
    entry_kind TEXT NOT NULL CHECK(entry_kind IN ('word', 'phrasal_verb', 'phrase', 'idiom')),
    revision INTEGER NOT NULL CHECK(revision >= 1)
);

CREATE TABLE senses (
    id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    part_of_speech TEXT NOT NULL CHECK(part_of_speech IN (
        'noun', 'verb', 'adjective', 'adverb', 'pronoun',
        'determiner', 'preposition', 'conjunction', 'interjection',
        'numeral', 'particle', 'other'
    )),
    definition_en TEXT NOT NULL,
    definition_vi TEXT NOT NULL,
    cefr_level TEXT NOT NULL CHECK(cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    usage_note_en TEXT,
    usage_note_vi TEXT,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0),
    revision INTEGER NOT NULL CHECK(revision >= 1)
);

CREATE TABLE pronunciations (
    id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    sense_id TEXT REFERENCES senses(id) ON DELETE CASCADE,
    accent TEXT NOT NULL CHECK(accent IN ('us', 'uk')),
    ipa TEXT NOT NULL,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0)
);

CREATE TABLE examples (
    id TEXT PRIMARY KEY,
    sense_id TEXT NOT NULL REFERENCES senses(id) ON DELETE CASCADE,
    text_en TEXT NOT NULL,
    text_vi TEXT NOT NULL,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0)
);

CREATE TABLE collocations (
    id TEXT PRIMARY KEY,
    sense_id TEXT NOT NULL REFERENCES senses(id) ON DELETE CASCADE,
    text_en TEXT NOT NULL,
    text_vi TEXT NOT NULL,
    example_id TEXT REFERENCES examples(id) ON DELETE SET NULL,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0)
);

CREATE TABLE decks (
    id TEXT PRIMARY KEY,
    title_en TEXT NOT NULL,
    title_vi TEXT NOT NULL,
    description_en TEXT,
    description_vi TEXT,
    icon_key TEXT NOT NULL,
    theme_key TEXT NOT NULL,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0),
    revision INTEGER NOT NULL CHECK(revision >= 1)
);

CREATE TABLE lessons (
    id TEXT PRIMARY KEY,
    deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    title_en TEXT NOT NULL,
    title_vi TEXT NOT NULL,
    icon_key TEXT NOT NULL,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0),
    revision INTEGER NOT NULL CHECK(revision >= 1)
);

CREATE TABLE lesson_senses (
    lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    sense_id TEXT NOT NULL REFERENCES senses(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL CHECK(sort_order >= 0),
    PRIMARY KEY (lesson_id, sense_id)
);

CREATE TABLE dataset_metadata (
    dataset_schema_version INTEGER NOT NULL CHECK(dataset_schema_version = 1),
    content_version INTEGER NOT NULL CHECK(content_version >= 1),
    published_at TEXT NOT NULL,
    content_language TEXT NOT NULL DEFAULT 'en',
    explanation_language TEXT NOT NULL DEFAULT 'vi'
);

CREATE TABLE attributions (
    id TEXT PRIMARY KEY,
    text TEXT NOT NULL,
    source_url TEXT,
    license_identifier TEXT
);

CREATE TABLE sense_attributions (
    sense_id TEXT NOT NULL REFERENCES senses(id) ON DELETE CASCADE,
    attribution_id TEXT NOT NULL REFERENCES attributions(id) ON DELETE CASCADE,
    PRIMARY KEY (sense_id, attribution_id)
);

CREATE TABLE retired_senses (
    sense_id TEXT PRIMARY KEY,
    retired_in_version INTEGER NOT NULL CHECK(retired_in_version >= 1)
);

-- Unique indexes
CREATE UNIQUE INDEX uq_decks_sort_order ON decks(sort_order);
CREATE UNIQUE INDEX uq_lessons_deck_sort_order ON lessons(deck_id, sort_order);
CREATE UNIQUE INDEX uq_lesson_sense_order ON lesson_senses(lesson_id, sort_order);
CREATE UNIQUE INDEX uq_senses_entry_sort_order ON senses(entry_id, sort_order);
CREATE UNIQUE INDEX uq_examples_sense_sort_order ON examples(sense_id, sort_order);
CREATE UNIQUE INDEX uq_collocations_sense_sort_order ON collocations(sense_id, sort_order);
CREATE UNIQUE INDEX uq_entry_ipa_order ON pronunciations(entry_id, accent, sort_order) WHERE sense_id IS NULL;
CREATE UNIQUE INDEX uq_sense_ipa_order ON pronunciations(sense_id, accent, sort_order) WHERE sense_id IS NOT NULL;

-- Search and FK indexes
CREATE INDEX idx_entries_lookup_key ON entries(lookup_key);
CREATE INDEX idx_pronunciations_entry_id ON pronunciations(entry_id);
CREATE INDEX idx_pronunciations_sense_id ON pronunciations(sense_id);
CREATE INDEX idx_senses_entry_id ON senses(entry_id);
CREATE INDEX idx_examples_sense_id ON examples(sense_id);
CREATE INDEX idx_collocations_sense_id ON collocations(sense_id);
CREATE INDEX idx_collocations_example_id ON collocations(example_id);
CREATE INDEX idx_lessons_deck_id ON lessons(deck_id);
CREATE INDEX idx_lesson_senses_sense_id ON lesson_senses(sense_id);
CREATE INDEX idx_sense_attributions_attribution_id ON sense_attributions(attribution_id);
