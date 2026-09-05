# Bằng chứng cho ý tưởng AI trong VocabCraft

Ngày kiểm tra: 2026-09-06. Phạm vi: sản phẩm học ngoại ngữ, cơ chế học, đối chiếu mã nguồn VocabCraft và tính khả thi kỹ thuật sơ bộ. Chưa benchmark model, lập dự toán API hoặc thiết kế kiến trúc triển khai. Đây là nghiên cứu để chọn giả thuyết sản phẩm, không phải bằng chứng rằng thêm AI chắc chắn cải thiện học tập. Đối tượng ưu tiên do người dùng xác nhận: người mới học, cần nhớ từ và tạo thói quen.

## 1. Những sản phẩm đang làm gì

### Duolingo: hội thoại có mục tiêu và gắn với bài học

Trang chính thức mô tả Roleplay theo tình huống đời sống, có nhận xét sau hội thoại. Video Call bắt đầu thường từ chủ đề đã học và có transcript. Đây là mô tả tính năng của nhà cung cấp, không phải thử nghiệm hiệu quả độc lập. Không suy ra các tính năng hoặc gói thuê bao giống nhau ở mọi thị trường. [Duolingo Max](https://blog.duolingo.com/duolingo-max/)

Duolingo mô tả rõ cách ràng buộc cuộc gọi theo trình độ CEFR, từ vựng mục tiêu, cấu trúc mở đầu–hội thoại–kết thúc và trợ giúp khi mắc kẹt. Họ tách bước tạo câu hỏi đầu tiên vì gộp quá nhiều yêu cầu có thể làm câu hỏi quá khó hoặc bỏ sót từ mục tiêu. Bài học thiết kế: người dùng có trải nghiệm tự nhiên nhờ hệ thống được kiểm soát phía sau. [How Duolingo uses AI to create speaking practice](https://blog.duolingo.com/ai-and-video-call/)

### Speak: biến nội dung vừa học thành bài tập liên quan đến cá nhân

Speak cho người học trả lời vài câu về mục tiêu, sở thích hoặc tình huống thực tế rồi tạo bài học tùy chỉnh ngay trong learning path, dựa trên mẫu câu vừa học. Tài liệu ghi tính năng còn beta, triển khai ở một số khóa. Đây là bằng chứng về một hướng sản phẩm, không chứng minh hiệu quả học tập hay độ phổ biến toàn thị trường. [Speak: Course Custom Lessons](https://help.speak.com/en/articles/11727854-how-to-create-your-own-lessons-course-custom-lessons)

**Suy luận sản phẩm:** Cơ hội phù hợp VocabCraft là nối bài học và luyện phản xạ với việc tự dùng từ trong tình huống. Chat tự do chỉ là một cách thể hiện, không nhất thiết là điểm khởi đầu.

## 2. Cơ sở học tập và giới hạn

### Tự nhớ lại vẫn quan trọng sau khi đã trả lời đúng

Thí nghiệm Karpicke & Roediger (2008) dùng 40 cặp từ Swahili–English. Tiếp tục luyện nhớ lại sau lần đúng đầu tiên giúp giữ nhớ sau một tuần tốt hơn các điều kiện ngừng kiểm tra. Nghiên cứu này ủng hộ retrieval practice, không chứng minh chatbot hoặc câu ví dụ AI tốt hơn SRS hiện có. Đối tượng và nhiệm vụ là học cặp từ trong thí nghiệm, chưa phải giao tiếp tự nhiên. [Bài gốc Science, bản PDF tại MIT](https://educationgroup.mit.edu/HHMIEducationGroup/wp-content/uploads/2011/04/14-Karpicke-Roediger-2008.pdf)

### Cần đo khả năng áp dụng, không chỉ lặp lại đáp án

Butler (2010) báo cáo bốn thí nghiệm: luyện kiểm tra giúp nhớ và trả lời câu hỏi suy luận mới sau một tuần tốt hơn đọc lại. Nội dung là đoạn văn và kiến thức, không phải thử nghiệm học ngoại ngữ bằng AI. Vì vậy đây là cơ sở để thử đo transfer; không phải bằng chứng trực tiếp rằng thêm tình huống AI sẽ tạo transfer trong VocabCraft. [Abstract của bài nghiên cứu](https://pubmed.ncbi.nlm.nih.gov/20804289/)

### Feedback có cơ sở, nhưng không phải mọi feedback đều tương đương

Lyster & Saito (2010) tổng hợp 15 nghiên cứu lớp học, 827 người học, và báo cáo tác động tích cực, bền của oral corrective feedback lên phát triển ngôn ngữ đích. Đó là nghiên cứu về feedback trong lớp học; không xác nhận độ chính xác hay hiệu quả của LLM chấm câu tự động. Phạm vi đọc ở đây là abstract và thông tin bài, không toàn bộ phân tích. [Oral Feedback in Classroom SLA](https://www.cambridge.org/core/journals/studies-in-second-language-acquisition/article/abs/oral-feedback-in-classroom-sla/4999EE1C8379B2BF026B148EAF373CA1)

### Làm bài tốt khi có AI không đồng nghĩa tự học tốt hơn

Bastani và cộng sự (2025) thử nghiệm ngẫu nhiên với gần một nghìn học sinh toán. Giao diện GPT không có ràng buộc cải thiện lúc luyện có hỗ trợ nhưng làm kết quả kém đi khi bỏ AI; tutor dùng gợi ý được thiết kế nhằm bảo vệ quá trình học giảm phần lớn tác động xấu đó. Đây là toán phổ thông, không phải từ vựng; chỉ nên rút ra nguyên tắc thiết kế và đo lường. Trang bài ghi có bản sửa đổi năm 2025; ghi chú này không sử dụng các con số effect size. [PNAS: Generative AI without guardrails can harm learning](https://doi.org/10.1073/pnas.2422633122)

## 3. Ba cơ hội sản phẩm cần kiểm chứng

Các mục sau là đề xuất dựa trên tổng hợp trên, không phải kết luận đã được nghiên cứu xác nhận cho VocabCraft.

### A. Từ đã học → nhiệm vụ dùng từ trong 3 phút

- Đầu vào: 3–5 từ vừa học hoặc còn yếu và một tình huống phù hợp trình độ.
- Trải nghiệm: app đưa mục tiêu cụ thể, người học tự viết/nói, AI đáp lại 2–4 lượt; kết thúc bằng một điểm làm tốt, một điểm cần sửa và một lượt thử lại.
- Khác với chatbot chung: không cần nghĩ prompt; hoạt động biết người học đang học từ nào và giúp đưa từ ấy vào sử dụng.
- Bản thử đầu: nhập văn bản, một vài tình huống có biên tập; voice là quyết định riêng sau khi xác nhận giá trị.
- Đo: sau 7 ngày, dùng được từ trong tình huống mới không gợi ý; thời gian mỗi câu và tỷ lệ hoàn thành là chỉ số phụ.

### B. Sửa đúng chỗ sau một lượt luyện phản xạ

- Đầu vào: câu sai hoặc từ dễ nhầm trong phiên vừa xong.
- Trải nghiệm: một giải thích ngắn bằng tiếng Việt, ví dụ đối chiếu, sau đó câu hỏi mới để người học tự sửa.
- Giá trị AI giả định: giải thích sát lỗi cụ thể, chấp nhận nhiều cách diễn đạt hợp lệ thay vì so một đáp án cứng.
- Không gán mọi lỗi cho người học: cần đường báo chấm sai và tập đánh giá do người giỏi ngôn ngữ duyệt.
- Đo: tỷ lệ lặp lại cùng lỗi ở lượt sau/ngày sau, tỷ lệ AI sửa sai câu vốn đúng.

### C. Biến deck thành bài luyện gắn với đời sống của tôi

- Đầu vào: deck đang học và một mục tiêu ngắn như họp công việc, du lịch hoặc sở thích.
- Trải nghiệm: tạo một đoạn hội thoại/bài tập ngắn sử dụng từ trong deck, rồi yêu cầu người học tự hoàn thành hoặc phản hồi; lưu lại nội dung hữu ích.
- Tránh biến thành máy sản xuất deck vô hạn: chỉ tạo lượng nội dung đủ cho một phiên và có đầu ra luyện tập cụ thể.
- Đo: tỷ lệ bắt đầu/hoàn thành và chất lượng dùng từ sau đó so với phiên cùng thời lượng không cá nhân hóa.

## 4. Đề xuất lựa chọn

Người dùng đã xác nhận ưu tiên người mới bắt đầu, cần nhớ từ và hình thành thói quen. Vì vậy nên thử **B dưới dạng hỗ trợ khi mắc kẹt** trước: giải thích ngắn, gợi ý tăng dần, rồi một lượt tự nhớ lại. Có thể kết hợp phiên A đơn giản với một câu có khung hoặc một tình huống rất ngắn; chưa cần hội thoại mở nhiều lượt. Đây là lựa chọn sản phẩm theo đối tượng, không phải kết luận nghiên cứu chứng minh AI tăng ghi nhớ hoặc hình thành thói quen. C hữu ích khi biết rõ người học có nhu cầu cá nhân hóa. Chưa có bằng chứng trong phạm vi nghiên cứu này rằng một tab AI chat chung là bắt buộc để cạnh tranh.

Thử nghiệm ban đầu nên giữ thời gian luyện ngang nhau giữa nhóm hiện tại và nhóm có AI; kiểm tra trì hoãn bằng câu/tình huống mới, không hiện gợi ý. Phỏng vấn và quan sát một nhóm nhỏ có thể chọn trải nghiệm phù hợp, nhưng không đủ để tuyên bố tăng hiệu quả học. Mọi quyết định triển khai còn cần kiểm tra dữ liệu thực có trong app, chất lượng tiếng Việt–English, chi phí và độ trễ.

## 5. Đối chiếu VocabCraft hiện tại

Các nhận xét sau dựa trên mã nguồn đã đọc tại commit `29483fc2`, không suy ra chỉ từ tài liệu thiết kế cũ:

- [Placeholder](../../VocabCraftApp/Features/AIAssistant/Views/AIAssistantPlaceholderView.swift) giới thiệu hội thoại, ngữ cảnh và phát âm. [AppStrings](../../VocabCraftApp/Core/Localization/AppStrings.swift) còn có mô tả mặc định hứa mô hình on-device. Đây là lời giới thiệu, chưa phải bằng chứng năng lực đã triển khai; nên điều chỉnh theo tính năng thật khi thiết kế được chốt.
- [SenseDetail](../../VocabCraftApp/Core/Content/ContentModels.swift) có nghĩa EN/VI, CEFR, usage notes, ví dụ, collocations và revision. AI có thể nhận đúng nghĩa đang học để tạo gợi ý sát nội dung; vẫn cần kiểm tra độ đầy đủ của dataset.
- [LearningEvents](../../VocabCraftApp/Core/Learning/LearningEvents.swift) phân biệt recognition, recall, application; có evaluatorVersion, unscored, hintCount và retryCount. Đây là nền tảng biểu diễn kết quả, không chứng minh bộ chấm vận dụng đã tồn tại.
- [SmartVaultWordSelector](../../VocabCraftApp/Domain/UseCases/SmartVaultWordSelector.swift) đã ưu tiên theo mode, chuỗi đúng và thời gian luyện. [HomepageViewModel](../../VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift) đã có mục tiêu ngày và streak. Không cần LLM quyết định lịch ôn hay viết lại cơ chế thói quen để bắt đầu thử AI.
- [ReflexSpeechMatcher](../../VocabCraftApp/Core/Audio/ReflexSpeechMatcher.swift) so transcript với từ đích và biến thể. Không dùng kết quả đó làm bằng chứng chấm ngữ nghĩa câu hoặc phát âm theo âm vị.
- [QuickReflexAttempt](../../VocabCraftApp/Domain/Models/QuickReflexAttempt.swift) lưu các chỉ số lần thử nhưng không lưu nguyên văn câu trả lời. Chưa kiểm chứng khả năng lấy lại chi tiết lỗi lịch sử trên mọi luồng; bản thử có thể dùng câu trả lời ngay trong phiên, tránh hứa AI biết mọi lỗi cũ.

## 6. Đề xuất riêng cho người mới: “Bạn học từ”

Lời hứa sản phẩm đề xuất: **Giúp bạn hiểu từ đang vướng, tự nhớ lại và hoàn thành một lượt học nhỏ hôm nay.** Đây là concept để thảo luận, chưa phải spec được duyệt.

| Hướng | Giá trị giả định | Giới hạn | Ưu tiên |
| --- | --- | --- | --- |
| Gỡ rối một từ: giải thích sát câu trả lời, gợi ý và thử lại | Giúp tiếp tục khi mắc kẹt; nối trực tiếp vào bài học | Phải kiểm tra AI giải thích đúng và không sửa câu đúng | Thử đầu tiên |
| Ôn 3 từ trong ngữ cảnh quen thuộc | Đổi ví dụ để bớt lặp máy móc, vẫn ôn đúng từ | Có thể tạo câu quá khó; 3 từ/3 phút chỉ là giả thuyết UX | Mở rộng sau |
| Bạn đồng hành hội thoại | Tập giao tiếp phong phú | Yêu cầu tự diễn đạt và vận hành voice lớn hơn | Để sau khi người học sẵn sàng |

### Một phiên minh họa

1. Sau bài học hoặc từ Kho Từ, người học chọn “Giúp mình nhớ từ này”. Không cần tự viết prompt.
2. Với `borrow`, app cho một câu hỏi ngắn để thử nhớ trước. Nếu người học nhầm với `lend`, AI giải thích ngắn: borrow là mượn từ ai; lend là cho ai mượn.
3. Nếu cần, đưa khung câu `Can I ___ your pen?`; chỉ hiện đáp án sau khi người học đã thử hoặc chủ động yêu cầu xem.
4. Sau một mục khác, thử câu mới `Can I ___ your book?`, giảm gợi ý. Đây mới là một tín hiệu tự nhớ lại, chưa phải “đã thành thạo”.
5. Kết thúc bằng kết quả quan sát được: từ nào tự nhớ được, từ nào còn cần gợi ý; đưa lần ôn tiếp theo về cơ chế hiện có.

Ở lần đầu chưa có lịch sử, dùng từ vừa học hoặc người dùng chọn. Không tự bịa rằng người học hay quên một từ. Nếu chỉ có đáp án chọn sai, có thể hỏi người học đang vướng nghĩa, cách dùng hay cách nhớ; không khẳng định nguyên nhân sai từ một tín hiệu mơ hồ.

AI có giá trị giả định ở việc phản hồi câu trả lời khác nhau, diễn giải lại và tạo ví dụ phù hợp. Các câu hỏi cố định, chọn từ cần ôn, streak và lịch nhắc nên dùng logic/nội dung hiện có. Không gọi model chỉ để đổi lời chúc mừng.

Tab hiện tại có thể trở thành nơi bắt đầu “Ôn vài từ hôm nay” hoặc “Gỡ rối một từ”; điểm vào ngay lúc mắc kẹt trong bài học có thể hữu ích hơn. Không cần làm cả hai bề mặt ở bản thử đầu. Tên nút/câu minh họa ở đây là nội dung đề xuất trong tài liệu; khi triển khai phải tuân thủ catalog EN/VI và CraftUIKit của repo.

## 7. Phạm vi thử nhỏ và kỹ thuật

- Thử một luồng trợ giúp bằng văn bản, khoảng 20–30 nghĩa từ A1–A2 đã biên tập; một giải thích ngắn, một ví dụ, một lượt tự thử lại. Đây là phạm vi đề xuất để đánh giá, không phải ước tính tiến độ.
- Cấp cho AI nghĩa chuẩn, ví dụ/collocation, trình độ và câu trả lời hiện tại. Cố định cấu trúc phản hồi, giới hạn độ dài. Nội dung sinh ra là nội dung học tạm thời, không tự sửa từ điển gốc.
- Chấm đáp án đóng bằng logic cố định. Phản hồi mở ban đầu mang tính hướng dẫn; chưa để điểm LLM chưa được kiểm định thay đổi mastery/SRS. Khi không đánh giá được, dùng trạng thái chưa chấm và nội dung biên tập dự phòng.
- Chỉ thêm voice sau khi giá trị trợ giúp đã rõ. Microsoft mô tả pronunciation assessment dùng model riêng khác STT thông thường; điều này củng cố việc tách nhận diện lời nói và đánh giá phát âm. [Microsoft pronunciation assessment](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/how-to-pronunciation-assessment)
- Apple công bố Foundation Models hỗ trợ suy luận on-device, offline và không tính phí suy luận trên thiết bị tương thích khi Apple Intelligence được bật. Đây là lựa chọn để thử, không bảo đảm mọi máy hoặc chất lượng phản hồi tiếng Việt đều đạt. Cần kiểm tra availability, locale và chất lượng trên thiết bị thực. [Apple Foundation Models](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- Chưa chọn cloud hay on-device trước khi chạy cùng bộ câu hỏi đánh giá. Nếu dùng cloud: backend giữ API key, hạn mức lượt và chi phí, giới hạn context; thông báo rõ dữ liệu gửi đi. Chi phí cần tính theo token đầu vào/đầu ra, số lượt, retry và âm thanh nếu có, thay vì đoán giá mỗi người dùng.

## 8. Cách biết có đáng phát triển tiếp

Đầu tiên thử trải nghiệm với khoảng 5–8 người mới học để quan sát họ có hiểu trợ giúp, tự thử lại và hoàn thành phiên hay không. Quy mô này chỉ kiểm tra usability, không chứng minh hiệu quả học.

Tiếp theo so với phiên ôn hiện tại có thời lượng tương đương:

- Chính: tỷ lệ tự nhớ từ sau 24 giờ và 7 ngày, không gợi ý; dùng thêm câu mới đơn giản phù hợp trình độ.
- Phụ: hoàn thành phiên, quay lại trong tuần, số lần chủ động dùng trợ giúp, mức thấy dễ tiếp tục học. Quay lại trong tuần chưa đủ kết luận đã hình thành thói quen lâu dài.
- Chất lượng: tỷ lệ giải thích sai, sửa nhầm câu đúng, lộ đáp án quá sớm, ngôn ngữ vượt trình độ; cần người có chuyên môn kiểm tra bộ mẫu.
- Vận hành: độ trễ phản hồi và chi phí mỗi phiên hoàn thành; ngưỡng chấp nhận cần chốt theo ngân sách và thử nghiệm thật.

Nếu AI chỉ tăng lượt bấm nhưng không cải thiện khả năng tự nhớ hoặc sự dễ hiểu so với trợ giúp biên tập, nên thu hẹp thành trợ giúp theo yêu cầu. Chưa có lý do buộc mọi phiên học phải dùng AI.
