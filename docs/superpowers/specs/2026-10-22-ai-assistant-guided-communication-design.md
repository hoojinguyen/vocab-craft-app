# AI Assistant: luyện giao tiếp từ vốn từ đã học

- Ngày: 2026-10-22
- Trạng thái: Đã được người dùng phê duyệt ngày 2026-10-22, bao gồm các lựa chọn mục 15.
- Được phép lập implementation plan; thực thi cần review kế hoạch và chọn execution method theo Superpowers.
- Đối tượng đầu tiên: learner A2–B1.
- Phạm vi: nhiệm vụ giao tiếp, giảm trợ giúp, bằng chứng vận dụng, tích hợp hệ thống học hiện có.

## 1. Mục tiêu và quyết định đã thống nhất

Giúp learner tự huy động từ đã học để giao tiếp đúng ngữ cảnh, giảm dần phụ thuộc vào gợi ý. Phản xạ nói và AI dẫn dắt việc học hằng ngày phục vụ mục tiêu này.

Trải nghiệm cốt lõi: nhiệm vụ giao tiếp → trợ giúp theo mức → thử lại ít hỗ trợ → vận dụng trong ngữ cảnh mới. Thành công nhờ câu mẫu là kết quả luyện tập có giá trị, nhưng không phải bằng chứng tự sử dụng.

Các quyết định đã thống nhất:

1. App quyết định mục tiêu, độ khó và công nhận tiến bộ bằng quy tắc có thể kiểm thử. AI tạo hội thoại, đề xuất phản hồi và đánh giá có cấu trúc trong giới hạn đó.
2. Ghi nhận mọi hỗ trợ đã thực sự trình bày, gồm nhắc từ trước bài, gợi ý, câu mẫu và từ nhân vật vừa nói.
3. Tiến bộ giao tiếp lưu riêng với SRS; không tự tăng mastery hoặc đẩy lịch ôn khi phát hiện từ trong transcript.
4. Voice và text dùng chung nhiệm vụ nhưng có bằng chứng tiến bộ riêng.
5. Tận dụng CraftUIKit, vocabulary, tiến độ, roleplay, AI Pack và audio hiện có.

Các ngưỡng định lượng trong tài liệu là cấu hình khởi đầu cho pilot, không phải kết luận đã được kiểm chứng về hiệu quả học.

## 2. Phạm vi phiên bản đầu

### Bao gồm

- Bốn màn hình: Hub, chuẩn bị, thực hành, nhìn lại.
- Nhiệm vụ từ template được biên soạn; AI biến đổi chi tiết trong ranh giới template.
- Hai từ trọng tâm, tối đa một từ ôn bổ sung; có thể giảm còn một từ.
- Trợ giúp năm mức, lượt thử lại và kiểm tra chuyển giao ở buổi sau.
- Lưu phiên, phục hồi sau gián đoạn, đánh giá có thể không chắc chắn, thao tác retry không ghi trùng.
- Tích hợp đọc dữ liệu học hiện có; lưu bằng chứng mới qua SwiftData.
- EN/VI đầy đủ cho UI, accessibility và template biên soạn.

### Để ngoài phiên bản đầu

- Chat tự do như một sản phẩm độc lập, bộ lập chương trình học toàn app, thay thuật toán SRS.
- Chấm điểm phát âm chuyên sâu hoặc suy ra fluency từ số lượt nói.
- Full-duplex voice, tự ngắt lời nhân vật, một hệ thống AI provider mới.
- Sinh nhiệm vụ không giới hạn, tự tạo video Shadowing, tự đồng bộ dữ liệu hội thoại lên cloud.
- Hệ thống XP mới. Luồng mới không cộng XP hay todayWordsLearned dựa trên số từ phát hiện; summary chỉ trình bày bằng chứng học. Tích hợp thưởng là thay đổi sản phẩm riêng.

## 3. Căn cứ hiện trạng

Các đường dẫn dưới đây tương đối với repository root, được kiểm tra từ source trong cuộc thảo luận. Đây là khảo sát tĩnh, chưa phải chứng nhận runtime.

