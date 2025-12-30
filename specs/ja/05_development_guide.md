# 開発ガイド

## はじめに

### 前提条件

1. **コンパイルされたgodot_voxelモジュールを含むGodot Engine 4.4**
   - 標準のGodotビルドは使用不可
   - ボクセルモジュールを含めてソースからコンパイル必要

2. **開発ツール**
   - バージョン管理用Git
   - GDScriptサポート付きテキストエディタ(VS Codeなど)
   - Godotのシーンシステムの基本理解

### ボクセルモジュール付きGodotのビルド

```bash
# Godotをクローン
git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.4-stable

# ボクセルモジュールをクローン
cd modules
git clone https://github.com/Zylann/godot_voxel.git voxel

# コンパイル(Linux例)
cd ..
scons platform=linuxbsd target=editor

# 結果: ボクセルモジュール付きカスタムGodotビルド
```

### プロジェクトを開く

```bash
# カスタムGodotビルドを使用
/path/to/custom/godot --editor project/project.godot
```

## プロジェクト構造

### ディレクトリレイアウト

```
ScriptVoxel/
├── project/                    # Godotプロジェクトルート
│   ├── project.godot           # プロジェクト構成
│   ├── blocky_game/            # メインデモ
│   ├── blocky_terrain/         # シンプルなブロックデモ
│   ├── smooth_terrain/         # スムーズ地形デモ
│   ├── grid_pathfinding/       # パスファインディングデモ
│   ├── blocky_fluid/           # 流体シミュレーション
│   ├── multipass_generator/    # マルチパス生成
│   ├── common/                 # 共有ユーティリティ
│   │   ├── util.gd
│   │   ├── mouse_look.gd
│   │   └── spectator_avatar.gd
│   └── addons/
│       └── zylann.debug_draw/  # デバッグ可視化
├── specs/                      # ドキュメント(このフォルダ)
└── CLAUDE.md                   # AIアシスタント向け指示
```

### ファイル組織

**シーンファイル (.tscn):**
- デモのメインエントリーポイント
- ノード階層を構成
- スクリプトとリソースを参照

**スクリプトファイル (.gd):**
- ゲームロジック実装
- C++モジュールクラスを拡張
- ユーザーインタラクションを処理

**リソースファイル (.tres):**
- VoxelBlockyLibrary定義
- マテリアル構成
- ジェネレータープリセット

## 新しいデモの作成

### ステップ1: デモディレクトリ作成

```bash
cd project
mkdir my_demo
cd my_demo
```

### ステップ2: メインシーン作成

**ファイル: `project/my_demo/main.tscn`**

```gdscript
# Godotエディタで作成:
# - Node3D (ルート)
#   ├── VoxelTerrain
#   ├── DirectionalLight3D
#   ├── Camera3D
#   └── Environment
```

### ステップ3: メインスクリプトをアタッチ

**ファイル: `project/my_demo/main.gd`**

```gdscript
extends Node3D

@onready var terrain: VoxelTerrain = $VoxelTerrain

func _ready():
    # 地形を構成
    terrain.generator = MyGenerator.new()
    terrain.voxel_library = _create_library()

func _create_library() -> VoxelBlockyLibrary:
    var library = VoxelBlockyLibrary.new()
    # ブロック定義を追加
    return library
```

### ステップ4: ジェネレーター作成

**ファイル: `project/my_demo/generator.gd`**

```gdscript
extends VoxelGeneratorScript

var _noise: FastNoiseLite

func _init():
    _noise = FastNoiseLite.new()
    _noise.frequency = 0.01

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)
                var height = _get_height_at(world_pos.x, world_pos.z)

                var block_id = 1 if world_pos.y < height else 0
                out_buffer.set_voxel(Vector3i(x, y, z), block_id, 0)

func _get_height_at(x: float, z: float) -> float:
    return 32.0 + _noise.get_noise_2d(x, z) * 10.0
```

## 一般的な開発タスク

### 新しいブロックタイプの追加

#### 1. ブロックレジストリで定義

