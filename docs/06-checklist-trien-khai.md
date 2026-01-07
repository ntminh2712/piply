## 6) Checklist triển khai theo từng step (Chi tiết)

Checklist này dùng cho vận hành hằng ngày. Thêm **Owner** và **Due date** khi bạn “đưa vào vận hành”.

---

### Step A — Chốt sản phẩm (1 tuần)
- [ ] **Confirm target segment**: trader MT4/MT5 bán chuyên (1–5 account).
- [ ] **Viết positioning** (1 trang) + ví dụ + “không dành cho ai”.
- [ ] **Chốt MVP + non‑goals** (freeze list).
- [ ] **Chốt success metrics** cho MVP (vd: activation, WAU, conversion Pro).

**Đầu ra**
- Positioning doc, MVP spec, non‑goals, success metrics.

**Tiêu chí nghiệm thu**
- Mọi người có thể nói lại positioning 1 câu và đồng thuận boundary MVP.

---

### Step B — Chốt UX (1 tuần)
- [ ] Map user flow (happy path + 2 error paths).
- [ ] Wireframe 5 màn hình (low‑fi).
- [ ] Chốt copy cho các điểm nhạy:
  - [ ] “Read‑only access” là gì?
  - [ ] “Sync delay” nghĩa là gì?
  - [ ] Khi sync fail thì user thấy gì và làm gì?

**Đầu ra**
- UX flow + wireframes + copy notes.

**Tiêu chí nghiệm thu**
- Trader không kỹ thuật hiểu cách connect và kỳ vọng sản phẩm mà không cần giải thích thêm.

---

### Step C — Kiến trúc & Data (1–2 tuần)
- [ ] Chốt stack (API/worker/DB/queue).
- [ ] Thiết kế DB schema cho:
  - [ ] `users`
  - [ ] `trading_accounts` (credentials mã hóa, status)
  - [ ] `trades` (model chuẩn hóa)
  - [ ] `snapshots` (raw-ish data, có version)
  - [ ] `sync_logs` (debug được, search được)
- [ ] Chốt “sync contract”:
  - [ ] Sync được trigger bởi gì? (schedule + manual)
  - [ ] Tránh duplicate thế nào? (idempotency keys)
  - [ ] “Last successful sync” vs “last attempted sync”
  - [ ] Backfill history như thế nào?

**Đầu ra**
- Architecture diagram + schema + sync contract.

**Tiêu chí nghiệm thu**
- Môi trường mới chạy được “fake sync” end‑to‑end với dữ liệu stub và persist đúng.

---

### Step D — Backend Core (2–3 tuần)
- [ ] Auth system (signup/login, sessions/JWT, reset password nếu cần).
- [ ] Trading account CRUD:
  - [ ] Add / update / delete account
  - [ ] Status: `pending` / `synced` / `failed`
- [ ] Sync APIs:
  - [ ] Trigger sync
  - [ ] Get sync status + log gần nhất
- [ ] Analytics APIs (MVP):
  - [ ] P/L
  - [ ] Win rate
  - [ ] Drawdown
- [ ] Plan gating + rate limit theo plan (Free vs Pro).
- [ ] API documentation (OpenAPI hoặc tương đương).

**Đầu ra**
- API chạy thật + API docs.

**Tiêu chí nghiệm thu**
- Tạo user → thêm account → trigger sync → đọc analytics qua API cho 1 user test.

---

### Step E — Sync Worker (Python) (2–3 tuần)

**Worker flow**
Pick account → Login passview → Fetch snapshot → Fetch history → Normalize → Save → Logout

- [ ] Implement login + session handling.
- [ ] Fetch snapshot + trade history ổn định.
- [ ] Normalize sang schema `trades` (timezone, symbol naming, partial fills nếu có).
- [ ] Idempotent writes (retry không tạo duplicate).
- [ ] Reliability:
  - [ ] Timeout
  - [ ] Retry + backoff
  - [ ] Kill session/process treo (nếu applicable)
  - [ ] Logging có cấu trúc vào `sync_logs`
- [ ] Failure handling:
  - [ ] Mark account `failed` kèm lý do
  - [ ] Giữ raw snapshot để debug

**Đầu ra**
- Worker ổn định ở staging + error handling rõ ràng.

**Tiêu chí nghiệm thu**
- 100 job sync liên tiếp không mất data; lỗi có thể debug từ logs.

---

### Step F — Frontend App (2–3 tuần)
- [ ] Màn hình auth (login/signup).
- [ ] Account management:
  - [ ] Form connect account (broker, account ID, read‑only password, server)
  - [ ] Hiển thị sync status + error
- [ ] Dashboard:
  - [ ] Balance / Equity
  - [ ] Max drawdown
  - [ ] Win/Loss streak
- [ ] Trade history list (filter theo date/symbol).
- [ ] Trade detail:
  - [ ] Entry/exit, volume, SL/TP, profit, duration
  - [ ] Note + tag (setup/mistake)
  - [ ] Placeholder screenshot (optional)
- [ ] Analytics charts (đơn giản, nhanh).

**Đầu ra**
- Web app usable (mobile tùy team).

**Tiêu chí nghiệm thu**
- User connect được account, xem trạng thái sync, browse trades/analytics rõ ràng.

---

### Step G — Subscription & Billing (1 tuần)
- [ ] Chốt plan:
  - [ ] Free limits (vd: 1 account, sync chậm, giới hạn history)
  - [ ] Pro value (multi‑account, sync nhanh, export)
- [ ] Implement paywall + pricing page.
- [ ] Enforce plan gating server‑side.
- [ ] Downgrade handling an toàn (access changes, retention policy).

**Đầu ra**
- Billing flow + pricing page + enforced limits.

**Tiêu chí nghiệm thu**
- Upgrade/downgrade đổi giới hạn đúng; không truy cập trái phép feature Pro.

---

### Step H — Test, Launch, Iterate (ongoing)
- [ ] Test với 20–50 trader.
- [ ] Track: activation, retention, sync success rate, time‑to‑first‑dashboard.
- [ ] Ưu tiên fix sync issues (stability > feature).
- [ ] Improve UX copy + onboarding.

**Đầu ra**
- Pilot report + backlog ưu tiên.

**Tiêu chí nghiệm thu**
- Sync success rate đủ cao để dùng hằng ngày; retention tăng dần theo tuần.