| Thành phần | Hiện trạng cần tính đến |
|---|---|
| `VocabCraftApp/Features/AIAssistant/ViewModels/AIAssistantHubViewModel.swift` | Chọn scenario đầu làm daily; nhận weakWords từ bên gọi |
| `VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift` | Tạo scenario adaptive chung từ tối đa ba chuỗi từ |
| `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift` | Hợp nhận diện fuzzy và từ LLM trả về; chưa tách đầy đủ bằng chứng hỗ trợ |
| `VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift` | Tính fluency theo tỷ lệ từ/lượt; ghi challenge result cho masteredWords |
| `VocabCraftApp/Data/Local/Actors/UserProgressModelActor+Mutations.swift` | recordChallengeResult có thể tăng masteryLevel và thay sourceDeckId |
| `VocabCraftApp/Domain/Entities/RoleplayScenario.swift` | targetWordIds hiện là chuỗi từ, không phải ID từ vựng Int64 |
| `VocabCraftApp/Core/Database/Schemas/AppSchemaV2.swift` | Có progress, SRS fields và QuickReflexAttemptRecord |
| `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift` | Store App Group và migration V1 → V2 hiện hữu |
| `VocabCraftApp/App/DI/AppContainer.swift` | Điểm lắp ghép use case, roleplay, voice và Shadowing |

Spec này thay quy tắc sư phạm và ghi kết quả cho luồng mới. Các spec AI Pack/audio cũ vẫn là bối cảnh, nhưng không được dùng để suy ra provider hiện chạy đúng trên thiết bị.

## 4. Quy tắc chọn nhiệm vụ

### 4.1 Từ đủ điều kiện

Dùng wordId Int64 và dữ liệu vocabulary chính thức. Từ phải có bằng chứng đã học: totalReviews > 0 hoặc masteryLevel > 0. Bookmark đơn thuần không đủ. Record không còn resolve được trong vocabulary bị loại khỏi lựa chọn mới; lịch sử vẫn có snapshot để hiển thị.

Đọc tiến độ từ UserProgressRepositoryProtocol. Không xem giá trị CEFR mặc định trên record là đánh giá năng lực learner. Phạm vi A2–B1 là cấu hình nhiệm vụ, không phải nhãn chẩn đoán cá nhân.

### 4.2 Xếp ưu tiên v1

Lọc theo template có thể tạo cơ hội dùng từ tự nhiên, rồi xếp theo thứ tự:

1. Bằng chứng gần đây dùng chưa phù hợp hoặc còn cần gợi từ/khung/câu mẫu, đã đến nextPracticeAt.
2. Đã từng tự dùng và đến hạn kiểm tra lại giao tiếp.
3. Đã học nhưng chưa có bằng chứng giao tiếp.

Trong cùng nhóm: từ đến hạn SRS trước, sau đó ngày luyện giao tiếp cũ nhất (chưa luyện đứng trước), cuối cùng wordId để kết quả ổn định. Tối đa hai từ trọng tâm; thêm một từ ôn chỉ khi cùng template có cơ hội tự nhiên. Không đủ thì dùng một từ; không có từ đủ điều kiện thì dẫn về bài học.

selectionReasons lưu mã lý do, không lưu lời giải thích tùy ý do LLM sáng tác. UI diễn đạt mã qua localization.

### 4.3 Template và mục tiêu

Template chứa ID/version, khóa nội dung EN/VI, vai nhân vật, nhóm bối cảnh, ý định giao tiếp cần hoàn thành, biến thể được phép, giới hạn khó và liên kết nội dung bổ trợ đã có nếu phù hợp. Bộ pilot gồm ba nhóm: ăn uống, mua sắm và sắp xếp kế hoạch; mỗi nhóm có một tình huống cơ bản và một biến thể chuyển giao.

AI có thể thay chi tiết và lời thoại, nhưng output phải thỏa schema và mục tiêu template. Nếu không ghép được từ tự nhiên, bỏ từ phụ hoặc chọn template khác. Không buộc learner dùng một lemma cụ thể để được công nhận hoàn thành ý định.