**ファイル: `project/blocky_game/blocks/blocks.gd`**

```gdscript
func _init_blocks():
    # 既存のブロック...

    _register_block({
        "name": "my_new_block",
        "voxel_id": 20,
        "rotation_type": ROTATION_NONE,
    })
```

#### 2. VoxelBlockyLibraryに追加

**Godotエディタで:**
1. `voxel_library.tres`を開く
2. 新しいVoxel定義を追加
3. IDを20に設定
4. モデルジオメトリを構成
5. 衝突形状を設定

#### 3. テクスチャを追加(必要に応じて)

1. マテリアルのテクスチャ配列にテクスチャを追加
2. ボクセル定義でテクスチャインデックスを参照

### ボクセル編集の実装

```gdscript
extends Node3D

@onready var terrain: VoxelTerrain = $VoxelTerrain
var _voxel_tool: VoxelTool

func _ready():
    _voxel_tool = terrain.get_voxel_tool()

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        var camera = get_viewport().get_camera_3d()
        var from = camera.global_position
        var to = from + camera.global_transform.basis.z * -10.0

        var hit = _voxel_tool.raycast(from, to)
        if hit:
            if event.button_index == MOUSE_BUTTON_LEFT:
                _remove_block(hit.position)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                _place_block(hit.previous_position, 1)

func _remove_block(pos: Vector3i):
    _voxel_tool.set_voxel(pos, 0)  # 0 = AIR

func _place_block(pos: Vector3i, block_id: int):
    _voxel_tool.set_voxel(pos, block_id)
```

### SDFスカルプティングの追加(スムーズ地形)

```gdscript
extends Node3D

@onready var terrain: VoxelLodTerrain = $VoxelLodTerrain
var _voxel_tool: VoxelToolLodTerrain

func _ready():
    _voxel_tool = terrain.get_voxel_tool()
    _voxel_tool.set_channel(VoxelBuffer.CHANNEL_SDF)

func _sculpt_terrain(center: Vector3, radius: float, add_mode: bool):
    _voxel_tool.mode = VoxelTool.MODE_ADD if add_mode else VoxelTool.MODE_REMOVE
    _voxel_tool.do_sphere(center, radius)
```

### マルチプレイヤーの実装

#### サーバーセットアップ

```gdscript
func start_server(port: int):
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(port, 32)
    multiplayer.multiplayer_peer = peer

    # 地形同期を有効化
    var sync = VoxelTerrainMultiplayerSynchronizer.new()
    sync.terrain = $VoxelTerrain
    add_child(sync)

    multiplayer.peer_connected.connect(_on_player_connected)

func _on_player_connected(peer_id: int):
    # VoxelViewer付きリモートプレイヤーアバターをスポーン
    var avatar = preload("res://player/avatar.tscn").instantiate()
    avatar.name = str(peer_id)

    var viewer = VoxelViewer.new()
    avatar.add_child(viewer)

    $Players.add_child(avatar)
```

#### クライアントセットアップ

```gdscript
func join_server(address: String, port: int):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(address, port)
    multiplayer.multiplayer_peer = peer

    # 地形はサーバーから自動同期
```

#### RPCパターン

```gdscript
# クライアントがこれを呼び出してブロック編集をリクエスト
func place_block_request(pos: Vector3i, block_id: int):
    rpc_id(1, "server_place_block", pos, block_id)

# サーバーが受信して実行
@rpc("any_peer", "call_remote", "reliable")
func server_place_block(pos: Vector3i, block_id: int):
    if not multiplayer.is_server():
        return

    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel(pos, block_id)
    # 全クライアントに自動同期
```

## ベストプラクティス

### パフォーマンス最適化

#### 1. シミュレーションスコープを制限

```gdscript
# 良い: フレームあたり限定ボクセルを処理
const UPDATES_PER_FRAME = 64

func _process(_delta):
    for i in range(UPDATES_PER_FRAME):
        _process_one_update()

# 悪い: すべてのボクセルを処理
func _process(_delta):
    for all_voxels:  # 数百万になる可能性!
        _process_one_update()
```

