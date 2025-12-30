# ブロックゲームシステム仕様

## 概要

ブロックゲームデモ(`project/blocky_game/`)は、ScriptVoxelで最も包括的なデモンストレーションで、マルチプレイヤーサポート、地形生成、ブロック編集、インベントリ管理、ボクセルシミュレーションを備えたMinecraftライクなボクセルゲームを実装しています。

## システムコンポーネント

### 1. ブロックシステム

#### ブロックレジストリ (blocks/blocks.gd)

**初期化要件:** シーンツリーの最初の子ノードである必要があります。

**責務:**
- ボクセルIDからブロックタイプへの中央レジストリマッピング
- ブロックメタデータ(名前、回転タイプ、プロパティ)を提供
- ボクセルIDからブロックIDへの変換を処理

**ブロック構造:**
```gdscript
{
    "id": int,              # 論理ブロックID
    "name": String,         # ブロック識別子
    "voxel_id": int,        # プライマリボクセルID
    "rotation_type": int,   # NONE, AXIAL, Y, CUSTOM
    "voxel_ids": Array,     # すべての回転バリアントID
}
```

**回転システム:**

| タイプ | 説明 | 例 | バリアント数 |
|-------|------|---|------------|
| NONE | 回転なし | 土、草、石 | 1 |
| AXIAL | 3軸回転 | 丸太、柱 | 3 |
| Y | Y軸のみ回転 | 階段、看板 | 4 |
| CUSTOM | カスタムマッピング | レール、複雑なブロック | 可変 |

**主要メソッド:**
```gdscript
get_block_by_name(name: String) -> int
get_block(block_id: int) -> Dictionary
get_block_name(block_id: int) -> String
get_rotation_type(block_id: int) -> int
get_voxel_id_from_block_rotation(block_id: int, dir: Vector3i) -> int
```

**重要な区別:**
- **ブロックID:** ゲームコードで使用される論理識別子
- **ボクセルID:** VoxelBufferに保存される生のID(回転バリアントを含む)
- レジストリは双方向マッピングを提供

#### ブロックライブラリ (voxel_library.tres)

**タイプ:** VoxelBlockyLibraryリソース

**構成:**
- 各ボクセルIDのビジュアルモデル
- 衝突形状
- マテリアル割り当て
- カリング動作
- 透明度設定

**モデルタイプ:**
- フルキューブ(ほとんどのブロック)
- カスタムメッシュ(階段、スラブ)
- クロスモデル(草、花)
- 空(空気)

### 2. 地形生成システム

#### メインジェネレーター (generator/generator.gd)

**基底クラス:** VoxelGeneratorScript

**生成プロセス:**

##### フェーズ1: ハイトマップ生成

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # チャンク内の各XZ位置について:
    var height = _get_height_at(x, z)
```

**ノイズ構成:**
- **タイプ:** FastNoiseLite
- **アルゴリズム:** Simplexノイズ
- **周波数:** 設定可能(地形スケールに影響)
- **振幅:** 高さの変動を制御

##### フェーズ2: レイヤー充填

```
チャンク内の各ボクセルについて:
    if y < height - 4:
        block = STONE
    elif y < height:
        block = DIRT
    elif y == height:
        block = GRASS (または水の近くでSAND)
    elif y <= WATER_LEVEL:
        block = WATER
    else:
        block = AIR