## 5. Trợ giúp và mức tiến bộ

### 5.1 Thang hỗ trợ

| Mức | Nội dung |
|---|---|
| none | Chỉ bối cảnh và lời thoại cần thiết |
| intent | Nhắc ý cần diễn đạt, không tiết lộ từ mục tiêu |
| lexical | Gợi từ hoặc cụm từ |
| frame | Khung câu có chỗ trống |
| model | Câu mẫu đầy đủ, đọc mẫu hoặc nghe mẫu |

Nút xin giúp luôn có sẵn. Mỗi lần xin giúp tăng tối đa một mức; learner có thể yêu cầu câu mẫu trực tiếp. Một lần thử lại sau hỗ trợ thành công giảm một mức. Nếu lại gặp khó, khôi phục mức trước, không xóa bằng chứng cũ.

Không tự nâng trợ giúp vì im lặng. Learner có thể chọn “Tôi đang nghĩ” hoặc yêu cầu giúp; audio timeout chỉ tạo trạng thái thao tác, không tạo thất bại học.

### 5.2 Ghi nhận exposure và sự độc lập

Ghi exposure khi nội dung thực sự được render cho learner hoặc audio bắt đầu phát. Tạo response nhưng chưa trình bày không phải exposure. Mở lại nội dung có ghi exposure mới nhưng không tạo bằng chứng thành công mới.

Mỗi exposure gắn từ liên quan và nguồn: prelessonReview, learnerRequested, coachSuggested, characterSpeech, correction, transcriptReplay. Nếu lời nhân vật/feedback có từ mục tiêu, nó cũng là lexical exposure. Câu mẫu tương đương câu trả lời tạo model exposure. Khi không xác định chắc từ liên quan, áp dụng bảo thủ cho toàn bộ target words của nhiệm vụ.

Trong cùng phiên, mọi lexical/frame/model exposure trước lần thử cho từ đó khiến lần thử mang nhãn primed. Lượt thử lại có thể chứng minh giảm hỗ trợ, nhưng không tăng bộ đếm tự nhớ độc lập. intent-only không tiết lộ từ được phép trong mức “tự dùng trong tình huống quen”, song vẫn ghi lại.

Không thể biết mọi hỗ trợ bên ngoài app. Nhãn sản phẩm phải diễn đạt “không dùng gợi ý trong bài”, không tuyên bố chứng minh tuyệt đối không có trợ giúp ngoài app.

### 5.3 Trạng thái giao tiếp

- noEvidence: chưa có bằng chứng đủ dùng, hiển thị “Chưa luyện giao tiếp”.
- practicing: đã thử hoặc đã dùng với hỗ trợ.
- independentFamiliar: ít nhất hai lần usage=appropriate, transcript đủ tin cậy, không bị primed, tối đa intent support, thuộc hai cơ hội khác nhau. Mỗi phiên chỉ đóng góp tối đa một lần cho mỗi wordId/inputMode.
- transferred: đạt independentFamiliar và có thêm một lần phù hợp, không gợi ý (none), không primed, ở phiên khác sau ít nhất 24 giờ so với lần độc lập gần nhất, với contextFamily khác.

Ngưỡng thời gian dùng elapsed UTC; timezone chỉ ảnh hưởng hiển thị. Cùng buổi đổi cửa hàng không tự thành contextFamily mới. ContextFamily do template quy định, AI không tự đặt để nâng trạng thái.

Trạng thái thể hiện bằng chứng từng đạt; nextPracticeAt và kết quả gần đây thể hiện nhu cầu luyện tiếp. Một lần lỗi không xóa thành tựu. Khi bằng chứng bị sửa/xóa, tổng hợp được tính lại và có thể giảm trạng thái.

Lịch giao tiếp khởi đầu: sau kết quả có hỗ trợ/chưa phù hợp là 24 giờ; independentFamiliar là 3 ngày; transferred là 7 ngày. Learner vẫn có thể tự luyện sớm; luyện sớm không vượt điều kiện chuyển giao. Không thay nextReviewDate của SRS.

