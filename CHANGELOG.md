# Changelog

All notable changes to this project will be documented in this file.

## [0.5.0] - 05-10-2026

### 🚨 BREAKING CHANGES

- **Modern browsers only**: The dashboard is now built with Tailwind CSS v4 and daisyUI 5 and requires Safari 16.4+, Chrome 111+ or Firefox 128+

### ✨ New Features

- **Tailwind CSS v4 + daisyUI 5**: CSS-first config, matching the defaults of new Phoenix 1.8 apps
- **Latest Phoenix**: Tested against Phoenix 1.8.15 and LiveView 1.2 (LiveView 1.1 is still supported)

### 🐛 Bug Fixes

- **Custom root layout**: Charts and stats no longer render blank when the dashboard runs inside a host app's root layout (`:root_layout` + `analytics_head/1`). The dashboard now registers its React hooks on the host's LiveSocket instead of starting a second one

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