#### 2. VoxelToolを効率的に使用

```gdscript
# 良い: VoxelToolインスタンスを再利用
var _voxel_tool: VoxelTool

func _ready():
    _voxel_tool = terrain.get_voxel_tool()

func edit_voxel(pos: Vector3i, id: int):
    _voxel_tool.set_voxel(pos, id)

# 悪い: 毎回新しいVoxelToolを作成
func edit_voxel(pos: Vector3i, id: int):
    var tool = terrain.get_voxel_tool()  # 高コスト!
    tool.set_voxel(pos, id)
```

#### 3. ボクセル編集をバッチ処理

```gdscript
# 良い: 複数の編集をバッチ
func place_structure(positions: Array):
    for pos in positions:
        _voxel_tool.set_voxel(pos, block_id)
    # すべての編集後に一度メッシュ更新

# 悪い: 各編集後に強制更新
func place_structure(positions: Array):
    for pos in positions:
        _voxel_tool.set_voxel(pos, block_id)
        terrain.force_update()  # これはしないで!
```

#### 4. LOD構成

```gdscript
# VoxelLodTerrain設定
terrain.view_distance = 512  # 必要に応じて調整
terrain.lod_count = 4        # より多いLOD = より良いパフォーマンス
terrain.lod_distance = 32.0  # LODレベル間の距離
```

### コード組織

#### 1. グローバルデータのシングルトンパターン

```gdscript
# blocks.gd - グローバルブロックレジストリ
extends Node

var _blocks: Dictionary = {}

func get_block(id: int) -> Dictionary:
    return _blocks.get(id, {})
```

**オートロードに追加** プロジェクト設定で:
- 名前: `Blocks`
- パス: `res://blocks/blocks.gd`

#### 2. 関心事の分離

```gdscript
# 良い: システムを分離
# character_controller.gd - 移動のみ
# avatar_interaction.gd - ボクセル編集のみ
# inventory.gd - アイテム管理のみ

# 悪い: 神オブジェクト
# player.gd - すべてを行う
```

#### 3. コンポジションを使用

```gdscript
# 良い: コンポーネント
CharacterAvatar
├── CharacterController (移動)
├── AvatarInteraction (ボクセル編集)
└── Inventory (アイテム)

# 悪い: 継承チェーン
Player extends CharacterController extends VoxelEditor extends InventoryManager
```

### デバッグテクニック

#### 1. デバッグドローの使用

```gdscript
# HUDテキスト
DDD.set_text("Player Pos", global_position)
DDD.set_text("FPS", Engine.get_frames_per_second())

# 3D可視化
DDD.draw_box(position, size, Color.GREEN)
DDD.draw_ray(origin, direction, 10.0, Color.RED)
```

#### 2. ボクセルデータ検査

```gdscript
func debug_voxel_at(pos: Vector3i):
    var voxel_id = _voxel_tool.get_voxel(pos)
    var block_id = Blocks.get_block_from_voxel_id(voxel_id)
    print("Voxel ID: %d, Block ID: %d" % [voxel_id, block_id])
```

#### 3. パフォーマンスプロファイリング

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var start_time = Time.get_ticks_usec()

    # 生成ロジック...

    var elapsed = (Time.get_ticks_usec() - start_time) / 1000.0
    if elapsed > 5.0:  # > 5msで警告
        push_warning("Slow generation at %v: %.2f ms" % [origin, elapsed])
```

## テスト

### 手動テストチェックリスト

#### 地形生成
- [ ] 同じシードで一貫して地形が生成される
- [ ] チャンク間に目に見える継ぎ目がない
- [ ] 構造物がチャンク境界で切断されない
- [ ] パフォーマンスが許容範囲(< 5ms/チャンク)

#### ボクセル編集
- [ ] ブロック配置が正しく動作
- [ ] ブロック削除が正しく動作
- [ ] 回転バリアントが正しく配置される
- [ ] 移動して戻った後も編集が持続

#### マルチプレイヤー(該当する場合)
- [ ] サーバーが正常に起動
- [ ] クライアントが正常に接続
- [ ] 地形がクライアントに同期
- [ ] ブロック編集がすべてのクライアントに同期
- [ ] 編集の重複がない

### 自動テスト

```gdscript
# test_generator.gd
extends GutTest

