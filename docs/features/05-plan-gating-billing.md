## PRD — Plan Gating (Free vs Pro) + Billing (MVP)

### 1) Mục tiêu
- **User goal**: Hiểu rõ giới hạn Free và có đường nâng cấp rõ ràng khi cần.
- **Business goal**: Enable subscription sớm và đảm bảo giới hạn được enforce server-side.

### 2) Phạm vi
- **In scope (MVP)**:
  - Free plan + Pro plan (ít nhất 2 tier).
  - Gating theo:
    - Số lượng accounts
    - Tần suất sync (scheduler)
    - Manual sync triggers per day
    - Export (nếu để Pro)
  - Pricing page + paywall states.
- **Out of scope**:
  - Nhiều tier phức tạp
  - Coupon/referral

### 3) User stories
- As a Free user, I want to know why I hit a limit and how to upgrade.
- As a Pro user, I want higher limits and faster syncing.

### 4) UX / UI requirements
- Pricing page:
  - Plan comparison table
  - CTA “Upgrade”
- Paywall patterns:
  - When blocked: show message + link to pricing
  - In-product upsell: show current plan + remaining quota

### 5) Data requirements
- `subscriptions` (or fields on `users` for MVP):
  - `user_id`, `plan` (free/pro)
  - `status` (active/canceled/past_due)
  - `current_period_end`
- Usage counters (per day/week):
  - manual sync count
  - accounts count

### 6) API / Contracts (high level)
- Enforcement MUST be server-side:
  - Adding account: block if exceeds plan
  - Trigger sync: block/rate-limit if exceeds quota
  - Scheduler: compute interval per plan
- Possible endpoints:
  - `GET /me/subscription`
  - `POST /billing/checkout` (provider-specific)
  - `POST /billing/webhook` (provider-specific)

### 7) Edge cases
- Downgrade:
  - If user has > Free limit accounts: lock extra accounts (read-only view) or require removal.
- Billing provider outage:
  - Grace period vs immediate block (decide and log in decision log).

### 8) Analytics / Tracking
- Events:
  - `paywall_shown`, `pricing_viewed`, `checkout_started`, `checkout_completed`
- Metrics:
  - Conversion rate
  - Paywall-trigger rate by feature

### 9) Acceptance criteria (DoD)
- All limits are enforced server-side and cannot be bypassed by client.
- Upgrade/downgrade immediately changes allowed limits (or per policy) and is reflected in UI.