## 6. Điều chỉnh độ khó

Difficulty có ba trục: số/ràng buộc ý định, độ trực tiếp của lời nhân vật, mức mới của bối cảnh. Mỗi trục có ba mức template định nghĩa. Phiên đầu bắt đầu một yêu cầu rõ, lời thoại ngắn một ý, bối cảnh quen.

Hai cơ hội liên tiếp hoàn thành ý định, dùng từ phù hợp, tối đa intent support và không primed → tăng một trục ở nhiệm vụ tiếp theo. Thứ tự tăng: độ trực tiếp, ràng buộc nhiệm vụ, bối cảnh. Khi đã ở mức tối đa thì giữ nguyên.

Hai cơ hội liên tiếp vẫn chưa hoàn thành sau hỗ trợ → trước tiên giảm ràng buộc nhiệm vụ một mức; nếu đã tối thiểu thì tăng mức hỗ trợ khởi điểm đề xuất. Learner vẫn được thử tự nói trước. Kết quả lẫn lộn giữ nguyên mức.

Lỗi kỹ thuật, chưa đủ chắc chắn, dùng từ đồng nghĩa phù hợp và learner tự dừng không tính thất bại. Difficulty snapshot được giữ cố định cho nhiệm vụ đang chạy; thay đổi nhiệm vụ đang khó phải tạo revision có lý do, không âm thầm đổi mục tiêu.

## 7. Luồng màn hình và CraftUIKit

### 7.1 Hub

Một CraftActionCard cho nhiệm vụ đề xuất: hoàn cảnh, lợi ích, lý do lựa chọn qua localization. Phiên dở ưu tiên CTA Tiếp tục. Chủ đề khác qua CraftListRow/CraftCard. AI Pack nằm ở cấu hình phụ, chỉ nổi bật khi cản trở bắt đầu.

Các trạng thái: loading, có nhiệm vụ, có phiên dở, chưa có từ đủ điều kiện, lỗi đọc dữ liệu. CraftEmptyState và nút retry phục vụ trạng thái rỗng/lỗi. Không dùng nội dung demo làm dữ liệu cá nhân thật.

### 7.2 Chuẩn bị

CraftCard trình bày vai, hoàn cảnh và mục tiêu. CraftChoiceCard chọn nói/nhập. Không hiện từ trọng tâm mặc định. “Ôn từ trước” mở nội dung ngay trong luồng và ghi exposure. Bắt đầu voice mới xin quyền mic cần thiết; thiếu quyền vẫn có đường dùng text.

Preflight xác minh capability cần cho mode hiện tại. Chưa sẵn sàng có lựa chọn sửa cấu hình, retry hoặc text nếu text thực sự khả dụng; không giả định text giải quyết lỗi LLM.

### 7.3 Thực hành

Một screen ổn định cho lời nhân vật, transcript, coach và input. CraftTactileMicHubView cho mic; CraftTextField/CraftButton cho text và thao tác; CraftCard cho nội dung trợ giúp. Không render toàn bộ câu gợi ý sẵn.

Bản đầu learner chủ động bắt đầu/kết thúc thu âm. Trước TTS phải dừng capture; chỉ một bên sở hữu audio lease tại một thời điểm. Transcript không chắc chắn có lựa chọn nghe lại/thu lại/chuyển text. Sửa transcript được ghi thành editedTranscript, không tính thành bằng chứng nói độc lập.

Phản hồi inline ở khoảng nghỉ, tối đa một trọng tâm sửa mỗi lượt. Không mở sheet cho mỗi lỗi ngữ pháp. Nút kết thúc/tạm dừng luôn có thể truy cập. Mục tiêu hoàn tất dựa trên objective, không phần trăm suy từ số lượt.

### 7.4 Nhìn lại

CraftListRow + CraftBadge biểu diễn kết quả mỗi từ và mức trợ giúp. Cho mở câu làm bằng chứng, ghi rõ text hoặc voice. CraftFeedbackSheet dùng ở điểm kết thúc phù hợp; không xếp nhiều modal. CTA đề xuất buổi tiếp theo hoặc nội dung bổ trợ có liên kết thực.

