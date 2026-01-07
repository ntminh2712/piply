## PRD — Sync (Worker + Contract + Reliability)

### 1) Mục tiêu
- **User goal**: Data giao dịch và vốn được cập nhật tự động, ổn định.
- **Business goal**: Giảm churn do sync lỗi; tăng trust (số liệu đúng + minh bạch trạng thái).

### 2) Phạm vi
- **In scope (MVP)**:
  - Sync theo lịch (scheduler) + manual trigger.
  - Chuẩn hóa dữ liệu trade vào `trades`.
  - Lưu `snapshots` và `sync_logs` để audit/debug.
  - Idempotency: chạy lại không tạo duplicate trades.
- **Out of scope**:
  - Realtime streaming.
  - Near-zero latency SLAs.

### 3) User stories
- As a trader, I want my data to refresh periodically so that my dashboard stays updated.
- As a trader, I want to know sync is running / failed and why, so that I can fix it.
- As an operator, I want logs and retries so that I can debug failures quickly.

### 4) UX / UI requirements
- “Sync status” component:
  - Shows `last_attempted_sync_at`, `last_successful_sync_at`
  - Shows `status`: syncing/pending/synced/failed
  - On `failed`: show safe error message + CTA “Try again”

### 5) Data requirements
- `snapshots`:
  - `id`, `trading_account_id`
  - `source` (passview)
  - `payload` (raw-ish json, versioned)
  - `created_at`
- `sync_logs`:
  - `id`, `trading_account_id`, `job_id`
  - `started_at`, `finished_at`
  - `status`: success|failed|running
  - `error_code`, `error_message` (sanitized)
  - `stats`: counts (fetched trades, inserted, updated(should be 0 if append-only), duplicates)

### 6) API / Contracts (high level)
- Trigger:
  - `POST /trading-accounts/:id/sync`
- Status:
  - `GET /trading-accounts/:id/sync-status` (or include in `GET /trading-accounts`)
- Worker job payload (queue message):
  - `trading_account_id`
  - `requested_by` (system/manual)
  - `requested_at`
- **Idempotency approach** (choose one):
  - Unique constraint on `(trading_account_id, source_trade_id)` OR
  - Deterministic hash key on normalized fields
- **Rate limiting**:
  - Manual trigger limited per plan
  - Scheduler frequency per plan (Free slower)

### 7) Edge cases
- Network timeouts → retry with exponential backoff, cap attempts.
- Partial failure after snapshot fetch → still log and preserve snapshot for debugging.
- Credential revoked → mark account `failed`, stop auto-scheduling until user updates credentials.

### 8) Analytics / Tracking
- Events:
  - `sync_job_started`, `sync_job_succeeded`, `sync_job_failed`
- Metrics:
  - Sync success rate per day
  - Mean time to recover (MTTR)
  - Avg sync duration

### 9) Acceptance criteria (DoD)
- Re-running the same sync job does not create duplicate trades.
- Failures are visible to user (safe message) and to operator (detailed logs).
- Scheduler respects plan-based frequency limits.


