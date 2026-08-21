import Foundation

public enum VocabularySampleDataset {
    public static let decks: [TopicDeckDTO] = [
        TopicDeckDTO(id: "deck_daily", title: "Giao Tiếp Hằng Ngày", iconName: "bubble.left.and.bubble.right",
                     badgeColorHex: "#38B2AC", cefrLevel: "A2 - B1", sortOrder: 1),
        TopicDeckDTO(id: "deck_business", title: "Công Sở & Kinh Doanh", iconName: "briefcase",
                     badgeColorHex: "#ED8936", cefrLevel: "B1 - B2", sortOrder: 2),
        TopicDeckDTO(id: "deck_tech", title: "Công Nghệ & AI", iconName: "cpu",
                     badgeColorHex: "#4299E1", cefrLevel: "B2 - C1", sortOrder: 3),
        TopicDeckDTO(id: "deck_academic", title: "Học Thuật & IELTS", iconName: "graduationcap",
                     badgeColorHex: "#9F7AEA", cefrLevel: "B2 - C1", sortOrder: 4)
    ]

    public static let stages: [SubTopicStageDTO] = [
        SubTopicStageDTO(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1: Thói quen & Cảm xúc", iconName: "heart", sortOrder: 1),
        SubTopicStageDTO(id: "stage_daily_2", deckId: "deck_daily", title: "Chặng 2: Giao tiếp & Ứng xử", iconName: "person.2", sortOrder: 2),
        SubTopicStageDTO(id: "stage_biz_1", deckId: "deck_business", title: "Chặng 1: Quản lý & Kế hoạch", iconName: "checklist", sortOrder: 1),
        SubTopicStageDTO(id: "stage_biz_2", deckId: "deck_business", title: "Chặng 2: Đàm phán & Năng lực", iconName: "chart.line.uptrend.xyaxis", sortOrder: 2),
        SubTopicStageDTO(id: "stage_tech_1", deckId: "deck_tech", title: "Chặng 1: Kỷ nguyên Số", iconName: "network", sortOrder: 1),
        SubTopicStageDTO(id: "stage_tech_2", deckId: "deck_tech", title: "Chặng 2: Trí tuệ Nhân tạo", iconName: "sparkles", sortOrder: 2),
        SubTopicStageDTO(id: "stage_acad_1", deckId: "deck_academic", title: "Chặng 1: Môi trường & Xã hội", iconName: "leaf", sortOrder: 1),
        SubTopicStageDTO(id: "stage_acad_2", deckId: "deck_academic", title: "Chặng 2: Tư duy & Toàn cầu", iconName: "globe", sortOrder: 2)
    ]

    public static let words: [TopicWordDTO] = [
        // Daily Stage 1 (7 words)
        TopicWordDTO(
            id: 1, stageId: "stage_daily_1", lemma: "Resilience", phonetic: "/rɪˈzɪl.jəns/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Khả năng phục hồi, kiên cường", definitionEn: "The capacity to recover quickly from difficulties",
            exampleEn: "Her resilience helped her overcome difficulties.", exampleVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        ),
        TopicWordDTO(
            id: 2, stageId: "stage_daily_1", lemma: "Overwhelmed", phonetic: "/ˌoʊ.vɚˈwelmd/", pos: "adjective", cefrLevel: "B1",
            definitionVi: "Bị ngợp, quá tải", definitionEn: "Completely overcome by emotions or tasks",
            exampleEn: "He felt overwhelmed by the workload.", exampleVi: "Anh ấy cảm thấy quá tải vì khối lượng công việc."
        ),
        TopicWordDTO(
            id: 3, stageId: "stage_daily_1", lemma: "Spontaneous", phonetic: "/spɑːnˈteɪ.ni.əs/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Tự phát, ngẫu hứng", definitionEn: "Performed or occurring as a result of a sudden impulse",
            exampleEn: "We took a spontaneous road trip.", exampleVi: "Chúng tôi đã có một chuyến đi phượt ngẫu hứng."
        ),
        TopicWordDTO(
            id: 4, stageId: "stage_daily_1", lemma: "Gratitude", phonetic: "/ˈɡræt̬.ə.tuːd/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Lòng biết ơn", definitionEn: "The quality of being thankful",
            exampleEn: "She expressed gratitude for his help.", exampleVi: "Cô ấy bày tỏ lòng biết ơn vì sự giúp đỡ của anh ấy."
        ),
        TopicWordDTO(
            id: 5, stageId: "stage_daily_1", lemma: "Procrastinate", phonetic: "/proʊˈkræs.tə.neɪt/", pos: "verb", cefrLevel: "B2",
            definitionVi: "Trì hoãn công việc", definitionEn: "Delay or postpone action",
            exampleEn: "Don't procrastinate on important tasks.", exampleVi: "Đừng trì hoãn những công việc quan trọng."
        ),
        TopicWordDTO(
            id: 6, stageId: "stage_daily_1", lemma: "Empathy", phonetic: "/ˈem.pə.θi/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự đồng cảm", definitionEn: "The ability to understand others' feelings",
            exampleEn: "Empathy is vital for healthy relationships.", exampleVi: "Sự đồng cảm rất quan trọng cho các mối quan hệ tốt đẹp."
        ),
        TopicWordDTO(
            id: 7, stageId: "stage_daily_1", lemma: "Reliable", phonetic: "/rɪˈlaɪ.ə.bəl/", pos: "adjective", cefrLevel: "A2",
            definitionVi: "Đáng tin cậy", definitionEn: "Consistently good in quality or performance",
            exampleEn: "She is a reliable and honest friend.", exampleVi: "Cô ấy là một người bạn đáng tin cậy và thật thà."
        ),

        // Daily Stage 2 (6 words)
        TopicWordDTO(
            id: 8, stageId: "stage_daily_2", lemma: "Compromise", phonetic: "/ˈkɑːm.prə.maɪz/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Sự thỏa hiệp", definitionEn: "An agreement reached by mutual concession",
            exampleEn: "They reached a fair compromise.", exampleVi: "Họ đã đạt được một sự thỏa hiệp công bằng."
        ),
        TopicWordDTO(
            id: 9, stageId: "stage_daily_2", lemma: "Misunderstanding", phonetic: "/ˌmɪs.ʌn.dɚˈstæn.dɪŋ/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Sự hiểu lầm", definitionEn: "A failure to understand correctly",
            exampleEn: "Clear communication prevents misunderstanding.", exampleVi: "Giao tiếp rõ ràng giúp ngăn ngừa hiểu lầm."
        ),
        TopicWordDTO(
            id: 10, stageId: "stage_daily_2", lemma: "Heartfelt", phonetic: "/ˈhɑːrt.felt/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Chân thành, từ tận đáy lòng", definitionEn: "Sincere and deeply felt",
            exampleEn: "He gave a heartfelt apology.", exampleVi: "Anh ấy đã đưa ra lời xin lỗi chân thành."
        ),
        TopicWordDTO(
            id: 11, stageId: "stage_daily_2", lemma: "Hesitate", phonetic: "/ˈhez.ə.teɪt/", pos: "verb", cefrLevel: "B1",
            definitionVi: "Do dự, ngập ngừng", definitionEn: "Pause before saying or doing something",
            exampleEn: "Do not hesitate to ask questions.", exampleVi: "Đừng ngần ngại đặt câu hỏi."
        ),
        TopicWordDTO(
            id: 12, stageId: "stage_daily_2", lemma: "Optimistic", phonetic: "/ˌɑːp.təˈmɪs.tɪk/", pos: "adjective", cefrLevel: "B1",
            definitionVi: "Lạc quan", definitionEn: "Hopeful and confident about the future",
            exampleEn: "She remains optimistic about the future.", exampleVi: "Cô ấy vẫn luôn lạc quan về tương lai."
        ),
        TopicWordDTO(
            id: 13, stageId: "stage_daily_2", lemma: "Genuine", phonetic: "/ˈdʒen.ju.ɪn/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Thật lòng, chân thực", definitionEn: "Truly what something is said to be; authentic",
            exampleEn: "He showed genuine interest in the project.", exampleVi: "Anh ấy thể hiện sự quan tâm chân thật tới dự án."
        ),

        // Business Stage 1 (6 words)
        TopicWordDTO(
            id: 14, stageId: "stage_biz_1", lemma: "Prioritize", phonetic: "/praɪˈɔːr.ə.taɪz/", pos: "verb", cefrLevel: "B1",
            definitionVi: "Ưu tiên", definitionEn: "Designate or treat as more important",
            exampleEn: "Prioritize your urgent tasks daily.", exampleVi: "Hãy ưu tiên các công việc khẩn cấp hàng ngày."
        ),
        TopicWordDTO(
            id: 15, stageId: "stage_biz_1", lemma: "Deadline", phonetic: "/ˈded.laɪn/", pos: "noun", cefrLevel: "A2",
            definitionVi: "Hạn chót", definitionEn: "The latest time by which something should be completed",
            exampleEn: "We must meet the strict deadline.", exampleVi: "Chúng ta phải hoàn thành đúng hạn chót nghiêm ngặt."
        ),
        TopicWordDTO(
            id: 16, stageId: "stage_biz_1", lemma: "Collaborate", phonetic: "/kəˈlæb.ə.reɪt/", pos: "verb", cefrLevel: "B2",
            definitionVi: "Hợp tác làm việc", definitionEn: "Work jointly on an activity or project",
            exampleEn: "Teams collaborate across departments.", exampleVi: "Các đội nhóm hợp tác xuyên phòng ban."
        ),
        TopicWordDTO(
            id: 17, stageId: "stage_biz_1", lemma: "Milestone", phonetic: "/ˈmaɪl.stoʊn/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Cột mốc quan trọng", definitionEn: "A significant stage or event in development",
            exampleEn: "Launching the app was a major milestone.", exampleVi: "Ra mắt ứng dụng là một cột mốc lớn."
        ),
        TopicWordDTO(
            id: 18, stageId: "stage_biz_1", lemma: "Delegation", phonetic: "/ˌdel.əˈɡeɪ.ʃən/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự ủy quyền", definitionEn: "The assignment of responsibility or authority",
            exampleEn: "Effective delegation saves time.", exampleVi: "Ủy quyền hiệu quả giúp tiết kiệm thời gian."
        ),
        TopicWordDTO(
            id: 19, stageId: "stage_biz_1", lemma: "Productivity", phonetic: "/ˌproʊ.dʌkˈtɪv.ə.t̬i/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Năng suất", definitionEn: "The effectiveness of productive effort",
            exampleEn: "Quiet workspaces boost productivity.", exampleVi: "Không gian làm việc yên tĩnh giúp nâng cao năng suất."
        ),

        // Business Stage 2 (6 words)
        TopicWordDTO(
            id: 20, stageId: "stage_biz_2", lemma: "Negotiation", phonetic: "/nəˌɡoʊ.ʃiˈeɪ.ʃən/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Cuộc đàm phán", definitionEn: "Discussion aimed at reaching an agreement",
            exampleEn: "The contract negotiation was successful.", exampleVi: "Cuộc đàm phán hợp đồng đã thành công."
        ),
        TopicWordDTO(
            id: 21, stageId: "stage_biz_2", lemma: "Feedback", phonetic: "/ˈfiːd.bæk/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Ý kiến phản hồi", definitionEn: "Information about performance used for improvement",
            exampleEn: "Constructive feedback helps employees grow.", exampleVi: "Phản hồi mang tính xây dựng giúp nhân viên tiến bộ."
        ),
        TopicWordDTO(
            id: 22, stageId: "stage_biz_2", lemma: "Competence", phonetic: "/ˈkɑːm.pə.t̬əns/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Năng lực chuyên môn", definitionEn: "The ability to do something successfully",
            exampleEn: "She demonstrated high technical competence.", exampleVi: "Cô ấy chứng tỏ năng lực kỹ thuật rất cao."
        ),
        TopicWordDTO(
            id: 23, stageId: "stage_biz_2", lemma: "Benchmark", phonetic: "/ˈbentʃ.mɑːrk/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Tiêu chuẩn đối sánh", definitionEn: "A standard against which things may be compared",
            exampleEn: "The project sets a new quality benchmark.", exampleVi: "Dự án thiết lập một tiêu chuẩn chất lượng mới."
        ),
        TopicWordDTO(
            id: 24, stageId: "stage_biz_2", lemma: "Incentive", phonetic: "/ɪnˈsen.t̬ɪv/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Động lực, sự khích lệ", definitionEn: "A thing that motivates or encourages someone",
            exampleEn: "Bonuses serve as a strong incentive.", exampleVi: "Tiền thưởng đóng vai trò là một động lực mạnh mẽ."
        ),
        TopicWordDTO(
            id: 25, stageId: "stage_biz_2", lemma: "Transparency", phonetic: "/trænˈspær.ən.si/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Tính minh bạch", definitionEn: "The condition of being open and transparent",
            exampleEn: "We value transparency in management.", exampleVi: "Chúng tôi đề cao tính minh bạch trong quản trị."
        ),

        // Tech Stage 1 (6 words)
        TopicWordDTO(
            id: 26, stageId: "stage_tech_1", lemma: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Thuật toán", definitionEn: "A process or set of rules in calculations",
            exampleEn: "Search algorithms rank relevant content.", exampleVi: "Các thuật toán tìm kiếm xếp hạng nội dung phù hợp."
        ),
        TopicWordDTO(
            id: 27, stageId: "stage_tech_1", lemma: "Automation", phonetic: "/ˌɑː.t̬əˈmeɪ.ʃən/", pos: "noun", cefrLevel: "B1",
            definitionVi: "Sự tự động hóa", definitionEn: "The use of largely automatic equipment",
            exampleEn: "Factory automation cuts production costs.", exampleVi: "Tự động hóa nhà máy cắt giảm chi phí sản xuất."
        ),
        TopicWordDTO(
            id: 28, stageId: "stage_tech_1", lemma: "Data-driven", phonetic: "/ˈdeɪ.t̬əˌdrɪv.ən/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Dựa trên dữ liệu", definitionEn: "Determined by or dependent on the collection of data",
            exampleEn: "We make data-driven marketing decisions.", exampleVi: "Chúng tôi đưa ra quyết định tiếp thị dựa trên dữ liệu."
        ),
        TopicWordDTO(
            id: 29, stageId: "stage_tech_1", lemma: "Cutting-edge", phonetic: "/ˌkʌt̬.ɪŋˈedʒ/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Tối tân, tiên tiến", definitionEn: "Highly advanced; innovative",
            exampleEn: "They use cutting-edge AI technology.", exampleVi: "Họ sử dụng công nghệ AI tối tân."
        ),
        TopicWordDTO(
            id: 30, stageId: "stage_tech_1", lemma: "Cybersecurity", phonetic: "/ˌsaɪ.bɚ.səˈkjʊr.ə.t̬i/", pos: "noun", cefrLevel: "B2",
            definitionVi: "An ninh mạng", definitionEn: "Protection of computer systems against cyberattacks",
            exampleEn: "Cybersecurity protects sensitive customer data.", exampleVi: "An ninh mạng bảo vệ dữ liệu khách hàng nhạy cảm."
        ),
        TopicWordDTO(
            id: 31, stageId: "stage_tech_1", lemma: "Scalability", phonetic: "/ˌskeɪ.ləˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Khả năng mở rộng", definitionEn: "The capacity to be changed in size or scale",
            exampleEn: "Cloud computing ensures system scalability.", exampleVi: "Điện toán đám mây đảm bảo khả năng mở rộng hệ thống."
        ),

        // Tech Stage 2 (6 words)
        TopicWordDTO(
            id: 32, stageId: "stage_tech_2", lemma: "Neural network", phonetic: "/ˈnʊr.əl ˈnet.wɜːrk/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Mạng nơ-ron nhân tạo", definitionEn: "A computer system modeled on the human brain",
            exampleEn: "Neural networks recognize complex speech patterns.", exampleVi: "Mạng nơ-ron nhận dạng các mẫu giọng nói phức tạp."
        ),
        TopicWordDTO(
            id: 33, stageId: "stage_tech_2", lemma: "Autonomous", phonetic: "/ɑːˈtɑː.nə.məs/", pos: "adjective", cefrLevel: "C1",
            definitionVi: "Tự hành, tự chủ", definitionEn: "Having the freedom to act independently",
            exampleEn: "Autonomous vehicles navigate city roads.", exampleVi: "Xe tự hành di chuyển trên các tuyến đường thành phố."
        ),
        TopicWordDTO(
            id: 34, stageId: "stage_tech_2", lemma: "Predictive", phonetic: "/prɪˈdɪk.tɪv/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Có tính dự báo", definitionEn: "Relating to the ability to predict",
            exampleEn: "Predictive analytics forecast market trends.", exampleVi: "Phân tích dự báo giúp định hình xu hướng thị trường."
        ),
        TopicWordDTO(
            id: 35, stageId: "stage_tech_2", lemma: "Disruptive", phonetic: "/dɪsˈrʌp.tɪv/", pos: "adjective", cefrLevel: "C1",
            definitionVi: "Mang tính đột phá", definitionEn: "Innovatively transforming an existing market",
            exampleEn: "Generative AI is a disruptive technology.", exampleVi: "AI tạo sinh là một công nghệ mang tính đột phá."
        ),
        TopicWordDTO(
            id: 36, stageId: "stage_tech_2", lemma: "Infrastructure", phonetic: "/ˈɪn.frəˌstrʌk.tʃɚ/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Hạ tầng cơ sở", definitionEn: "Basic physical and organizational structures",
            exampleEn: "Server infrastructure supports heavy traffic.", exampleVi: "Hạ tầng máy chủ đáp ứng lưu lượng truy cập lớn."
        ),
        TopicWordDTO(
            id: 37, stageId: "stage_tech_2", lemma: "Virtualization", phonetic: "/ˌvɜːr.tʃu.ə.laɪˈzeɪ.ʃən/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Sự ảo hóa", definitionEn: "Creation of a virtual version of something",
            exampleEn: "Server virtualization reduces hardware costs.", exampleVi: "Ảo hóa máy chủ giúp giảm chi phí phần cứng."
        ),

        // Academic Stage 1 (7 words)
        TopicWordDTO(
            id: 38, stageId: "stage_acad_1", lemma: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.t̬i/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Đa dạng sinh học", definitionEn: "The variety of plant and animal life in a habitat",
            exampleEn: "Deforestation threatens regional biodiversity.", exampleVi: "Phá rừng đe dọa sự đa dạng sinh học trong khu vực."
        ),
        TopicWordDTO(
            id: 39, stageId: "stage_acad_1", lemma: "Sustainability", phonetic: "/səˌsteɪ.nəˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự bền vững", definitionEn: "Avoidance of depletion of natural resources",
            exampleEn: "Environmental sustainability is a global goal.", exampleVi: "Sự bền vững môi trường là mục tiêu toàn cầu."
        ),
        TopicWordDTO(
            id: 40, stageId: "stage_acad_1", lemma: "Urbanization", phonetic: "/ˌɝː.bən.əˈzeɪ.ʃən/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự đô thị hóa", definitionEn: "The process of making an area more urban",
            exampleEn: "Rapid urbanization strains public transport.", exampleVi: "Đô thị hóa nhanh chóng gây áp lực lên giao thông công cộng."
        ),
        TopicWordDTO(
            id: 41, stageId: "stage_acad_1", lemma: "Detrimental", phonetic: "/ˌdet.rəˈmen.t̬əl/", pos: "adjective", cefrLevel: "C1",
            definitionVi: "Có hại, bất lợi", definitionEn: "Tending to cause harm",
            exampleEn: "Pollution has a detrimental effect on health.", exampleVi: "Ô nhiễm có ảnh hưởng bất lợi tới sức khỏe."
        ),
        TopicWordDTO(
            id: 42, stageId: "stage_acad_1", lemma: "Phenomenon", phonetic: "/fəˈnɑː.mə.nɑːn/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Hiện tượng", definitionEn: "A fact or situation that is observed to exist",
            exampleEn: "Climate change is a complex phenomenon.", exampleVi: "Biến đổi khí hậu là một hiện tượng phức tạp."
        ),
        TopicWordDTO(
            id: 43, stageId: "stage_acad_1", lemma: "Preservation", phonetic: "/ˌprez.ɚˈveɪ.ʃən/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự bảo tồn", definitionEn: "The act of keeping something safe from harm",
            exampleEn: "Forest preservation prevents soil erosion.", exampleVi: "Bảo tồn rừng giúp chống xói mòn đất."
        ),
        TopicWordDTO(
            id: 44, stageId: "stage_acad_1", lemma: "Depletion", phonetic: "/dɪˈpliː.ʃən/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Sự cạn kiệt", definitionEn: "Reduction in the number or quantity of something",
            exampleEn: "Resource depletion is an urgent challenge.", exampleVi: "Cạn kiệt tài nguyên là một thách thức cấp bách."
        ),

        // Academic Stage 2 (6 words)
        TopicWordDTO(
            id: 45, stageId: "stage_acad_2", lemma: "Fluctuation", phonetic: "/ˌflʌk.tʃuˈeɪ.ʃən/", pos: "noun", cefrLevel: "B2",
            definitionVi: "Sự biến động", definitionEn: "An irregular rising and falling in number or amount",
            exampleEn: "Currency fluctuations impact import prices.", exampleVi: "Biến động tỷ giá ảnh hưởng tới giá nhập khẩu."
        ),
        TopicWordDTO(
            id: 46, stageId: "stage_acad_2", lemma: "Unprecedented", phonetic: "/ʌnˈpres.ə.den.t̬ɪd/", pos: "adjective", cefrLevel: "C1",
            definitionVi: "Chưa từng có tiền lệ", definitionEn: "Never done or known before",
            exampleEn: "The crisis caused unprecedented economic loss.", exampleVi: "Cuộc khủng hoảng gây thiệt hại kinh tế chưa từng có."
        ),
        TopicWordDTO(
            id: 47, stageId: "stage_acad_2", lemma: "Discrepancy", phonetic: "/dɪˈskrep.ən.si/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Sự sai lệch, bất nhất", definitionEn: "A lack of compatibility or similarity between two facts",
            exampleEn: "There was a discrepancy in the budget report.", exampleVi: "Có một sự sai lệch trong báo cáo ngân sách."
        ),
        TopicWordDTO(
            id: 48, stageId: "stage_acad_2", lemma: "Paradigm shift", phonetic: "/ˈpær.ə.daɪm ʃɪft/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Bước chuyển dịch mô thức", definitionEn: "A fundamental change in approach or underlying assumptions",
            exampleEn: "Remote work created a cultural paradigm shift.", exampleVi: "Làm việc từ xa tạo ra một bước chuyển biến lớn trong văn hóa."
        ),
        TopicWordDTO(
            id: 49, stageId: "stage_acad_2", lemma: "Substantial", phonetic: "/səbˈstæn.ʃəl/", pos: "adjective", cefrLevel: "B2",
            definitionVi: "Đáng kể, quan trọng", definitionEn: "Of considerable importance, size, or worth",
            exampleEn: "They made substantial progress this quarter.", exampleVi: "Họ đã đạt được tiến bộ đáng kể trong quý này."
        ),
        TopicWordDTO(
            id: 50, stageId: "stage_acad_2", lemma: "Feasibility", phonetic: "/ˌfiː.zəˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "C1",
            definitionVi: "Tính khả thi", definitionEn: "The state or degree of being easily or conveniently done",
            exampleEn: "Engineers tested the technical feasibility of the design.", exampleVi: "Các kỹ sư đã kiểm tra tính khả thi kỹ thuật của thiết kế."
        )
    ]
}
