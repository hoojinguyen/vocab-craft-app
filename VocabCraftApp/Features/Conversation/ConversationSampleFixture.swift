#if DEBUG
import Foundation

/// Fixed educational content, compiled only into development builds.
enum ConversationSampleFixture {
    static let data = Data(#"""
[
  {
    "id": "project-check-in",
    "situation": "Checking in on a team project",
    "situationVi": "Trao đổi tiến độ dự án nhóm",
    "vocabularyReferences": [
      "Prioritize",
      "Deadline",
      "Collaborate",
      "Milestone",
      "Reliable"
    ],
    "turns": [
      {
        "id": "project-1",
        "speaker": "speakerA",
        "english": "Could we prioritize the launch checklist today?",
        "vietnamese": "Hôm nay chúng ta có thể ưu tiên danh sách kiểm tra ra mắt không?"
      },
      {
        "id": "project-2",
        "speaker": "speakerB",
        "english": "Yes. The deadline is Friday, so we should collaborate closely.",
        "vietnamese": "Được. Hạn chót là thứ Sáu, nên chúng ta cần phối hợp chặt chẽ."
      },
      {
        "id": "project-3",
        "speaker": "speakerA",
        "english": "What is our next milestone?",
        "vietnamese": "Cột mốc tiếp theo của chúng ta là gì?"
      },
      {
        "id": "project-4",
        "speaker": "speakerB",
        "english": "A reliable test build by tomorrow afternoon.",
        "vietnamese": "Một bản dựng kiểm thử đáng tin cậy vào chiều mai."
      },
      {
        "id": "project-5",
        "speaker": "speakerA",
        "english": "Great, I will share the checklist after lunch.",
        "vietnamese": "Tuyệt, tôi sẽ chia sẻ danh sách kiểm tra sau bữa trưa."
      }
    ]
  },
  {
    "id": "project-planning",
    "situation": "Planning the next project milestone",
    "situationVi": "Lên kế hoạch cho cột mốc tiếp theo của dự án",
    "vocabularyReferences": [
      "Prioritize",
      "Deadline",
      "Collaborate",
      "Milestone",
      "Reliable"
    ],
    "turns": [
      {
        "id": "planning-1",
        "speaker": "speakerA",
        "english": "We need a reliable plan for the next milestone.",
        "vietnamese": "Chúng ta cần một kế hoạch đáng tin cậy cho cột mốc tiếp theo."
      },
      {
        "id": "planning-2",
        "speaker": "speakerB",
        "english": "Let us prioritize the tests before the deadline.",
        "vietnamese": "Hãy ưu tiên các bài kiểm thử trước hạn chót."
      },
      {
        "id": "planning-3",
        "speaker": "speakerA",
        "english": "Can we collaborate with the design team today?",
        "vietnamese": "Hôm nay chúng ta có thể phối hợp với nhóm thiết kế không?"
      },
      {
        "id": "planning-4",
        "speaker": "speakerB",
        "english": "Yes. I will ask them to review our plan this afternoon.",
        "vietnamese": "Được. Tôi sẽ nhờ họ xem lại kế hoạch của chúng ta chiều nay."
      },
      {
        "id": "planning-5",
        "speaker": "speakerA",
        "english": "Then we can finish the tests by Friday.",
        "vietnamese": "Vậy thì chúng ta có thể hoàn thành kiểm thử trước thứ Sáu."
      }
    ]
  }
]
"""#.utf8)
}
#endif
