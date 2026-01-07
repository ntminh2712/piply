## PRD — Dashboard vốn + Analytics (MVP)

### 1) Mục tiêu
- **User goal**: Nắm được P/L, drawdown, win rate và các chỉ số nền tảng để quản lý vốn.
- **Business goal**: Tạo “aha moment” (value) ngay sau sync thành công.

### 2) Phạm vi
- **In scope (MVP)**:
  - Dashboard tổng quan theo account (và “All accounts” nếu Pro sau).
  - Chỉ số: Balance/Equity (nếu có), P/L, win rate, max drawdown.
  - Basic charts: equity curve (nếu suy ra được), P/L theo ngày/tuần.
- **Out of scope**:
  - So sánh multi-account nâng cao (Post‑MVP/Pro).
  - AI insights.

### 3) User stories
- As a trader, I want to see my key performance metrics so that I know whether I’m improving.
- As a trader, I want to understand drawdown so that I can adjust risk.

### 4) UX / UI requirements
- Dashboard components:
  - KPI cards: Total P/L, Win rate, Max drawdown
  - Chart: P/L over time (daily)
  - Recent trades (last 10)
- Copy/education (tooltip):
  - “Max drawdown: the largest peak-to-trough decline…”
- Empty states:
  - If no trades: prompt sync

### 5) Data requirements
- Calculations should be deterministic and testable.
- Store “derived daily aggregates” later if performance requires (Post‑MVP); MVP can compute on read.

### 6) API / Contracts (high level)
- `GET /analytics/summary?account_id=&from=&to=`
  - returns: `pnl_total`, `win_rate`, `max_drawdown`, `trade_count`
- `GET /analytics/pnl-series?account_id=&from=&to=&bucket=daily`
- `GET /trades?limit=10&account_id=`

### 7) Edge cases
- Drawdown definition must be consistent:
  - If only trade P/L available: compute equity curve from cumulative P/L.
  - If balance/equity snapshots available: prefer snapshot curve.
- Handling open trades (if source provides):
  - MVP: ignore open trades in realized P/L; show separately if needed.

### 8) Analytics / Tracking
- Events:
  - `dashboard_viewed`, `analytics_range_changed`
- Metrics:
  - Time-to-first-dashboard-value (after first sync)

### 9) Acceptance criteria (DoD)
- Dashboard renders within acceptable time for a typical account (config target).
- Metrics match a golden dataset (known input trades → expected win rate/drawdown/P&L).