Hoàn tất một phần vẫn có summary trung thực. Lỗi ghi dữ liệu hiện trạng thái chưa lưu, không giả vờ thành công. Không hiển thị fluencyScore cũ trong luồng mới.

### 7.5 Quy chuẩn chung

Chỉ dùng Craft tokens cho màu, font, spacing, radius, depth. Hỗ trợ Dynamic Type, VoiceOver, Reduce Motion; thông tin không chỉ biểu đạt bằng màu. Mọi label/hint/value tĩnh có EN/VI, extractionState=manual, state=translated và format parity.

Dùng app.ai_assistant.* cho nội dung màn hình; craft.* cho mặc định chung của component. Nội dung hội thoại động và transcript là dữ liệu, không phải literal UI. Template biên soạn và các câu fallback phải đi qua catalog. V1 không thêm component thiết kế hệ thống; nếu API hiện có không đáp ứng, phải trao đổi theo AGENTS.md trước khi mở rộng hoặc tạo view dùng lại mới.

## 8. Domain model và storage contract

Các domain snapshot là value types Codable/Sendable. SwiftData model chỉ tồn tại trong actor sở hữu context. Không truyền @Model qua actor hoặc để view tự sửa bằng chứng.

| Model | Trường bắt buộc/chính |
|---|---|
| PracticeMission | id UUID; templateId/version; targetWordIds [Int64]; wordSnapshots; objectiveIds; contextFamily; difficulty; selectionReasons; policyVersion; createdAt |
| PracticeSession | id UUID; missionSnapshot; status; startedAt; completedAt optional; checkpoint; revision Int; initialInputMode; policyVersion |
| PracticeTurn | id UUID; sessionId; sequence; speaker; inputMode; originalText; acceptedText; transcriptStatus; generationStatus; requestId; sessionRevision; timestamp |
| SupportExposure | id UUID; sessionId; turnId optional; wordIds; level; origin; contentSnapshot; presentedAt; channel visual/audio |
| WordUseEvidence | id UUID; sessionId; turnId; wordId; objectiveId; usageVerdict; intentVerdict; transcriptReliability; supportExposureIds; primed; contextFamily; inputMode; quotedSpan; assessmentVersion; providerIdentity; status; timestamp |
| CommunicationProgress | wordId + inputMode logical key; stage; independentEvidenceIds; lastIndependentUseAt optional; nextPracticeAt optional; recentOutcome; policyVersion |

wordSnapshots gồm lemma và nghĩa đích tại lúc tạo bài; đánh giá phải đúng nghĩa mục tiêu. ID từ không được LLM tự phát minh. quotedSpan phải thuộc acceptedText; evidence cho từ không có cơ hội dùng ghi notObserved, không incorrect.

usageVerdict: appropriate / inappropriate / notObserved / uncertain. intentVerdict: achieved / notYet / uncertain. transcriptReliability: usable / needsConfirmation / unavailable; không yêu cầu confidence số nếu STT không cung cấp.

Evidence.status: valid / superseded. Sửa transcript tạo turn revision và supersede assessment cũ, rồi đánh giá lại. Progress chỉ tổng hợp valid evidence. Assessment uncertainty không nâng/giảm mức học.

inputMode của bằng chứng là voice / typed / editedTranscript. Chỉ voice với transcript usable được xét cho tiến bộ nói; typed được tổng hợp riêng; editedTranscript chỉ là bằng chứng luyện tập. Các lần thử không có cơ hội giao tiếp hợp lệ không được đưa vào chuỗi thành công/thất bại để điều chỉnh độ khó.

Session lưu snapshot nhiệm vụ để resume không thay bài khi catalog/policy cập nhật. CommunicationProgress là cache suy ra từ evidence, có thể rebuild. Lịch sử hiển thị template đã dùng, không rewrite theo template mới.

## 9. Các ranh giới trách nhiệm

