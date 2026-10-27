-- Curated learning paths (Daily Life & Travel, Business & Career, Academic & Research).
--
-- The Essential path ships with every content release; these three are seeded on top of it.
-- Deck mappings are matched by decks.title_en because deck IDs are regenerated on every release.
-- Idempotent: safe to run repeatedly. Verified by scripts/content/seed_curated_paths.sh.
BEGIN TRANSACTION;

INSERT OR REPLACE INTO learning_paths (id, code, title_en, title_vi, description_en, description_vi, goal_category, target_level_min, target_level_max, icon_key, theme_key, sort_order, revision)
VALUES ('c11e8a24-9b2f-4e67-881a-637dc44d3201', 'daily-life-travel', 'Everyday Life & Travel Fluency', 'Giao Tiếp Đời Sống & Du Lịch Thực Tế', 'Master everyday conversations, travel scenarios, social interactions, and essential daily living.', 'Làm chủ giao tiếp hàng ngày, du lịch thực tế, kết nối bạn bè và đời sống thường nhật.', 'travel', 'A1', 'B1', 'airplane.departure', 'forest_green', 1, 1);

INSERT OR REPLACE INTO learning_paths (id, code, title_en, title_vi, description_en, description_vi, goal_category, target_level_min, target_level_max, icon_key, theme_key, sort_order, revision)
VALUES ('d22f9b35-0c30-4f78-992b-748ed55e4312', 'business-career', 'Business & Workplace Excellence', 'Tiếng Anh Công Sở & Phát Triển Sự Nghiệp', 'Excel in workplace communication, negotiations, meetings, professional correspondence, and career growth.', 'Thành thạo tiếng Anh công sở, đàm phán, thuyết trình, email chuyên nghiệp và phát triển sự nghiệp.', 'business', 'B1', 'B2', 'briefcase.fill', 'ocean_blue', 2, 1);

INSERT OR REPLACE INTO learning_paths (id, code, title_en, title_vi, description_en, description_vi, goal_category, target_level_min, target_level_max, icon_key, theme_key, sort_order, revision)
VALUES ('e33a0c46-1d41-4089-aa3c-859fe66f5423', 'academic-research', 'Academic Mastery & Critical Inquiries', 'Tiếng Anh Học Thuật & Nghiên Cứu Chuyên Sâu', 'Tackle university lectures, research methodology, scientific discourse, and critical academic analysis.', 'Chinh phục giảng đường đại học, phương pháp nghiên cứu, phản biện và tư duy học thuật chuyên sâu.', 'academic', 'B2', 'C2', 'graduationcap.fill', 'royal_purple', 3, 1);

DELETE FROM path_decks WHERE path_id IN ('c11e8a24-9b2f-4e67-881a-637dc44d3201', 'd22f9b35-0c30-4f78-992b-748ed55e4312', 'e33a0c46-1d41-4089-aa3c-859fe66f5423');

-- daily-life-travel: 26 decks
INSERT INTO path_decks (path_id, deck_id, sort_order)
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 0 FROM decks WHERE title_en = 'Greetings, Self & Personal Details'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 1 FROM decks WHERE title_en = 'Hometowns, Roots & Local Geography'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 2 FROM decks WHERE title_en = 'Family, Relatives & Kinship Bonds'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 3 FROM decks WHERE title_en = 'Physical Appearance, Age & Features'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 4 FROM decks WHERE title_en = 'Life Milestones & Personal Growth'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 5 FROM decks WHERE title_en = 'Daily Rhythms & Personal Routines'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 6 FROM decks WHERE title_en = 'Personal Hobbies, Leisure & Discoveries'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 7 FROM decks WHERE title_en = 'Sports, Athletics & Team Spirit'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 8 FROM decks WHERE title_en = 'Emotions, Moods & Inner Feelings'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 9 FROM decks WHERE title_en = 'Personality Traits, Virtues & Values'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 10 FROM decks WHERE title_en = 'Nature, Wildlife & Living Surroundings'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 11 FROM decks WHERE title_en = 'Homes, Architecture & Living Quarters'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 12 FROM decks WHERE title_en = 'Kitchen Life, Cookware & Family Dining'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 13 FROM decks WHERE title_en = 'Home Appliances, Electronics & Utilities'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 14 FROM decks WHERE title_en = 'House Chores, Cleanliness & Home Maintenance'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 15 FROM decks WHERE title_en = 'Culinary Flavors, Ingredients & Food Prep'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 16 FROM decks WHERE title_en = 'Restaurant Dining, Ordering Food & Hospitality'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 17 FROM decks WHERE title_en = 'Fashion Shopping, Garment Styles & Fitting'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 18 FROM decks WHERE title_en = 'Checkout Counters, Promotions & Customer Service'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 19 FROM decks WHERE title_en = 'City Navigation, Transit & Urban Mobility'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 20 FROM decks WHERE title_en = 'Travel Adventures, Airports & Sightseeing'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 21 FROM decks WHERE title_en = 'Daily Wellness, Nutrition & Vital Living'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 22 FROM decks WHERE title_en = 'Medical Symptoms, Clinic Care & Pharmacy'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 23 FROM decks WHERE title_en = 'Friendship, Personal Narratives & Memories'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 24 FROM decks WHERE title_en = 'Empathy, Active Listening & Support'
UNION ALL
SELECT 'c11e8a24-9b2f-4e67-881a-637dc44d3201', id, 25 FROM decks WHERE title_en = 'Social Plans, Parties & Group Celebrations';

