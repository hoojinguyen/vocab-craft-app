# Phase 3A — Offline Learning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App iOS học được bộ từ/cụm từ thật theo từng nghĩa, offline, và giữ lịch sử sau khởi động lại.

**Architecture:** Service biên tập và xuất một SQLite release bất biến. iOS đọc cùng contract, lưu guest attempts và completion ở kho riêng. Chia công việc thành ba kế hoạch có đầu ra kiểm chứng được; auth, sync và công thức SRS mới thuộc Phase 3B.

**Tech Stack:** Python/FastAPI/SQLAlchemy/Alembic/Postgres; SQLite; Swift/SwiftUI, Apple speech hiện hữu.

**Spec:** [Shared Learning Contract](../specs/2026-09-05-shared-learning-contract-design.md), đã được owner duyệt bản chi tiết.

## Global Constraints

- “Người Việt học tiếng Anh; definition và example có EN/VI.”
- “Tiến độ theo sense; một lịch ôn chung, bằng chứng riêng cho recognition, recall, application.”
- “Nội dung nháp tách release; v1 cập nhật toàn bộ SQLite, progress nằm ở kho riêng.”
- “Phát âm dùng Apple trên iOS; không đóng gói audio hay xây audio service ở v1.”
- “Học guest không cần mạng/tài khoản; login để backup/sync. Guest và account profile tách biệt.”
- “Tạo migration mới, không sửa lịch sử 001_initial.py.”

## Thứ tự thực hiện

1. [A — Service authoring và publisher](2026-09-05-phase-3a-service.md): contract fixture, schema, revision/approval, immutable snapshot, SQLite, public manifest/bundle.
2. [B — iOS offline content và guest history](2026-09-05-phase-3a-ios.md): typed IDs, reader thật, journal local, tích hợp màn hình và cập nhật bundle.
3. [C — Nội dung thật và nghiệm thu](2026-09-05-phase-3a-content-acceptance.md): nghiên cứu nguồn, biên soạn/duyệt, xuất release và chạy nghiệm thu hai repo.

A phải xuất golden artifact trước B reader tests. C nghiên cứu/biên soạn có thể diễn ra sau A contract fixture; C publish phụ thuộc A, C nghiệm thu phụ thuộc B. Không triển khai tất cả trong một lần commit.

## Workspace và điều kiện môi trường

- Repo service: `/Users/hoojinguyen/Projects/vocab-craft-api`.
- Repo app: `/Users/hoojinguyen/Projects/vocab-craft-app`.
- Trước execution dùng using-git-worktrees để cô lập theo repo, ghi commit đầu vào và trạng thái working tree. Không xóa thay đổi có sẵn.
- Hiện lần kiểm tra trước: `.venv` service thiếu pytest, Docker daemon không chạy. Thiết lập dev deps và Postgres test trước chạy A2; không báo PASS bằng cách skip integration suite.
- Đọc AGENTS.md ở repo app, xcodebuildmcp và các skill Swift phù hợp trước implementation. Dùng xcodebuildmcp để chọn simulator và test; nếu dùng CLI, lấy UDID từ `xcodebuild -showdestinations`, không hardcode một máy chưa xác minh.
- iOS yêu cầu localization EN/VI, CraftUIKit/tokens hiện hữu, build/test/lint theo repo. Không mở rộng UI design system trong kế hoạch này.
- Tên file mới ở các kế hoạch là đường dẫn dự kiến. Các đường dẫn có sẵn đã đối chiếu source. Không sửa OpenWiki generated.

## Review checkpoints

- [ ] A1: JSON contract/SQL artifact schema khớp spec; một sense không mang lesson_id.
- [ ] A3–A4: review revision, snapshot và concurrent publishing chạy trên Postgres thật.
- [ ] A5: golden SQLite được hash, lưu provenance và sẵn sàng cho iOS.
- [ ] B2–B3: reader dùng service artifact; journal chứng minh crash/relaunch và dedupe.
- [ ] B4: màn hình học/tra cứu dùng SenseID, không ép UUID về Int64.
- [ ] C3: owner duyệt nội dung, airplane-mode evidence và lịch sử local; chỉ lúc này công bố milestone hoàn tất.

## Phạm vi chưa triển khai trong Phase 3A

Auth provider, nhập guest vào account production, push/pull, SRS schedule mới, automated application grading không nằm trong ba kế hoạch này. Phase 3A ghi đủ event envelope và capability counters, không hiển thị ngày ôn/mức mastery giả. Đánh giá unscored không được tính thành correct. Existing word SRS không được gắn vào sense mới qua ID tạm.

## Coverage map

| Spec | Task |
|---|---|
| §3 IDs/version/serialization | A1, B1 |
| §4 authoring/constraints/provenance | A2–A3, C1–C2 |
| §5 release, SHA, snapshot, API | A4–A6 |
| §5.2 atomic update | B5 |
| §6 repository và không sample fallback | B2, B4 |
| §7 guest/account partitions | B3 (guest + schema partition); full auth Phase 3B |
| §8 attempt/completion | B1, B3–B4; replay server/SRS Phase 3B |
| §9 migration | A2, A3, B3–B4 |
| §10 acceptance | A–B focused tests và C3 cross-repo gate |

Self-review: phân tách contract test fixture và nội dung production; không coi fixture QA là human approval của bộ từ thật. Code blocks trong task mô tả lõi thuật toán/test, các bảng/trường đầy đủ lấy từ spec đã duyệt và schema fixture A1; không dùng đoạn code minh họa như implementation hoàn chỉnh.