- Mission selection use case: đọc vocabulary/progress/evidence, chọn template và Difficulty. Clock, policy và nguồn dữ liệu được inject.
- Session coordinator: owner duy nhất của trạng thái phiên và tác vụ. UI-bound @Observable/@MainActor theo kiến trúc hiện có; domain policy là logic thuần.
- Turn assessment use case: kiểm tra output AI, identity, quoted span, ngữ cảnh, exposure; trả evidence đề xuất, không tự ghi SRS.
- Adaptation policy: tính mức hỗ trợ, độ khó, trạng thái tiến bộ và lịch giao tiếp bằng quy tắc xác định.
- Practice repository: lưu transaction, checkpoint, deduplicate, truy vấn và xóa; triển khai @ModelActor.
- AppContainer: inject các dependency, giữ provider và audio adapters hiện hữu sau khi xác minh contract.

Quick Reflex là nguồn phụ cho lựa chọn bài; không đổi log cũ thành bằng chứng hội thoại. Shadowing chỉ được đề xuất khi có nội dung phù hợp; không hứa có video cho mọi lỗi.

## 10. AI contract và capability

Request chứa template, mục tiêu, từ/định nghĩa, mức khó, lịch sử cần thiết và support budget. Nội dung learner nằm trong message dữ liệu, không ghép thành instruction đặc quyền. Giới hạn lịch sử bằng snapshot mục tiêu + các lượt gần nhất; context summary không thay transcript dùng làm bằng chứng.

Output tách characterReply, objectiveAssessment, wordAssessments, coachFeedback và hintCandidate. AI không trả mastery hoặc XP. Mỗi assessment có wordId và quotedSpan; app kiểm tra thuộc mission, span khớp và cấu trúc hợp lệ. Ý nghĩa/ngữ pháp vẫn cần đánh giá chất lượng qua human rubric; JSON hợp lệ không bảo đảm sư phạm đúng.

Trợ giúp chỉ được trình bày trong mức policy cho phép. Character reply lỡ chứa từ mục tiêu phải ghi exposure trước lượt tiếp theo. Output rỗng/sai schema thử sửa định dạng tối đa một lần; tiếp tục lỗi thì chuyển trạng thái có thể retry, không dùng dữ liệu rỗng như thành công.

Capability tách canGenerateDialogue và canAssessUsage. Provider không đánh giá được vẫn cho luyện nếu hội thoại khả dụng, nhưng hiển thị chưa đánh giá được và không nâng stage. Không âm thầm thay cloud/offline hoặc gửi dữ liệu sang provider khác. Đổi provider theo hành động learner giữ checkpoint và ghi identity mới.

## 11. State machine, phục hồi và tính nhất quán

Các trạng thái: preparing → awaitingLearner → capturing (voice) → processing → playingCharacter (nếu có audio) → awaitingLearner hoặc coaching → awaitingLearner; mọi trạng thái hoạt động có thể về paused/recoverableError; kết thúc qua saving → completed/partial.

Mỗi tác vụ gắn sessionId, requestId, revision. Chỉ kết quả khớp revision còn hoạt động được apply. Cancel/đổi input/đổi provider tăng revision và hủy tác vụ cũ; callback đến muộn bị bỏ qua.

Lưu turn accepted và trạng thái pending trước network call. Sau assessment hợp lệ, lưu evidence, progress cache và checkpoint trong một transaction. Logical uniqueness của evidence là sessionId + turnId + wordId + assessmentVersion; chỉ một assessment valid cho một turn revision/wordId. Retry đánh giá không tăng số lần vận dụng.

Khi lưu exposure thất bại, tạm dừng trình bày hỗ trợ. Nếu UI/audio đã hiển thị trước lỗi ghi, đánh dấu exposure chưa chắc chắn và phiên không đủ điều kiện tăng độc lập đến khi phục hồi. Không bỏ sót exposure để công nhận sai.

