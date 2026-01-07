## 9) Risk Register (Gọn nhưng thật)

| Rủi ro | Ảnh hưởng | Khả năng | Giảm thiểu | Owner | Trạng thái |
|---|---|---|---|---|---|
| passview thay đổi/không ổn định làm hỏng sync | Cao | Trung bình | Contract tests, fallback, quy trình hotfix nhanh |  |  |
| Sync bị duplicate/missing trades | Cao | Trung bình | Idempotency keys, reconciliation checks, audit logs |  |  |
| User hiểu sai “read‑only” hoặc “sync delay” | Vừa | Cao | Onboarding copy mạnh + status UI + FAQs |  |  |
| Analytics sai (mất niềm tin) | Cao | Trung bình | Golden datasets + cross‑check calculations |  |  |


