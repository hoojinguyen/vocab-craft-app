# Phase 3A-C — Real Content & Offline Acceptance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xuất bộ 50 entries thật, >=55 senses đã duyệt và chứng minh người dùng guest học offline qua app thật.

**Architecture:** Bộ từ được biên soạn vào contract A1, import/review qua service A3, publish A5, bundle vào iOS B6. Acceptance dùng release bytes/provenance cố định, không dùng golden fixture test thay nội dung thật.

**Tech Stack:** Contract JSON, CLI authoring/publisher, Postgres/SQLite, iOS Simulator/thiết bị, Markdown evidence.

**Spec:** [Shared Learning Contract](../specs/2026-09-05-shared-learning-contract-design.md), §4.1–4.2, §10; thực hiện sau contract A1, publish sau A5, app acceptance sau B5/B6.

## Global Constraints

- “Nguồn bộ từ sẽ nghiên cứu sau khi owner duyệt schema/contract.”
- “Nội dung mock được giữ ngoài published dataset.”
- “Sửa cách diễn đạt/translation giữ ID; đổi ý nghĩa hoặc split/merge tạo ID mới.”
- “Phát âm dùng Apple trên iOS; không đóng gói audio hay xây audio service ở v1.”
- 50 entries gồm phrasal verbs, >=5 entries đa nghĩa, >=55 senses; 1 deck/5 lessons, 10–15 memberships/bài và sense dùng lại.
- Mọi nội dung EN/VI/IPA/CEFR và quyền sử dụng cần review, AI không tự ký human approval.

## File map

Service create `docs/research/2026-09-05-first-dataset-sources.md`, `content/first-release/{draft.json,editorial-checklist.md,review-decisions.json}`, `tests/content/test_first_release.py`, `scripts/content/verify_first_release.py`, `docs/verification/phase-3a-offline.md`.

App production resources: `VocabCraftApp/Resources/Content/{vocab_content.sqlite,manifest.json,NOTICE.txt}`. Test evidence không chứa account credentials, thiết bị cá nhân hoặc audio người dùng.

### C1 — Chọn nguồn và biên soạn bản nháp có thể review

**Consumes:** A1 DatasetSnapshot/contract + catalog; owner đã đồng ý tiếng Anh cho người Việt, sense-level và phrasal verbs. **Produces:** draft.json đúng contract authoring, source evidence từng entry/sense/example, checklist cho owner; chưa review-decisions approve.

- [ ] Dùng research skill và primary sources để tìm 2–3 phương án. Kiểm nguồn danh sách headwords, nghĩa/ví dụ, IPA, căn cứ CEFR riêng; đọc trang nguồn/quyền sử dụng trực tiếp, không suy từ tên “open”. Lưu URL/ngày truy cập và giới hạn thực tế trong source report. Không chép ví dụ/định nghĩa hàng loạt khi chưa có căn cứ sử dụng.
- [ ] Đề xuất một bộ theo chủ đề sinh hoạt/đặt dịch vụ gồm book, check in, give up để kiểm đa nghĩa/phrasal verb. Chọn nguồn trên bằng chứng và trình bày đề xuất cùng checklist; bộ từ cụ thể có thể được owner sửa mà không đổi schema.
- [ ] Biên soạn original EN/VI examples và glossary ngắn nếu hướng nguồn cho phép; nguồn tham khảo và nguyên bản được ghi riêng. Cấp UUID v4 cố định trong file ngay lần đầu, sửa nội dung không regenerate ID. Ví dụ shape sense (IDs trong actual file là literals đã cấp, không chạy uuid4 mỗi import):

```json
{
  "id": "77df7ad7-b945-48cf-a802-4636050c95a4",
  "entry_id": "831fcad1-dd0b-40de-b51b-3392c31e4ab1",
  "part_of_speech": "verb",
  "definition_en": "To arrange to use a service at a particular time.",
  "definition_vi": "Đặt trước để sử dụng một dịch vụ vào thời điểm cụ thể.",
  "cefr_level": "A2",
  "usage_note_en": null,
  "usage_note_vi": null,
  "sort_order": 1,
  "revision": 1
}
```

Đoạn này là ví dụ biên soạn chưa duyệt; CEFR cần nguồn/reviewer xác nhận trước xuất bản, không coi A2 là kết luận nghiên cứu. Với mỗi sense tạo ít nhất một example EN/VI và IPA/source links theo A1.
- [ ] Chạy `python -m scripts.content.import_content --file content/first-release/draft.json --dry-run`; sửa mọi invalid graph/blank field/placeholder/source error. Dry-run không ghi DB hoặc approval. Lưu report count per entry/sense/lesson.
- [ ] Commit source report/draft/checklist ở trạng thái draft, `docs(content): prepare first reviewed-dataset candidate`.

### C2 — Duyệt và xuất bản bộ thật

**Consumes:** C1 draft, A3 authoring/review, A5 builder. **Produces:** reviewed release snapshot/manifest/bundle; review-decisions.json do quyết định owner cung cấp; test_first_release.py kiểm contract chất lượng/cấu trúc, không đánh giá thay con người.

- [ ] Trình owner bảng EN/VI, ví dụ, IPA, CEFR/nguồn và membership của toàn bộ senses; lấy quyết định approve/reject/edit theo nội dung/revision. Không tự ghi reviewer=owner khi chưa được duyệt. Các edits quay lại draft, owner review revision mới.
- [ ] Tạo test acceptance dữ liệu cụ thể:

