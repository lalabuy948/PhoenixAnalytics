# Changelog

All notable changes to this project will be documented in this file.

## [0.5.0] - 08-11-2026

### 🚨 BREAKING CHANGES

- **Modern browsers only**: The dashboard is now built with Tailwind CSS v4 and daisyUI 5 and requires Safari 16.4+, Chrome 111+ or Firefox 128+
- **Bots excluded from visitor metrics**: Crawlers, scripts, monitors and requests without a user agent are tagged as `bot` and no longer count towards visitors, page views, visits or bounce rate. Server metrics (requests, errors, response times) still include them. Numbers will drop compared to 0.4.x
- **Visits count sessions**: The visits chart counts distinct sessions instead of requests

### ⬆️ Upgrading

- Add a migration that calls `PhoenixAnalytics.Migration.add_indexes()` again to create the new `(remote_ip, inserted_at)` index used by new vs returning visitors. Existing indexes are skipped

### ✨ New Features

- **Tailwind CSS v4 + daisyUI 5**: CSS-first config, matching the defaults of new Phoenix 1.8 apps
- **Latest Phoenix**: Tested against Phoenix 1.8.15 and LiveView 1.2 (LiveView 1.1 is still supported)
- **Error rate**: Share of 5xx responses, with a daily trend
- **p95 / p99 response time**: Response time percentiles, with daily trends
- **Entry and exit pages**: First and last page of each visit
- **New vs returning visitors**: Visitors seen before the selected range count as returning
- **Pages per visit**: Visits grouped by how many pages they viewed
- **Referrer → landing page**: Which page visitors from each external site land on
- **Time to second page**: How long visitors take to open a second page
- **Traffic heatmap**: Page views by weekday and hour
- **Bot detection**: Requests are classified as `bot` from the user agent

### 🐛 Bug Fixes

- **Custom root layout**: Charts and stats no longer render blank when the dashboard runs inside a host app's root layout (`:root_layout` + `analytics_head/1`). The dashboard now registers its React hooks on the host's LiveSocket instead of starting a second one
- **Page views**: Only HTML responses increase the session page counter, so assets and API calls no longer inflate views per visit and hide bounces
- **Top referers**: Grouped by host, own domain and subdomains excluded
- **Slowest endpoints**: Grouped by method and path with ids collapsed (`/users/:id`), one-off slow requests ignored
- **Visitor hashing**: Fewer IP hash collisions
- **Query errors**: Failed dashboard queries are no longer cached as empty results
- **Batcher**: A database outage no longer crashes the request batcher
- **Elixir 1.20**: No compile warnings (#50)

### 🔧 Improvements

- **Less CSS leaking into host apps**: Theme variables are no longer written to the host page's `:root`, and daisyUI is scoped to the dashboard and limited to the components it uses
- **Smaller assets**: Bundled assets are minified (JS 2.9MB → 935KB, CSS 52KB → 44KB)
- **Assets recompile**: Layouts recompile when the bundled assets change
- **Cleanup**: Removed unused core components and the deprecated `Phoenix.LiveView.Helpers` import

## [0.4.0] - 14-08-2025

### 🚨 BREAKING CHANGES

- **Removed Duck Feature**: The 🦆 duck emoji branding has been completely removed from the UI and codebase
- **Migration Path**: Users who prefer the duck-themed version should use the maintained fork at [https://github.com/lalabuy948/PhoenixAnalyticsDuck](https://github.com/lalabuy948/PhoenixAnalyticsDuck)

### ✨ New Features

- **Pure plug and play**: Sqlite, Postgres and MySQL support out of the box using your repo!
- **Color Theme System**: Added 12 color themes (Zinc, Slate, Stone, Gray, Neutral, Red, Rose, Orange, Green, Blue, Yellow, Violet)

### 🔧 Improvements

- **Database Indexes**: Added optional `add_indexes()` function for optimized query performance
- **Multi-Database Support**: Unified index creation for PostgreSQL, MySQL, and SQLite
- **CSS Architecture**: Comprehensive CSS custom properties system for theme management
- **Dark Mode Compatibility**: All color themes work seamlessly in both light and dark modes

---

> [!NOTE]
> For detailed release notes, please check the [GitHub releases page](https://github.com/lalabuy948/PhoenixAnalytics/releases).