var generator: VoxelGeneratorScript

func before_each():
    generator = MyGenerator.new()

func test_deterministic_generation():
    var buffer1 = VoxelBuffer.new()
    buffer1.create(16, 16, 16)
    generator._generate_block(buffer1, Vector3i.ZERO, 0)

    var buffer2 = VoxelBuffer.new()
    buffer2.create(16, 16, 16)
    generator._generate_block(buffer2, Vector3i.ZERO, 0)

    # 同一の結果を生成する必要
    assert_true(_buffers_equal(buffer1, buffer2))

func _buffers_equal(a: VoxelBuffer, b: VoxelBuffer) -> bool:
    for y in range(a.get_size().y):
        for z in range(a.get_size().z):
            for x in range(a.get_size().x):
                if a.get_voxel(Vector3i(x, y, z), 0) != b.get_voxel(Vector3i(x, y, z), 0):
                    return false
    return true
```

## よくある落とし穴

### 1. LODパラメータを忘れる

```gdscript
# 間違い: LODを無視
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for x in range(16):  # 常に16!
        # ...

# 正しい: LODを尊重
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod
    for x in range(out_buffer.get_size().x):
        var world_x = origin.x + x * stride
        # ...
```

### 2. ブロックIDとボクセルIDの混同

```gdscript
# 間違い: ブロックIDを直接使用
_voxel_tool.set_voxel(pos, GRASS_BLOCK_ID)

# 正しい: ブロックレジストリからボクセルIDを取得
var voxel_id = Blocks.get_voxel_id(GRASS_BLOCK_ID, rotation)
_voxel_tool.set_voxel(pos, voxel_id)
```

### 3. Blocksを最初に初期化しない

```gdscript
# 間違い: Blocksが初期化されていない可能性
func _ready():
    var grass_id = Blocks.get_block_by_name("grass")  # 失敗する可能性!

# 正しい: blocksが最初の子であることを確認
# シーンツリー順序で構成:
# 1. Blocks (レジストリ)
# 2. その他すべて
```

### 4. クライアントで地形を変更

```gdscript
# 間違い: クライアントが地形を直接変更
func place_block_client(pos: Vector3i, id: int):
    _voxel_tool.set_voxel(pos, id)  # 同期がずれる!

# 正しい: クライアントはRPC経由でリクエスト
func place_block_client(pos: Vector3i, id: int):
    rpc_id(1, "server_place_block", pos, id)
```

## リソースと参照

### 公式ドキュメント
- Godot Voxelモジュール: https://github.com/Zylann/godot_voxel
- Godotエンジンドキュメント: https://docs.godotengine.org/en/stable/

### 有用なツール
- Godot Jolt Physics: https://github.com/godot-jolt/godot-jolt
- GUT (Godot Unit Testing): https://github.com/bitwes/Gut

### 学習リソース
- ScriptVoxelデモ(このプロジェクト)
- Godot Voxelデモシーン
- コミュニティフォーラムディスカッション

## コントリビュート

### コードスタイル

- 変数と関数に`snake_case`を使用
- クラスとノードに`PascalCase`を使用
- プライベートメンバーに`_`を接頭辞
- コメントでパブリックAPIをドキュメント化

### コミットガイドライン

```bash
# 良いコミットメッセージ
git commit -m "Add new tree generation algorithm"
git commit -m "Fix chunk boundary structure placement"
git commit -m "Optimize water simulation performance"

# 悪いコミットメッセージ
git commit -m "Update"
git commit -m "WIP"
git commit -m "asdfasdf"
```

### プルリクエストプロセス

1. 変更を徹底的にテスト
2. 必要に応じてドキュメントを更新
3. 既存デモにリグレッションがないことを確認
4. コードスタイルガイドラインに従う
5. 変更の明確な説明を提供
