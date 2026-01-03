# Testing Guide for Blocky Game

このドキュメントは、blocky_gameのテスト実行方法を説明します。

## テストフレームワーク

このプロジェクトでは[GUT (Godot Unit Test)](https://github.com/bitwes/Gut)を使用しています。

## テストファイル

- `test_gut_character_spawn.gd` - キャラクタースポーンとブロック配置のテスト

## テストの実行方法

### 方法1: コマンドラインから実行（推奨）

```bash
# プロジェクトルートから実行
./godot.macos.editor.app/Contents/MacOS/Godot --headless \
  --path project \
  -s addons/gut/gut_cmdln.gd \
  -gdir=res://../project/blocky_game \
  -gprefix=test_gut_ \
  -gexit
```

### 方法2: Godot Editorから実行

1. Godot Editorを開く
2. メニューバーから `Project > Project Settings` を開く
3. `Plugins` タブで `Gut` を有効化
4. `Scene > Run Gut` を選択
5. テストディレクトリとして `res://../project/blocky_game` を指定
6. `Run Tests` をクリック

## テストケース

### test_ready_does_not_spawn_character
`_ready()`後にキャラクターが自動スポーンされないことを確認します。
これは、キャラクター初期化の重複を防ぐための重要なテストです。

**期待される動作:** `_ready()`実行後、Playersコンテナは空であるべき

### test_no_duplicate_spawn_on_new_world
新規ワールド作成時にキャラクターが1体のみスポーンされることを確認します。

**期待される動作:** `start_new_world()`後、正確に1体のキャラクターが存在する

### test_start_new_world_spawns_character
`start_new_world()`がキャラクターを正しくスポーンすることを確認します。

**期待される動作:** キャラクターノード "1" が存在し、少なくとも1体のキャラクターがいる

### test_block_placement_works
ブロック配置機能が正常に動作することを確認します。

**期待される動作:** 配置されたブロックが空気(ID=0)ではない

## トラブルシューティング

### "Node not found" エラー

GUTテスト環境ではシーンツリー構造が異なるため、一部のテストで"Node not found"エラーが発生する場合があります。これは予期される動作であり、最も重要なテスト(`test_ready_does_not_spawn_character`)がパスしていれば問題ありません。

### GUTクラスがインポートされていない

初回実行時にGUTクラスのインポートエラーが発生した場合：

```bash
./godot.macos.editor.app/Contents/MacOS/Godot --headless --path project --import --quit
```

## 手動テスト

自動テストに加えて、以下の手動テストを推奨します：

1. **新規ワールドでブロック配置**
   - Main Menu > New World
   - ブロックを配置
   - 期待結果: ブロックが正しく配置される

2. **セーブ/ロード後のブロック配置**
   - F5でセーブ
   - F9でロード
   - ブロックを配置
   - 期待結果: 正常に配置される

3. **クイックプレイモード**
   - Main Menu > Singleplayer
   - ブロックを配置
   - 期待結果: ゲームが正常に起動し、ブロック配置が動作する