```python
def test_first_release_has_required_learning_cases(first_release):
    from collections import Counter
    assert len(first_release.entries) == 50
    assert len(first_release.senses) >= 55
    senses_per_entry = Counter(s.entry_id for s in first_release.senses)
    assert sum(count >= 2 for count in senses_per_entry.values()) >= 5
    membership = Counter(m.sense_id for m in first_release.lesson_senses)
    assert max(membership.values()) >= 2
    assert len(first_release.lessons) == 5
    lesson_sizes = Counter(m.lesson_id for m in first_release.lesson_senses)
    assert all(10 <= lesson_sizes[l.id] <= 15 for l in first_release.lessons)
    assert any(e.entry_kind == "phrasal_verb" for e in first_release.entries)
```

`first_release` fixture đọc C1 file vào DatasetSnapshot, admission checks A1; không autoapprove. Trước dữ liệu đủ, test phải FAIL rõ criterion thiếu. Thêm assertions every sense example EN/VI, human approval cùng revision và không test-only provenance qua publish validator A3–A4.
- [ ] Import vào DB dev đã inventory, ghi REVIEW_JSON theo owner decisions bằng CLI A3, publish selected lessons bằng A5. Không dùng production account DB cho acceptance. Kiểm SHA byte file cuối; asset nguồn không thay sau manifest.
- [ ] Create `scripts/content/verify_first_release.py --bundle PATH --manifest PATH`: reuse verify_bundle, đọc counts/foreign keys/metadata, export verification JSON. Core:

```python
verify_bundle(bundle_path, manifest)
with sqlite3.connect(bundle_path) as db:
    sense_count = db.execute("SELECT COUNT(*) FROM senses").fetchone()[0]
    lesson_count = db.execute("SELECT COUNT(*) FROM lessons").fetchone()[0]
if sense_count < 55 or lesson_count != 5:
    raise ValueError("FIRST_RELEASE_COVERAGE_FAILED")
```

CLI argparse yêu cầu explicit paths; không lookup production env khi chỉ verify file. Commit reviewed draft/decisions và reports, không commit DB password hoặc artifact ngoài ownership. Dùng `content: approve and publish first offline dataset` cho content source; app bundle commit ở C3.

### C3 — Nghiệm thu service → bundle → màn hình → journal

**Consumes:** C2 bytes, B1–B6 iOS. **Produces:** bundled resource và evidence report có commit IDs, content/schema version, SHA, counts, test output và screenshot bằng simulator tool; final milestone status theo thực tế.

- [ ] Copy C2 artifact + manifest + attribution notice vào app production resources, kiểm resource membership trong app target. Ghi service commit/release SHA trong report. Không chỉnh SQLite bằng tay trong app repo.
- [ ] Chạy iOS contract reader trên đúng production resource, test LessonLearningViewModel và journal reopen. Dùng xcodebuildmcp build/install/run với simulator đã chọn; không coi việc test resource có file là main bundle đã đóng gói đúng.
- [ ] Ghi các trường hợp này vào checklist evidence, mỗi case có observed result:

| Case | Kết quả bắt buộc |
|---|---|
| Fresh launch offline guest | Mở được deck/lesson, không hỏi login, không sample data |
| book nhiều nghĩa | Chọn đúng nghĩa/ví dụ EN/VI; học nghĩa này không cập nhật nghĩa kia |
| phrasal verb | give up/check in hiển thị và bài tập văn bản xử lý cả cụm |
| Shared sense | Qua bài khác thấy cùng lịch sử sense; completion bài riêng |
| Kill/relaunch | Attempt IDs/counts và completion giữ nguyên |
| Corrupt update | Giữ bản nội dung hợp lệ; journal không đổi |
| Update khi đang học | Session giữ release cũ; buổi mới mở release mới |
| Không mạng | Không chặn flashcard/tra cứu/văn bản; Apple voice kiểm riêng |

- [ ] Simulator không luôn mô phỏng đúng airplane mode thực: ngắt route/network qua công cụ được hỗ trợ và kiểm request failures; nếu không có thiết bị để xác minh airplane mode, report rõ “simulator network unavailable”, không ghi đã kiểm máy thật. Kiểm thiết bị thực khi có sẵn, không tự thay network hệ thống của user toàn máy chỉ để giả lập.
- [ ] Chạy full backend pytest gồm Postgres tests, ruff; iOS app test suite/build/SwiftLint; CraftUIKit localization và full package tests theo repo. Không thêm test UI chụp ảnh mọi trạng thái; tập trung case chứng minh contract/offline/persistence. Khi fail, sửa root cause trong task sở hữu rồi chạy lại affected checks.
- [ ] Lưu `docs/verification/phase-3a-offline.md`: commands/tool runs, pass/fail, skipped và lý do, source/app commits, release versions, SHA và các hạn chế speech/SRS/auth. Kiểm local profile không lẫn legacy progress. Commit app resource + integration changes và service evidence riêng theo repo.

## Gate C

Chỉ công bố “bộ từ thật học được offline” khi owner đã duyệt nội dung và C3 có bằng chứng không còn sample fallback. Nếu chưa có human content review hoặc thiếu runtime environment, báo đúng phần đã hoàn thành, không thay dữ liệu thật bằng mock để đóng milestone. Human review là bước nội dung sản phẩm đã duyệt trong spec, khác review code/approval sandbox.
