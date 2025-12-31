# Building Godot + Voxel Module for macOS

このドキュメントでは、他のMacでこのプロジェクトをビルドして実行する方法を説明します。

## オプション1: ビルド済みバイナリを使用（推奨）

最も簡単な方法は、GitHubのReleasesページからビルド済みのGodotエディタをダウンロードすることです。

1. [Releases](../../releases)ページから最新の`Godot_Voxel.app.zip`をダウンロード
2. ZIPを解凍
3. プロジェクトを開く：
   ```bash
   open Godot_Voxel.app --args --editor project/project.godot
   ```

## オプション2: 自分でビルドする

### 必要な環境

- **macOS**: 10.15 (Catalina) 以降
- **Xcode Command Line Tools**: `xcode-select --install`
- **Homebrew**: https://brew.sh
- **空きディスク容量**: 約10GB（ソース + ビルド成果物）
- **ビルド時間**: 30〜60分（Macの性能に依存）

### クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/ScriptVoxel.git
cd ScriptVoxel

# ビルドスクリプトを実行
./build_godot.sh
```

スクリプトは以下を自動的に行います：
1. 必要な依存関係のチェック（SCons、Python等）
2. Godot 4.4のソースコードをダウンロード
3. godot_voxelモジュールをダウンロード
4. Godot + voxelモジュールをコンパイル
5. `Godot_Voxel.app`バンドルを作成

### ビルド後

ビルドが完了すると、`Godot_Voxel.app`が作成されます：

```bash
# エディタを起動
open Godot_Voxel.app

# プロジェクトを直接開く
./Godot_Voxel.app/Contents/MacOS/Godot --editor project/project.godot

# またはコマンドラインで
./Godot_Voxel.app/Contents/MacOS/Godot --editor project/project.godot
```

### トラブルシューティング

#### "xcrun: error: invalid active developer path"

Xcode Command Line Toolsが必要です：
```bash
xcode-select --install
```

#### "scons: command not found"

SCons（ビルドツール）をインストールしてください：
```bash
pip3 install scons
```

#### ビルドが途中で止まる/失敗する

1. ディスク容量を確認（10GB以上必要）
2. `build/`ディレクトリを削除して再実行：
   ```bash
   rm -rf build/
   ./build_godot.sh
   ```

#### Apple Silicon (M1/M2/M3) Macでの注意点

スクリプトは自動的にARM64向けにビルドします。Intel Macでも動作しますが、Rosetta 2経由で実行されます。

### カスタムビルドオプション

スクリプトを編集して以下をカスタマイズできます：

```bash
# Godotのバージョンを変更
GODOT_VERSION="4.4-stable"  # または "4.3-stable" など

# voxelモジュールのブランチを変更
# build_godot.sh内のVOXEL_REPO行の後に:
# cd "$VOXEL_MODULE_DIR"
# git checkout specific-branch
```

## オプション3: py4godot サポート付きビルド（上級者向け）

**注意**: 現在py4godotは動作していません。基本的なゲームプレイには不要です。

py4godotサポートを追加するには、以下のドキュメントを参照：
https://github.com/niklas2902/py4godot

## ビルド成果物の構成

```
ScriptVoxel/
├── build/                    # ビルド作業ディレクトリ（Git管理外）
│   └── godot/               # Godotソースコード
│       ├── modules/voxel/   # voxelモジュール
│       └── bin/             # コンパイル済みバイナリ
├── Godot_Voxel.app/         # 最終的なアプリバンドル（Git管理外）
└── project/                 # ゲームプロジェクトファイル（Git管理内）
```

## 開発者向け情報

### ビルド設定の詳細

スクリプトは以下のオプションでGodotをビルドします：
- `platform=macos` - macOS向けビルド
- `target=editor` - エディタビルド
- `arch=arm64` - Apple Silicon向け（Intel Macでも動作）
- `use_volk=yes` - Vulkanローダー使用
- `-j$(nproc)` - 並列コンパイル（全CPUコア使用）

### 手動ビルド

スクリプトを使わずに手動でビルドする場合：

```bash
# ソースを取得
git clone --branch 4.4-stable --depth 1 https://github.com/godotengine/godot.git
cd godot
git clone https://github.com/Zylann/godot_voxel.git modules/voxel

# ビルド
scons platform=macos target=editor arch=arm64 -j$(sysctl -n hw.ncpu)

# バイナリは bin/godot.macos.editor.arm64 に生成される
```

## 参考リンク

- [Godot公式ビルドドキュメント](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_macos.html)
- [godot_voxelモジュール](https://github.com/Zylann/godot_voxel)
- [SCons公式サイト](https://scons.org/)
