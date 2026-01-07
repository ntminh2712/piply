## 4) Kiến trúc & Data plan (Không đập lại khi scale)

### Tech stack đề xuất
- **API**: Node.js
- **Worker**: Python
- **DB**: PostgreSQL
- **Queue**: Redis + BullMQ (hoặc tương đương)

### Bảng dữ liệu core (ban đầu)
- `users`
- `trading_accounts`
- `trades`
- `snapshots`
- `sync_logs`

### Sync strategy (ràng buộc quan trọng)
- Snapshot‑based
- Append‑only (tránh update/delete phá lịch sử)
- Không hứa realtime

**Đầu ra**
- Architecture diagram.
- DB schema + index chính + retention policy.

**DoD**
- Có thể mô tả rõ luồng dữ liệu từ “credentials” → “worker” → “trades chuẩn hóa” → “analytics API”.

### Sync contract (cần chốt)
- Sync được trigger bởi gì? (schedule + manual)
- Tránh duplicate thế nào? (idempotency keys)
- “Last successful sync” vs “last attempted sync”
- Backfill history như thế nào?


