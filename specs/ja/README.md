# ScriptVoxel 仕様書 (日本語)

このディレクトリには、ScriptVoxelプロジェクトの包括的な技術仕様書が含まれています。

## ドキュメント索引

### 01. [プロジェクト概要](./01_project_overview.md)
ScriptVoxelの高レベル紹介、以下を含む:
- プロジェクトの目的と目標
- 技術スタック
- 主要機能の概要
- デモシーンの説明
- システム要件
- アーキテクチャ哲学

**プロジェクトが初めての方は**ここから始めてください。

### 02. [アーキテクチャ仕様](./02_architecture.md)
詳細なシステムアーキテクチャドキュメント、以下をカバー:
- C++モジュール統合パターン
- コアボクセルシステムクラス
- ブロックゲームアーキテクチャ
- 地形生成アーキテクチャ
- マルチプレイヤーアーキテクチャ
- シミュレーションシステム
- データフロー図

**システムの連携を理解するために**必須の読み物。

### 03. [ブロックゲームシステム](./03_blocky_game.md)
メインデモ(blocky_game)の完全な仕様、以下を含む:
- ブロックレジストリシステム
- 地形生成の詳細
- プレイヤーコントローラーメカニクス
- インベントリシステム
- アイテムデータベース
- ランダムティックシミュレーション
- 水シミュレーション
- マルチプレイヤー実装

**プロジェクトで最も複雑なデモの**主要リファレンス。

### 04. [地形生成](./04_terrain_generation.md)
地形生成技術の詳細カバレッジ:
- シングルパスハイトマップ生成
- マルチパス生成システム
- SDF(符号付き距離場)生成
- ノイズ構成戦略
- 構造物配置アルゴリズム
- 洞窟生成
- パフォーマンス最適化

**プロシージャル生成への**技術的深掘り。

### 05. [開発ガイド](./05_development_guide.md)
ScriptVoxelで作業する開発者向けの実践ガイド:
- はじめにと前提条件
- ボクセルモジュール付きGodotのビルド
- 新しいデモの作成
- 一般的な開発タスク
- ベストプラクティス
- デバッグテクニック
- テスト戦略
- 避けるべきよくある落とし穴

**開発作業のための**実践ガイド。

## クイックナビゲーション

### トピック別

**プロジェクトの理解:**
- 開始: [01_project_overview.md](./01_project_overview.md)
- アーキテクチャ: [02_architecture.md](./02_architecture.md)

**特定のシステムでの作業:**
- ブロックとアイテム: [03_blocky_game.md](./03_blocky_game.md) § 1-4
- 地形: [04_terrain_generation.md](./04_terrain_generation.md)
- マルチプレイヤー: [03_blocky_game.md](./03_blocky_game.md) § 7
- シミュレーション: [03_blocky_game.md](./03_blocky_game.md) § 6

**開発:**
- セットアップ: [05_development_guide.md](./05_development_guide.md) § はじめに
- コンテンツ作成: [05_development_guide.md](./05_development_guide.md) § 新しいデモの作成
- ベストプラクティス: [05_development_guide.md](./05_development_guide.md) § ベストプラクティス

### 経験レベル別

**初心者** (ScriptVoxelが初めて):
1. [01_project_overview.md](./01_project_overview.md)
2. [05_development_guide.md](./05_development_guide.md) § はじめに
3. [02_architecture.md](./02_architecture.md) § アーキテクチャ原則

**中級者** (基本に精通):
1. [03_blocky_game.md](./03_blocky_game.md)
2. [04_terrain_generation.md](./04_terrain_generation.md)
3. [05_development_guide.md](./05_development_guide.md) § 一般的な開発タスク

**上級者** (詳細なカスタマイズ):
1. [02_architecture.md](./02_architecture.md)
2. [04_terrain_generation.md](./04_terrain_generation.md) § パフォーマンス最適化
3. [03_blocky_game.md](./03_blocky_game.md) § マルチプレイヤーシステム

### タスク別

**やりたいこと:**
- **コードベースを理解する** → [02_architecture.md](./02_architecture.md)
- **新しいブロックタイプを追加** → [05_development_guide.md](./05_development_guide.md) § 新しいブロックタイプの追加
- **地形生成を変更** → [04_terrain_generation.md](./04_terrain_generation.md)
- **マルチプレイヤーを実装** → [03_blocky_game.md](./03_blocky_game.md) § 7, [05_development_guide.md](./05_development_guide.md) § マルチプレイヤーの実装
- **新しいデモを作成** → [05_development_guide.md](./05_development_guide.md) § 新しいデモの作成
- **問題をデバッグ** → [05_development_guide.md](./05_development_guide.md) § デバッグテクニック
- **パフォーマンスを最適化** → [04_terrain_generation.md](./04_terrain_generation.md) § パフォーマンス最適化

## 追加リソース

### 関連ファイル
- **CLAUDE.md** (プロジェクトルート) - AIアシスタント向けの指示
- **project/project.godot** - Godotプロジェクト構成
- **project/common/** - 共有ユーティリティスクリプト

### 外部リソース
- [Godot Voxelモジュール](https://github.com/Zylann/godot_voxel)
- [Godotエンジンドキュメント](https://docs.godotengine.org/)
- [Godot Jolt Physics](https://github.com/godot-jolt/godot-jolt)

## ドキュメント規則

### コードブロック
```gdscript
# GDScript例はこのように表示
func example():
    pass
```

```bash
# シェルコマンドはこのように表示
godot --editor project/project.godot
```

### ファイルパス
- 絶対パス: `/Users/user/ScriptVoxel/project/main.tscn`
- プロジェクトルートからの相対パス: `project/blocky_game/main.tscn`
- Godotリソースパス: `res://blocky_game/main.tscn`

### 参照
- 内部リンク: [開発ガイド](./05_development_guide.md)
- ファイルロケーション: `project/blocky_game/blocks/blocks.gd`
- コード参照: `BlockyGame.blocks:712`

## ドキュメントの更新

プロジェクトに変更を加える場合:
1. 関連する仕様ファイルを更新
2. コード例を実際のコードと同期
3. ファイルが移動した場合はファイルパス参照を更新
4. すべてのドキュメント間で一貫性を維持

## 言語バージョン

- **英語:** `specs/en/`
- **日本語:** `specs/ja/` (このディレクトリ)

両方のバージョンには同じ情報が異なる言語で含まれています。