```

##### フェーズ3: 構造物配置

**木の配置:**
1. 事前生成された木構造(TreeGeneratorを参照)
2. 配置条件:
   - 草ブロック上
   - チャンク境界からの最小間隔(Moore近傍処理)
   - ノイズを使用したランダム分布
3. `VoxelTool.paste_masked()`を使用して貼り付け

**植物配置:**
- 草ブロック上の高い草
- 砂ブロック上の枯れ低木
- ランダム分布

#### ツリージェネレーター (generator/tree_generator.gd)

**目的:** 地形生成中の高速配置用に木構造を事前生成します。

**機能:**
- 初期化時に16種類の木バリアントを生成
- 幹の高さと樹冠サイズを変化
- VoxelBuffer構造として保存
- 木の丸太(AXIAL回転)と葉ブロックを使用

**構造フォーマット:**
```gdscript
{
    "buffer": VoxelBuffer,    # 事前構築された木構造
    "offset": Vector3i,       # 配置用の地面オフセット
}
```

**生成アルゴリズム:**
1. 幹を作成(高さ4-6ブロック)
2. 樹冠球を構築(半径2-3ブロック)
3. 丸太にAXIAL回転を使用
4. 貼り付け準備完了のバッファを返す

#### Moore近傍境界処理

**問題:** 構造物がチャンク境界をまたぐ可能性

**解決策:**
```gdscript
# チャンク端に近すぎる場所に構造物を配置しない
if x < MARGIN or x >= CHUNK_SIZE - MARGIN:
    continue
if z < MARGIN or z >= CHUNK_SIZE - MARGIN:
    continue
```

**MARGIN通常:** 木の半径 + 1ブロック

### 3. プレイヤーシステム

#### キャラクターコントローラー (player/character_controller.gd)

**物理システム:** VoxelBoxMover (CharacterBody3Dを置き換え)

**移動システム:**
```gdscript
var velocity: Vector3
var gravity: float = 20.0
var jump_strength: float = 8.0
var speed: float = 5.0

func _physics_process(delta):
    # 重力を適用
    velocity.y -= gravity * delta

    # 入力を処理
    var input_dir = get_input_direction()
    velocity.x = input_dir.x * speed
    velocity.z = input_dir.z * speed

    # ボクセル衝突で移動
    velocity = _box_mover.get_motion(velocity, delta, terrain)
    global_position += velocity * delta
```

**VoxelBoxMover機能:**
- ボクセルワールドとのAABB衝突
- スライディング衝突応答
- 段差上り処理
- 水/はしご検出サポート

#### アバターインタラクション (player/avatar_interaction.gd)

**ボクセルレイキャスト:**
```gdscript
var voxel_tool: VoxelTool = terrain.get_voxel_tool()

# カメラからレイキャスト
var hit = voxel_tool.raycast(camera_origin, camera_direction, 10.0)

if hit:
    var hit_position: Vector3i = hit.position
    var prev_position: Vector3i = hit.previous_position
```

**ブロック削除:**
```gdscript
func remove_block(position: Vector3i):
    voxel_tool.set_voxel(position, Blocks.AIR)
```

**ブロック配置:**
```gdscript
func place_block(position: Vector3i, block_id: int):
    # 回転に適したボクセルIDを取得
    var look_dir = get_look_direction()
    var voxel_id = Blocks.get_voxel_id_from_block_rotation(block_id, look_dir)

    voxel_tool.set_voxel(position, voxel_id)
```

**ブロックピック(中クリック):**
```gdscript
func pick_block(position: Vector3i):
    var voxel_id = voxel_tool.get_voxel(position)
    var block_id = Blocks.get_block_from_voxel_id(voxel_id)
    # ホットバーに追加
```

### 4. インベントリシステム (gui/inventory/inventory.gd)

#### 構造

**総スロット数:** 36
- **バッグ:** 27スロット(3行 × 9列)
- **ホットバー:** 9スロット(下部に表示)

**スロット定義:**
```gdscript
{
    "item_id": int,    # 空の場合は-1
    "amount": int,     # スタックサイズ
}
```

#### 操作

**アイテム追加:**
```gdscript
func add_item(item_id: int, amount: int) -> int:
    # 1. 既存アイテムとスタック試行
    # 2. 空のスロットを埋める
    # 3. 満杯の場合は残り数量を返す
```

**アイテム削除:**
```gdscript
func remove_item(item_id: int, amount: int) -> bool:
    # インベントリから指定量を削除
    # 成功時にtrueを返す