App background hoặc cuộc gọi hệ thống: dừng mic/TTS, checkpoint, paused. Resume không tự bật mic. Crash sau ghi turn nhưng trước phản hồi: khôi phục pending, learner chọn tiếp tục; không tạo lượt user thứ hai. Nếu phản hồi có thể đã được trình bày trước crash nhưng exposure chưa được xác nhận lưu, checkpoint phải giữ cờ exposureUncertain; phiên đó không được tính bằng chứng độc lập cho các từ có thể liên quan. Finalize cùng session nhiều lần trả cùng kết quả.

| Lỗi | Hành vi |
|---|---|
| STT không nghe được/không chắc | Thu lại, xác nhận hoặc text; không tạo lỗi kiến thức |
| Network/rate limit/LLM timeout | Giữ lượt learner, hiển thị retry có thể hủy; không retry vô hạn |
| TTS lỗi | Giữ text reply, cho đọc tiếp hoặc phát lại; ghi audio exposure theo thực tế |
| Download/provider chưa sẵn sàng | Chặn mode bị ảnh hưởng, cung cấp hành động cấu hình phù hợp |
| Save lỗi | Hiển thị chưa lưu, giữ dữ liệu chờ và retry; không công nhận persisted completion |
| Learner kết thúc sớm | Lưu partial và bằng chứng hợp lệ; không tự đánh dấu objectives còn lại thất bại |

Request timeout ban đầu: 30 giây cho generation/assessment, 20 giây cho chuẩn bị TTS; đây là giới hạn kỹ thuật cấu hình, không phải tiêu chí năng lực learner.

## 12. Migration, quyền riêng tư và xóa dữ liệu

Thêm SchemaV3 cho các record mới, mở rộng AppMigrationPlan; xác minh V1 → V2 → V3 và V2 → V3 trên bản sao store. Giữ nguyên toàn bộ SRS/mastery/sourceDeckId cũ. App và extensions dùng chung App Group phải build với schema tương thích; không cho bản cũ mở store mới trong quy trình rollback.

Legacy roleplay không đủ metadata được xem là lịch sử luyện, không backfill independent evidence. Dùng adapter sang wordId chỉ khi resolve duy nhất và chắc chắn; trường hợp trùng lemma/nghĩa không đoán.

Feature rollout có cờ nội bộ: tắt entry point mới vẫn giữ dữ liệu V3 và chạy luồng tương thích schema. Không rollback bằng xóa store. Không ghi metadata Xcode phát sinh vào commit mà chưa kiểm tra và giải thích.

Transcript, evidence và exposure lưu cục bộ cho resume/review; audio raw chỉ là file tạm cho lượt hiện tại, xóa khi hết nhu cầu phát lại, kết thúc hoặc xóa phiên. Không đưa transcript/API key vào diagnostic logs. Cloud provider nhận nội dung cần thiết sau thông báo/lựa chọn provider; không gửi toàn bộ lịch sử học.

Xóa một phiên xóa turns, exposures và evidence liên quan, rebuild CommunicationProgress trong transaction. Xóa toàn bộ tiến độ app bao gồm dữ liệu giao tiếp mới. Record không còn evidence trở về noEvidence. V1 không có cloud sync riêng; không tuyên bố xóa bản sao ở nhà cung cấp từ thao tác xóa local.

## 13. Acceptance matrix

