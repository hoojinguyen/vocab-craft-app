import sqlite3
import json
import os

DB_PATH = "VocabCraftApp/Resources/ShadowingCatalog.sqlite"

def main():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE topics (
        id TEXT PRIMARY KEY NOT NULL,
        title_en TEXT NOT NULL,
        title_vi TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        display_order INTEGER NOT NULL
    );
    """)

    cursor.execute("""
    CREATE TABLE videos (
        id TEXT PRIMARY KEY NOT NULL,
        youtube_video_id TEXT NOT NULL,
        title TEXT NOT NULL,
        topic_id TEXT NOT NULL REFERENCES topics(id),
        level TEXT NOT NULL,
        duration_seconds REAL NOT NULL,
        thumbnail_url TEXT,
        accent TEXT DEFAULT 'American',
        display_order INTEGER NOT NULL
    );
    """)

    cursor.execute("""
    CREATE TABLE sentences (
        id TEXT PRIMARY KEY NOT NULL,
        video_id TEXT NOT NULL REFERENCES videos(id),
        order_index INTEGER NOT NULL,
        start_time REAL NOT NULL,
        end_time REAL NOT NULL,
        text_en TEXT NOT NULL,
        text_vi TEXT NOT NULL,
        words_json TEXT
    );
    """)

    cursor.execute("""
    CREATE TABLE sentence_keywords (
        id TEXT PRIMARY KEY NOT NULL,
        sentence_id TEXT NOT NULL REFERENCES sentences(id),
        lemma TEXT NOT NULL,
        phonetic TEXT NOT NULL,
        definition_vi TEXT NOT NULL,
        definition_en TEXT,
        linked_word_id INTEGER
    );
    """)

    # 1. Topics
    topics = [
        ("dailyLife", "Daily Life", "Đời sống hàng ngày", "cup.and.saucer.fill", 1),
        ("moviesAndSeries", "Movies & TV Series", "Phim & Truyền hình", "film.stack", 2),
        ("businessEnglish", "Work & Business", "Công việc & Kinh doanh", "briefcase.fill", 3),
        ("techAndScience", "Tech & Trends", "Công nghệ & Đổi mới", "cpu.fill", 4),
    ]
    cursor.executemany("INSERT INTO topics VALUES (?, ?, ?, ?, ?);", topics)

    # 2. Videos
    videos = [
        (
            "yt_daily_morning_routine",
            "b1KGg722b9k",
            "Morning Habits for Success",
            "dailyLife",
            "A1",
            28.5,
            "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800",
            "American",
            1
        ),
        (
            "yt_daily_coffee_01",
            "NhiOn8f-kdM",
            "Ordering at a Café",
            "dailyLife",
            "A2",
            32.0,
            "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800",
            "American",
            2
        ),
        (
            "yt_movie_friends_dialogue",
            "kJQP7kiw5Fk",
            "Catching Up with Friends",
            "moviesAndSeries",
            "A2",
            38.0,
            "https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800",
            "American",
            3
        ),
        (
            "yt_biz_project_update",
            "JGwWNGJdvx8",
            "Sprint Planning Meeting",
            "businessEnglish",
            "B1",
            44.0,
            "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800",
            "British",
            4
        ),
        (
            "yt_tech_ai_breakthrough",
            "fJ9rUzIMcZQ",
            "How Neural Networks Learn",
            "techAndScience",
            "B1",
            48.0,
            "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800",
            "American",
            5
        ),
    ]
    cursor.executemany("INSERT INTO videos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);", videos)

    # 3. Sentences & Words JSON
    sentences = [
        # Video 1: yt_daily_morning_routine
        (
            "s_morning_01",
            "yt_daily_morning_routine",
            0,
            0.0,
            3.5,
            "Every morning, I wake up early and drink a glass of water.",
            "Mỗi buổi sáng, tôi thức dậy sớm và uống một cốc nước.",
            json.dumps([
                {"word": "Every", "start": 0.0, "end": 0.4},
                {"word": "morning,", "start": 0.4, "end": 0.9},
                {"word": "I", "start": 1.0, "end": 1.1},
                {"word": "wake", "start": 1.1, "end": 1.4},
                {"word": "up", "start": 1.4, "end": 1.6},
                {"word": "early", "start": 1.6, "end": 2.0},
                {"word": "and", "start": 2.1, "end": 2.3},
                {"word": "drink", "start": 2.3, "end": 2.6},
                {"word": "a", "start": 2.6, "end": 2.7},
                {"word": "glass", "start": 2.7, "end": 3.0},
                {"word": "of", "start": 3.0, "end": 3.1},
                {"word": "water.", "start": 3.1, "end": 3.5}
            ])
        ),
        (
            "s_morning_02",
            "yt_daily_morning_routine",
            1,
            3.6,
            6.5,
            "Then I go for a short walk in the park.",
            "Sau đó tôi đi dạo một đoạn ngắn trong công viên.",
            json.dumps([
                {"word": "Then", "start": 3.6, "end": 3.9},
                {"word": "I", "start": 3.9, "end": 4.1},
                {"word": "go", "start": 4.1, "end": 4.3},
                {"word": "for", "start": 4.3, "end": 4.5},
                {"word": "a", "start": 4.5, "end": 4.6},
                {"word": "short", "start": 4.6, "end": 5.0},
                {"word": "walk", "start": 5.0, "end": 5.3},
                {"word": "in", "start": 5.3, "end": 5.5},
                {"word": "the", "start": 5.5, "end": 5.7},
                {"word": "park.", "start": 5.7, "end": 6.5}
            ])
        ),
        (
            "s_morning_03",
            "yt_daily_morning_routine",
            2,
            6.8,
            10.2,
            "Fresh air helps me focus throughout the day.",
            "Không khí trong lành giúp tôi tập trung suốt cả ngày.",
            json.dumps([
                {"word": "Fresh", "start": 6.8, "end": 7.2},
                {"word": "air", "start": 7.2, "end": 7.6},
                {"word": "helps", "start": 7.7, "end": 8.1},
                {"word": "me", "start": 8.1, "end": 8.3},
                {"word": "focus", "start": 8.4, "end": 8.9},
                {"word": "throughout", "start": 9.0, "end": 9.5},
                {"word": "the", "start": 9.5, "end": 9.7},
                {"word": "day.", "start": 9.7, "end": 10.2}
            ])
        ),

        # Video 2: yt_daily_coffee_01
        (
            "s_coffee_01",
            "yt_daily_coffee_01",
            0,
            0.5,
            3.5,
            "Hi! What can I get for you?",
            "Xin chào! Tôi có thể lấy gì cho bạn?",
            json.dumps([
                {"word": "Hi!", "start": 0.5, "end": 0.9},
                {"word": "What", "start": 1.0, "end": 1.3},
                {"word": "can", "start": 1.3, "end": 1.6},
                {"word": "I", "start": 1.6, "end": 1.8},
                {"word": "get", "start": 1.8, "end": 2.1},
                {"word": "for", "start": 2.1, "end": 2.4},
                {"word": "you?", "start": 2.4, "end": 3.5}
            ])
        ),
        (
            "s_coffee_02",
            "yt_daily_coffee_01",
            1,
            3.6,
            7.2,
            "Can I get a small flat white, please?",
            "Cho tôi một ly flat white nhỏ được không?",
            json.dumps([
                {"word": "Can", "start": 3.6, "end": 3.9},
                {"word": "I", "start": 3.9, "end": 4.1},
                {"word": "get", "start": 4.1, "end": 4.4},
                {"word": "a", "start": 4.4, "end": 4.5},
                {"word": "small", "start": 4.5, "end": 4.9},
                {"word": "flat", "start": 5.0, "end": 5.4},
                {"word": "white,", "start": 5.4, "end": 5.9},
                {"word": "please?", "start": 6.1, "end": 7.2}
            ])
        ),
        (
            "s_coffee_03",
            "yt_daily_coffee_01",
            2,
            7.5,
            11.2,
            "Sure. Would you like anything to eat with that?",
            "Chắc chắn rồi. Bạn có muốn dùng kèm đồ ăn gì không?",
            json.dumps([
                {"word": "Sure.", "start": 7.5, "end": 8.0},
                {"word": "Would", "start": 8.1, "end": 8.4},
                {"word": "you", "start": 8.4, "end": 8.6},
                {"word": "like", "start": 8.6, "end": 8.9},
                {"word": "anything", "start": 9.0, "end": 9.5},
                {"word": "to", "start": 9.5, "end": 9.7},
                {"word": "eat", "start": 9.7, "end": 10.0},
                {"word": "with", "start": 10.0, "end": 10.3},
                {"word": "that?", "start": 10.3, "end": 11.2}
            ])
        ),

        # Video 3: yt_movie_friends_dialogue
        (
            "s_friends_01",
            "yt_movie_friends_dialogue",
            0,
            0.8,
            4.2,
            "I haven't seen you in such a long time!",
            "Lâu lắm rồi tớ mới gặp lại cậu!",
            json.dumps([
                {"word": "I", "start": 0.8, "end": 1.0},
                {"word": "haven't", "start": 1.0, "end": 1.5},
                {"word": "seen", "start": 1.5, "end": 1.8},
                {"word": "you", "start": 1.8, "end": 2.1},
                {"word": "in", "start": 2.1, "end": 2.3},
                {"word": "such", "start": 2.3, "end": 2.7},
                {"word": "a", "start": 2.7, "end": 2.8},
                {"word": "long", "start": 2.8, "end": 3.3},
                {"word": "time!", "start": 3.3, "end": 4.2}
            ])
        ),
        (
            "s_friends_02",
            "yt_movie_friends_dialogue",
            1,
            4.5,
            8.0,
            "I know! Work has been completely crazy lately.",
            "Tớ biết mà! Dạo này công việc bận rộn điên cuồng luôn.",
            json.dumps([
                {"word": "I", "start": 4.5, "end": 4.7},
                {"word": "know!", "start": 4.7, "end": 5.2},
                {"word": "Work", "start": 5.3, "end": 5.7},
                {"word": "has", "start": 5.7, "end": 6.0},
                {"word": "been", "start": 6.0, "end": 6.3},
                {"word": "completely", "start": 6.3, "end": 7.0},
                {"word": "crazy", "start": 7.0, "end": 7.5},
                {"word": "lately.", "start": 7.5, "end": 8.0}
            ])
        ),
        (
            "s_friends_03",
            "yt_movie_friends_dialogue",
            2,
            8.3,
            12.5,
            "We definitely need to grab dinner this weekend.",
            "Cuối tuần này chúng mình nhất định phải đi ăn tối đấy nhé.",
            json.dumps([
                {"word": "We", "start": 8.3, "end": 8.6},
                {"word": "definitely", "start": 8.6, "end": 9.2},
                {"word": "need", "start": 9.2, "end": 9.6},
                {"word": "to", "start": 9.6, "end": 9.8},
                {"word": "grab", "start": 9.8, "end": 10.2},
                {"word": "dinner", "start": 10.2, "end": 10.7},
                {"word": "this", "start": 10.8, "end": 11.2},
                {"word": "weekend.", "start": 11.2, "end": 12.5}
            ])
        ),

        # Video 4: yt_biz_project_update
        (
            "s_biz_01",
            "yt_biz_project_update",
            0,
            1.0,
            4.8,
            "Let's review our main deliverables before the release.",
            "Hãy rà soát lại các hạng mục bàn giao chính trước đợt phát hành.",
            json.dumps([
                {"word": "Let's", "start": 1.0, "end": 1.4},
                {"word": "review", "start": 1.4, "end": 1.8},
                {"word": "our", "start": 1.8, "end": 2.1},
                {"word": "main", "start": 2.1, "end": 2.5},
                {"word": "deliverables", "start": 2.5, "end": 3.4},
                {"word": "before", "start": 3.4, "end": 3.9},
                {"word": "the", "start": 3.9, "end": 4.1},
                {"word": "release.", "start": 4.1, "end": 4.8}
            ])
        ),
        (
            "s_biz_02",
            "yt_biz_project_update",
            1,
            5.0,
            9.2,
            "The engineering team has finalized all critical bug fixes.",
            "Đội ngũ kỹ thuật đã hoàn tất việc sửa toàn bộ các lỗi nghiêm trọng.",
            json.dumps([
                {"word": "The", "start": 5.0, "end": 5.2},
                {"word": "engineering", "start": 5.2, "end": 6.0},
                {"word": "team", "start": 6.0, "end": 6.4},
                {"word": "has", "start": 6.4, "end": 6.7},
                {"word": "finalized", "start": 6.7, "end": 7.4},
                {"word": "all", "start": 7.4, "end": 7.7},
                {"word": "critical", "start": 7.7, "end": 8.3},
                {"word": "bug", "start": 8.3, "end": 8.6},
                {"word": "fixes.", "start": 8.6, "end": 9.2}
            ])
        ),
        (
            "s_biz_03",
            "yt_biz_project_update",
            2,
            9.5,
            14.0,
            "That sounds great, so we are on track for Thursday.",
            "Nghe tuyệt đấy, vậy là chúng ta đang đúng tiến độ cho thứ Năm.",
            json.dumps([
                {"word": "That", "start": 9.5, "end": 9.8},
                {"word": "sounds", "start": 9.8, "end": 10.3},
                {"word": "great,", "start": 10.3, "end": 10.8},
                {"word": "so", "start": 11.0, "end": 11.3},
                {"word": "we", "start": 11.3, "end": 11.5},
                {"word": "are", "start": 11.5, "end": 11.7},
                {"word": "on", "start": 11.7, "end": 12.0},
                {"word": "track", "start": 12.0, "end": 12.4},
                {"word": "for", "start": 12.4, "end": 12.7},
                {"word": "Thursday.", "start": 12.7, "end": 14.0}
            ])
        ),

        # Video 5: yt_tech_ai_breakthrough
        (
            "s_tech_01",
            "yt_tech_ai_breakthrough",
            0,
            0.5,
            4.5,
            "Neural networks process incoming data through multiple hidden layers.",
            "Mạng nơ-ron xử lý dữ liệu đầu vào qua nhiều tầng ẩn.",
            json.dumps([
                {"word": "Neural", "start": 0.5, "end": 0.9},
                {"word": "networks", "start": 0.9, "end": 1.4},
                {"word": "process", "start": 1.4, "end": 1.9},
                {"word": "incoming", "start": 1.9, "end": 2.5},
                {"word": "data", "start": 2.5, "end": 2.9},
                {"word": "through", "start": 2.9, "end": 3.3},
                {"word": "multiple", "start": 3.3, "end": 3.8},
                {"word": "hidden", "start": 3.8, "end": 4.1},
                {"word": "layers.", "start": 4.1, "end": 4.5}
            ])
        ),
        (
            "s_tech_02",
            "yt_tech_ai_breakthrough",
            1,
            4.8,
            9.0,
            "Each connection between artificial neurons has an adjustable weight.",
            "Mỗi liên kết giữa các nơ-ron nhân tạo đều có một trọng số có thể điều chỉnh.",
            json.dumps([
                {"word": "Each", "start": 4.8, "end": 5.1},
                {"word": "connection", "start": 5.1, "end": 5.7},
                {"word": "between", "start": 5.7, "end": 6.1},
                {"word": "artificial", "start": 6.1, "end": 6.8},
                {"word": "neurons", "start": 6.8, "end": 7.4},
                {"word": "has", "start": 7.4, "end": 7.7},
                {"word": "an", "start": 7.7, "end": 7.8},
                {"word": "adjustable", "start": 7.8, "end": 8.5},
                {"word": "weight.", "start": 8.5, "end": 9.0}
            ])
        ),
        (
            "s_tech_03",
            "yt_tech_ai_breakthrough",
            2,
            9.3,
            14.2,
            "During training, weights update continuously to minimize prediction errors.",
            "Trong quá trình huấn luyện, các trọng số được cập nhật liên tục để giảm thiểu sai số dự đoán.",
            json.dumps([
                {"word": "During", "start": 9.3, "end": 9.7},
                {"word": "training,", "start": 9.7, "end": 10.3},
                {"word": "weights", "start": 10.4, "end": 10.8},
                {"word": "update", "start": 10.8, "end": 11.3},
                {"word": "continuously", "start": 11.3, "end": 12.1},
                {"word": "to", "start": 12.1, "end": 12.3},
                {"word": "minimize", "start": 12.3, "end": 12.9},
                {"word": "prediction", "start": 12.9, "end": 13.5},
                {"word": "errors.", "start": 13.5, "end": 14.2}
            ])
        ),
    ]
    cursor.executemany("INSERT INTO sentences VALUES (?, ?, ?, ?, ?, ?, ?, ?);", sentences)

    # 4. Keywords
    keywords = [
        ("kw_01", "s_morning_01", "wake up", "/weɪk ʌp/", "thức dậy", "to stop sleeping", None),
        ("kw_02", "s_morning_01", "early", "/ˈɜːr.li/", "sớm", "near the beginning of a period", None),
        ("kw_03", "s_morning_02", "walk", "/wɔːk/", "đi dạo", "to move on foot", None),
        ("kw_04", "s_morning_03", "focus", "/ˈfoʊ.kəs/", "tập trung", "to give your full attention", None),

        ("kw_05", "s_coffee_02", "flat white", "/ˌflæt ˈwaɪt/", "cà phê sữa kiểu Úc", "espresso with microfoam", None),
        ("kw_06", "s_coffee_02", "small", "/smɑːl/", "nhỏ", "little in size", None),
        ("kw_07", "s_coffee_03", "anything", "/ˈen.i.θɪŋ/", "bất cứ thứ gì", "any thing or object", None),

        ("kw_08", "s_friends_01", "such", "/sʌtʃ/", "đến thế, như vậy", "of that kind or extent", None),
        ("kw_09", "s_friends_02", "completely", "/kəmˈpliːt.li/", "hoàn toàn", "totally or fully", None),
        ("kw_10", "s_friends_02", "lately", "/ˈleɪt.li/", "dạo gần đây", "recently", None),
        ("kw_11", "s_friends_03", "definitely", "/ˈdef.ə.nət.li/", "chắc chắn, nhất định", "without any doubt", None),

        ("kw_12", "s_biz_01", "deliverables", "/dɪˈlɪv.ər.ə.bəlz/", "sản phẩm bàn giao", "things to be delivered", None),
        ("kw_13", "s_biz_02", "finalized", "/ˈfaɪ.nəl.aɪzd/", "đã hoàn tất", "put into final form", None),
        ("kw_14", "s_biz_02", "critical", "/ˈkrɪt.ɪ.kəl/", "nghiêm trọng, cốt yếu", "vital or crucial", None),
        ("kw_15", "s_biz_03", "on track", "/ɒn træk/", "đúng tiến độ", "proceeding as planned", None),

        ("kw_16", "s_tech_01", "neural networks", "/ˈnʊr.əl ˈnet.wɜːrks/", "mạng nơ-ron", "computing systems inspired by brain", None),
        ("kw_17", "s_tech_01", "layers", "/ˈleɪ.ərz/", "các tầng, các lớp", "levels or strata", None),
        ("kw_18", "s_tech_02", "neurons", "/ˈnʊr.ɑːnz/", "nơ-ron", "information processing nodes", None),
        ("kw_19", "s_tech_02", "adjustable", "/əˈdʒʌs.tə.bəl/", "có thể điều chỉnh", "able to be modified", None),
        ("kw_20", "s_tech_03", "continuously", "/kənˈtɪn.ju.əs.li/", "liên tục", "without interruption", None),
        ("kw_21", "s_tech_03", "minimize", "/ˈmɪn.ə.maɪz/", "giảm thiểu", "reduce to smallest amount", None),
    ]
    cursor.executemany("INSERT INTO sentence_keywords VALUES (?, ?, ?, ?, ?, ?, ?);", keywords)

    conn.commit()
    conn.close()
    print(f"Created {DB_PATH} successfully.")

if __name__ == "__main__":
    main()