```

**ドラッグアンドドロップ:**
- クリックでスタックをピックアップ
- 空のスロットにクリックで配置
- 同じアイテムにクリックでスタック
- 右クリックでハーフスタック操作

#### ホットバー統合

- ホットバースロットはインベントリスロット27-35
- 数字キー(1-9)でホットバースロット選択
- 選択されたスロットがハイライト
- 現在のアイテムをブロック配置/ツール使用に使用

### 5. アイテムシステム (items/item_db.gd)

**構造:**
```gdscript
var items: Dictionary = {
    0: {
        "name": "block_placer",
        "type": "block",
        "block_id": 1,
    },
    1: {
        "name": "rocket_launcher",
        "type": "tool",
        "script": "rocket_launcher.gd",
    },
}
```

**アイテムタイプ:**
- **block:** ブロックを配置(ブロックIDを参照)
- **tool:** 特別な機能(使用アクションを実装)

**ツールインターフェース:**
```gdscript
# カスタムツールスクリプト
func use(player: Node, terrain: VoxelTerrain):
    # ツールアクションを実装
```

### 6. シミュレーションシステム

#### ランダムティックシステム (random_ticks.gd)

**目的:** 草の広がりシミュレーション

**構成:**
- **ティックレート:** 毎フレーム512ボクセル
- **範囲:** プレイヤーから100ブロック半径
- **実装:** `VoxelTool.run_blocky_random_tick()`

**コールバックシステム:**
```gdscript
voxel_tool.run_blocky_random_tick(
    center,
    radius,
    tick_count,
    callback,
    batch_count
)
```

**草の広がりロジック:**
```gdscript
func _on_random_tick(voxel_info: Dictionary):
    var pos: Vector3i = voxel_info.position
    var voxel_id: int = voxel_info.voxel_id

    if voxel_id == Blocks.DIRT:
        # 上のブロックが空気か(光があるか)チェック
        var above = voxel_tool.get_voxel(pos + Vector3i(0, 1, 0))
        if above == Blocks.AIR:
            # 草に変換
            voxel_tool.set_voxel(pos, Blocks.GRASS)
```

#### 水シミュレーション (water.gd)

**アルゴリズム:** キューベースのセルオートマトン

**デュアルキューシステム:**
- **キューA:** 現在の処理キュー
- **キューB:** 次フレームキュー
- 各更新サイクル後にスワップ

**更新サイクル:**
```gdscript
var updates_per_cycle = 64
var update_interval = 0.2  # 秒

func _process_water():
    for i in range(updates_per_cycle):
        if queue_a.is_empty():
            queue_a, queue_b = queue_b, queue_a
            break

        var pos = queue_a.pop_front()
        _spread_water_from(pos)
```

**広がりロジック:**
```gdscript
func _spread_water_from(pos: Vector3i):
    # 5方向をチェック: 4水平 + 下
    var directions = [
        Vector3i(1, 0, 0),
        Vector3i(-1, 0, 0),
        Vector3i(0, 0, 1),
        Vector3i(0, 0, -1),
        Vector3i(0, -1, 0),  # 下への広がりを優先
    ]

    for dir in directions:
        var neighbor = pos + dir
        var voxel = voxel_tool.get_voxel(neighbor)

        if voxel == Blocks.AIR:
            # 水に変換
            voxel_tool.set_voxel(neighbor, Blocks.WATER)
            queue_b.append(neighbor)
```

**水バリアント:**
- **フルブロック:** WATER (完全に満たされている)
- **上面:** WATER_SURFACE (部分ブロック)

### 7. マルチプレイヤーシステム

#### ゲームモード

```gdscript
enum Mode {
    SINGLEPLAYER,
    CLIENT,
    HOST,
}
```

#### ネットワークアーキテクチャ

**サーバー (HOST):**
- 地形生成を実行
- シミュレーション(水、ランダムティック)を実行
- すべての地形変更に権限を持つ
- 各リモートプレイヤー用にVoxelViewerを作成

**クライアント:**
- 同期機経由で地形データを受信
- ローカルプレイヤー物理を実行
- ブロック編集用にRPCを送信
- プレイヤー位置をブロードキャスト

#### 地形同期

**セットアップ:**
```gdscript
var synchronizer = VoxelTerrainMultiplayerSynchronizer.new()
synchronizer.terrain = terrain
add_child(synchronizer)
```

**動作:**
- サーバーからクライアントへのボクセル変更を自動同期
- VoxelViewer位置に基づいてチャンクストリーミングを処理
- ネットワーク転送用にデータを圧縮

#### RPCメソッド

**ブロック配置:**
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func receive_place_single_block(pos: Vector3i, block_id: int):
    if not multiplayer.is_server():
        return  # サーバー権限

    # 検証してブロックを配置
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel(pos, block_id)
    # クライアントに自動同期
```