| ID | Kịch bản | Kết quả bắt buộc |
|---|---|---|
| A01 | Chỉ bookmark, chưa học | Không được chọn như từ đã học |
| A02 | Hai từ không hợp một tình huống | Giảm/tách mục tiêu, không ép câu |
| A03 | Xem từ trước bài rồi nói đúng | Ghi exposure; không tăng independent count |
| A04 | Nhân vật nói từ trước learner | Ghi priming cho từ đó |
| A05 | Đọc câu mẫu đúng | Ghi luyện model-supported; không mastery/SRS mutation |
| A06 | Lượt thử lại giảm trợ giúp cùng phiên | Ghi cải thiện hỗ trợ; không coi là kiểm tra nhớ sạch |
| A07 | Dùng từ đồng nghĩa hợp lý | Objective đạt, target notObserved |
| A08 | STT sai hoặc thiếu confidence | Không suy ra learner sai; có recovery |
| A09 | Sửa transcript/chuyển text | Không nâng bằng chứng nói độc lập |
| A10 | Hai lần độc lập hợp lệ | Stage đúng quy tắc, mỗi phiên đóng góp tối đa một lần |
| A11 | Ngữ cảnh mới nhưng chưa đủ 24 giờ | Chưa nâng transferred |
| A12 | Đủ điều kiện chuyển giao | Nâng transferred và lịch riêng; SRS nguyên vẹn |
| A13 | Retry/callback đến muộn | Không trùng evidence/tiến bộ hoặc đổi phiên đã hủy |
| A14 | Crash giữa nhận câu và assessment | Resume pending đúng câu, không tạo user turn mới |
| A15 | Save/exposure save thất bại | Báo chưa lưu; không công nhận độc lập sai |
| A16 | Provider không đánh giá được | Cho luyện đúng capability, không nâng stage |
| A17 | Migration/xóa phiên | Giữ dữ liệu cũ; xóa và rebuild đúng phạm vi |
| A18 | Dynamic Type/VoiceOver/EN-VI | Nội dung, thao tác và trạng thái đều truy cập được |

## 14. Verification và pilot

Implementation plan phải ánh xạ A01–A18 tới domain tests, repository integration tests và UI/runtime scenarios. Dùng clock/provider/STT fixtures để kiểm tra timeout, cancellation và policy một cách xác định; dùng fixture store cũ để kiểm migration. Kiểm tra AI trên bộ câu độc lập gồm đúng nghĩa, sai nghĩa, phủ định, đồng nghĩa, chỉ nhắc tên từ, đọc mẫu, transcript lỗi và prompt injection.

Quality gate bắt buộc theo AGENTS.md: CraftUIKit `swift test --filter LocalizationTests`; các package `swift test`; full app test suite; swiftlint 0 lỗi/0 warning; Xcode build 0 lỗi/0 warning. Ghi đủ failure output. Simulator không thay kiểm mic, TTS, interruption và model local trên thiết bị thật.

Pilot đề xuất: 6 learner A2–B1, mỗi người ba phiên trên thiết bị thật, phiên sau ít nhất 24 giờ; đây là đánh giá khả dụng ban đầu, không chứng minh hiệu quả thống kê. Thu thập tỷ lệ hoàn thành nhiệm vụ, mức trợ giúp theo từ, lần tự dùng ở buổi sau, số lần sửa đánh giá AI và lỗi làm gián đoạn.

Đánh giá bằng người: mọi nhãn nâng lên transferred trong pilot phải có câu làm bằng chứng và được reviewer kiểm tra; mọi false promotion phải được phân tích trước mở rộng rollout. Ít nhất 5/6 learner tự tìm được trợ giúp và kết thúc phiên mà không được người điều phối chỉ cách thao tác. Không có mất dữ liệu hoặc cộng tiến bộ trùng trong các kịch bản kiểm thử. Nếu không đạt, sửa và chạy lại phần liên quan; không thay bằng tài khoản/bot giả.

## 15. Ranh giới lập kế hoạch và review

Đây là một thiết kế cho vertical slice luyện giao tiếp có hướng dẫn; implementation có thể chia thành các checkpoint dữ liệu/policy, session/runtime, UI/integration và verification/pilot. Tài liệu không phải implementation plan và không cấp phép bắt đầu viết product code.

Các lựa chọn mới được cụ thể hóa để người dùng review trong spec: tiêu chí từ đã học; exposure có hiệu lực suốt phiên; tối đa một bằng chứng độc lập mỗi từ/mode/phiên; mốc 24 giờ và lịch 1/3/7 ngày; ba nhóm template pilot; tạm không ghi XP trong luồng mới; phạm vi lưu/xóa transcript và pilot 6 người.

Sau khi người dùng review và đồng ý written spec, mới dùng writing-plans để lập kế hoạch implementation. Chỉ chuyển sang thực thi sau khi người dùng review kế hoạch và chọn cách thực hiện theo workflow Superpowers.
