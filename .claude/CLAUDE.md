# CLAUDE.md — TABI Project

Claude Code がセッション開始時に読み込むコンテキストファイルです。

---

## プロジェクト概要

**TABI** — 世界中の人に日本を知ってもらう英語キュレーションメディア。  
静的 HTML サイト。PowerShell スクリプトで全ページを自動生成する構成。

- リポジトリ: `github.com/Raynart/tabi`
- 本番ドメイン予定: `tabi.guide`（未取得・未デプロイ）
- ホスティング: Netlify（`netlify.toml` 設定済み）
- 言語: **英語**（コンテンツ・UI ともに）

---

## World Picks との関係

| | World Picks | TABI |
|---|---|---|
| リポジトリ | `New-project` | `tabi` |
| ターゲット | 日本人 | 海外の人 |
| 言語 | 日本語 | 英語 |
| デザイン | テック・情報密度高め | 和風ミニマル |

**2つは完全に別プロジェクト。コードの混入に注意。**

---

## カテゴリ

- Travel Guide
- Culture & Tradition
- Food & Drink
- Things to Buy（アフィリエイト）
- Hidden Gems

---

## 重要ファイル

| ファイル | 役割 |
|---|---|
| `site.config.json` | サイト全体設定 |
| `articles.json` | 全記事データ |
| `styles.css` | デザインシステム |
| `script.js` | フロントエンド JS |
| `scripts/generate-pages.ps1` | HTML 生成スクリプト |
| `tabi-mockup.html` | デザインモック（開発参照用） |

---

## デザイン仕様

- **コンセプト**: 和風ミニマル（余白多め・漢字装飾・朱色アクセント）
- **カラー**: `--ink #111` / `--paper #f7f4ef` / `--accent #b5271f` / `--gold #c9a84c`
- **フォント**: Noto Serif JP（見出し）/ Noto Sans（本文）
- **参照**: `tabi-mockup.html`

---

## ブランチ運用

```
main            ← 常に公開可能な状態
claude/<作業名> ← Claude Code の作業ブランチ
codex/<作業名>  ← Codex の作業ブランチ
```

---

## スクリプト実行

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\generate-site.ps1"
```

## 制約・注意

- PowerShell スクリプト内の日本語は HTML エンティティで記述
- CSS 変数は `styles.css` 冒頭に集約
- 生成済み HTML を直接編集しない（再生成で上書きされる）
