## PRD — Kết nối Trading Account (Read‑only)

### 1) Mục tiêu
- **User goal**: Kết nối tài khoản MT4/MT5 để xem lịch sử giao dịch + dashboard vốn tự động.
- **Business goal**: Tăng activation (user connect thành công) và tạo nền tảng cho conversion (Free → Pro).

### 2) Phạm vi
- **In scope (MVP)**:
  - Thêm trading account bằng thông tin read‑only.
  - Lưu trạng thái account và hiển thị được trạng thái đó trên UI.
  - Cho phép “Trigger sync” thủ công sau khi tạo account.
- **Out of scope**:
  - Write access / đặt lệnh.
  - Validate bằng cách “test trade”.
  - Multi‑broker advanced discovery / auto-detect server.

### 3) User stories
- As a trader, I want to add my trading account using read‑only credentials so that I can see my trades automatically.
- As a trader, I want to see whether my account is synced or failed so that I know what to do next.
- As a trader, I want to delete a connected account so that I can remove outdated accounts.

### 4) UX / UI requirements
- **Screen**: “Add trading account”
  - Fields: Broker, Account ID, Server, Read‑only password
  - CTA: “Connect”
  - Secondary: “Learn what read‑only means”
- **States**:
  - `pending`: vừa tạo, chưa sync thành công
  - `synced`: sync thành công, có “Last successful sync”
  - `failed`: sync fail, hiển thị reason + CTA “Try again”
- **Copy bắt buộc**:
  - “Read‑only: app cannot place trades or change your account.”
  - “Sync is delayed; it may take a few minutes.”

### 5) Data requirements
- **Entity**: `trading_accounts`
  - `id`, `user_id`
  - `broker`, `server`, `account_id`
  - `credential_encrypted` (read‑only password)
  - `status`: `pending|synced|failed`
  - `last_attempted_sync_at`, `last_successful_sync_at`
  - `last_error_code`, `last_error_message` (sanitized)
  - `created_at`, `updated_at`
- **Validation**:
  - Account ID required, normalized (string vs number clarified)
  - Password required, min length (configurable)
  - Server required
- **Security / privacy**:
  - Encrypt credentials at rest (KMS/secret key managed)
  - Never log raw passwords
  - Only store what’s needed for syncing

### 6) API / Contracts (high level)
- `POST /trading-accounts`
- `GET /trading-accounts`
- `PATCH /trading-accounts/:id`
- `DELETE /trading-accounts/:id`
- `POST /trading-accounts/:id/sync` (manual trigger)
- **Plan gating**:
  - Free: 1 account max
  - Pro: up to N accounts
- **Idempotency**:
  - Optional: client sends idempotency key to avoid duplicate “add account” on retry.

### 7) Edge cases
- Wrong server/password → status `failed` + clear reason (generic, not leaking sensitive info).
- Duplicate account (same broker+server+account_id) → return existing or error with guidance.
- User deletes account while sync in progress → cancel job or mark as removed and ignore results.

### 8) Analytics / Tracking
- Events:
  - `trading_account_create_started`
  - `trading_account_created`
  - `trading_account_create_failed`
  - `trading_account_sync_triggered`
- Key metrics:
  - Connect success rate
  - Time-to-first-successful-sync

### 9) Acceptance criteria (DoD)
- Given a logged-in user on Free plan, when they connect 1 account successfully, then they can see status `pending/synced` and last sync timestamps.
- Given a user tries to add a 2nd account on Free plan, then the API blocks with a clear paywall response.
- Credentials are encrypted at rest and never appear in logs or responses.