**プレイヤー位置:**
```gdscript
@rpc("any_peer", "call_remote", "unreliable")
func receive_player_position(pos: Vector3, rot: Vector3):
    # リモートプレイヤーアバターを更新
```

#### プレイヤースポーン

**ローカルプレイヤー:**
```gdscript
func spawn_local_player():
    var avatar = CharacterAvatar.instantiate()
    avatar.is_local = true
    add_child(avatar)
```

**リモートプレイヤー (サーバー):**
```gdscript
func spawn_remote_player(peer_id: int):
    var avatar = CharacterAvatar.instantiate()
    avatar.is_local = false
    avatar.peer_id = peer_id

    # 地形ストリーミング用のVoxelViewerを作成
    var viewer = VoxelViewer.new()
    avatar.add_child(viewer)

    add_child(avatar)
```

#### UPNPサポート (upnp_helper.gd)

**ポート転送:**
```gdscript
func setup_upnp(port: int):
    var upnp = UPNP.new()
    var result = upnp.discover()

    if result == UPNP.UPNP_RESULT_SUCCESS:
        upnp.add_port_mapping(port, port, "ScriptVoxel", "UDP")
```

## パフォーマンス考慮事項

### 最適化戦略

1. **チャンクベース処理:** すべての地形操作は16³または32³チャンクで動作
2. **LODシステム:** 一貫したパフォーマンスのためVoxelTerrainで固定LOD
3. **シミュレーション調整:** フレームあたりの更新制限(512ランダムティック、64水更新)
4. **VoxelViewer範囲:** プレイヤーごとの地形ストリーミング半径を制御

### プロファイリングポイント

- 地形生成時間(DDDデバッグ出力を参照)
- メッシュ更新頻度
- シミュレーションシステムオーバーヘッド
- ネットワーク帯域幅(マルチプレイヤー)

## 設定

### ゲーム定数

```gdscript
const CHUNK_SIZE = 16
const WATER_LEVEL = 0
const PLAYER_SPAWN_HEIGHT = 64
const VOXEL_VIEW_DISTANCE = 256
const GRAVITY = 20.0
const PLAYER_SPEED = 5.0
const JUMP_STRENGTH = 8.0
```

### ブロックID

blocks.gdレジストリで定義:
- 0: AIR
- 1: GRASS
- 2: DIRT
- 3: STONE
- ... (拡張可能)

## ファイルロケーション

| コンポーネント | パス |
|--------------|------|
| メインシーン | `project/blocky_game/main.tscn` |
| ゲームスクリプト | `project/blocky_game/blocky_game.gd` |
| ブロックレジストリ | `project/blocky_game/blocks/blocks.gd` |
| ジェネレーター | `project/blocky_game/generator/generator.gd` |
| ツリージェネレーター | `project/blocky_game/generator/tree_generator.gd` |
| キャラクターコントローラー | `project/blocky_game/player/character_controller.gd` |
| アバターインタラクション | `project/blocky_game/player/avatar_interaction.gd` |
| インベントリ | `project/blocky_game/gui/inventory/inventory.gd` |
| アイテムデータベース | `project/blocky_game/items/item_db.gd` |
| ランダムティック | `project/blocky_game/random_ticks.gd` |
| 水シミュレーション | `project/blocky_game/water.gd` |
| インタラクション共通 | `project/blocky_game/interaction_common.gd` |
| ブロックライブラリ | `project/blocky_game/voxel_library.tres` |
