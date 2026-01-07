## PRD — Trades + Trading Journal

### 1) Mục tiêu
- **User goal**: Xem toàn bộ lịch sử trade (tự động) và ghi chú/tag để review.
- **Business goal**: Tăng stickiness (người dùng quay lại review và cải thiện trading).

### 2) Phạm vi
- **In scope (MVP)**:
  - Trade list (filter theo thời gian/symbol).
  - Trade detail.
  - Notes + tags cho trade (manual).
- **Out of scope**:
  - Screenshot tự động (để Post‑MVP).
  - AI insights.

### 3) User stories
- As a trader, I want to see my trades grouped/filtered so that I can review performance.
- As a trader, I want to add notes/tags to a trade so that I remember context and mistakes.

### 4) UX / UI requirements
- **Trade list**:
  - Sort by close time desc (default)
  - Filters: date range, symbol, outcome (win/loss/breakeven)
  - Columns: symbol, side, open/close, P/L, duration
- **Trade detail**:
  - Entry/Exit, volume, SL/TP (if available), profit, duration
  - Notes (free text)
  - Tags (multi-select, free-form or predefined)
- **Empty states**:
  - “No trades yet — trigger sync” CTA

### 5) Data requirements
- `trades` (normalized):
  - `id`, `trading_account_id`
  - `source_trade_id`
  - `symbol`, `side` (buy/sell)
  - `open_time`, `close_time`
  - `open_price`, `close_price`
  - `volume`
  - `sl`, `tp` (nullable)
  - `profit`, `commission`, `swap` (nullable/optional depending source)
  - `currency` (optional)
  - `created_at`
- `trade_notes` / `trade_tags` (choose one structure):
  - Option A: `trade_notes` table + `trade_tags` join
  - Option B (MVP simple): fields on `trades`:
    - `note_text` (nullable)
    - `tags` (json array)
  - Recommendation: start with **Option B** for speed; migrate later if needed.

### 6) API / Contracts (high level)
- `GET /trades?account_id=&from=&to=&symbol=&outcome=`
- `GET /trades/:id`
- `PATCH /trades/:id` (note/tags only)
- Authorization: trades must belong to the user’s accounts.

### 7) Edge cases
- Timezone normalization (store UTC, display user locale).
- Partial data from source (missing SL/TP) → display “—”.

### 8) Analytics / Tracking
- Events:
  - `trade_list_viewed`, `trade_detail_viewed`
  - `trade_note_updated`, `trade_tags_updated`

### 9) Acceptance criteria (DoD)
- User can browse trades, open trade detail, add a note/tag, and see it persist after refresh.
- Filtering works and returns only trades belonging to the user.