-- business-career: 10 decks
INSERT INTO path_decks (path_id, deck_id, sort_order)
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 0 FROM decks WHERE title_en = 'Greetings, Self & Personal Details'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 1 FROM decks WHERE title_en = 'Emotions, Moods & Inner Feelings'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 2 FROM decks WHERE title_en = 'Personality Traits, Virtues & Values'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 3 FROM decks WHERE title_en = 'Empathy, Active Listening & Support'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 4 FROM decks WHERE title_en = 'Study Methods, Discipline & Skill Acquisition'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 5 FROM decks WHERE title_en = 'Career Pathways & Professional Preparation'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 6 FROM decks WHERE title_en = 'Job Applications, Interviews & Negotiations'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 7 FROM decks WHERE title_en = 'Office Operations, Daily Tasks & Team Synergy'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 8 FROM decks WHERE title_en = 'Business Correspondence, Professional Emails & Memos'
UNION ALL
SELECT 'd22f9b35-0c30-4f78-992b-748ed55e4312', id, 9 FROM decks WHERE title_en = 'Business Meetings, Presentations & Updates';

-- academic-research: 16 decks
INSERT INTO path_decks (path_id, deck_id, sort_order)
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 0 FROM decks WHERE title_en = 'Lecture Comprehension & Core Academic Concepts'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 1 FROM decks WHERE title_en = 'Seminar Engagement & Consulting Professors'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 2 FROM decks WHERE title_en = 'Academic Seminars & Theoretical Debates'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 3 FROM decks WHERE title_en = 'Group Research Projects & Scientific Inquiries'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 4 FROM decks WHERE title_en = 'Laboratory Experiments & Test Methodologies'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 5 FROM decks WHERE title_en = 'Thesis Formulation, Essay Outlines & Evidence Evaluation'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 6 FROM decks WHERE title_en = 'Textual Cohesion, Flow & Signposting (Part A)'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 7 FROM decks WHERE title_en = 'Logical Transitions, Contrast & Concession (Part B)'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 8 FROM decks WHERE title_en = 'Advanced Discourse Flow & Rhetorical Cohesion'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 9 FROM decks WHERE title_en = 'Stating Opinions, Academic Stance & Debates'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 10 FROM decks WHERE title_en = 'Scientific Hypotheses, Speculation & Scenarios'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 11 FROM decks WHERE title_en = 'Scenario Modeling, Risk Analysis & Contingencies'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 12 FROM decks WHERE title_en = 'Synthesizing Findings & Drawing Research Conclusions'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 13 FROM decks WHERE title_en = 'Scholarly Presentations & Thesis Defense'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 14 FROM decks WHERE title_en = 'Advanced Critical Inquiry & Deep Analysis'
UNION ALL
SELECT 'e33a0c46-1d41-4089-aa3c-859fe66f5423', id, 15 FROM decks WHERE title_en = 'Contextual Mastery & Advanced Natural Fluency';

COMMIT;
