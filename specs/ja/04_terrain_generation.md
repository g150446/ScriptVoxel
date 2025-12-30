# 地形生成仕様

## 概要

ScriptVoxelは、シンプルなノイズベースのハイトマップから構造物配置を伴う複雑なマルチパスシステムまで、複数の地形生成アプローチを実証します。この仕様は、異なるデモで使用される生成システムをカバーします。

## 生成アプローチ

### 1. シングルパスハイトマップ生成

**使用場所:** ブロックゲーム、ブロック地形デモ

**プロセスフロー:**
```
ハイトマップ生成 → レイヤー充填 → 構造物配置 → バッファ返却
```

#### 実装パターン

```gdscript
extends VoxelGeneratorScript

var _noise: FastNoiseLite

func _init():
    _noise = FastNoiseLite.new()
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    _noise.frequency = 0.01
    _noise.fractal_octaves = 3

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod  # LODスケーリング

    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z) * stride
                var height = _get_height_at(world_pos.x, world_pos.z)

                var block_id = _determine_block(world_pos.y, height)
                out_buffer.set_voxel(Vector3i(x, y, z), block_id, 0)
```

### 2. マルチパス生成

**使用場所:** マルチパスジェネレーターデモ

**目的:** 地形分析に依存する構造物配置を可能にする

#### パスシステム

```gdscript
extends VoxelGeneratorMultipassCB

func _get_pass_count() -> int:
    return 2  # 地形パス + 構造物パス

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int, pass_index: int):
    if pass_index == 0:
        _generate_terrain(out_buffer, origin, lod)
    elif pass_index == 1:
        _place_structures(out_buffer, origin, lod)
```

#### パス0: 地形生成

```gdscript
func _generate_terrain(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # 標準的なハイトマップ生成
    # 他のチャンクへの依存なし
```

#### パス1: 構造物配置

```gdscript
func _place_structures(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # パス0から地形を読み取り可能
    var voxel_tool = out_buffer.get_voxel_tool()

    for structure_pos in _get_structure_positions(origin):
        # パス0から地面ブロックをチェック
        var ground_block = voxel_tool.get_voxel(structure_pos)

        if ground_block == GRASS:
            _place_tree(out_buffer, structure_pos)
```

**利点:**
- 構造物が実際の地形をクエリ可能
- 変化に富んだ地形への自然な配置
- 複雑なマルチブロック機能

**パフォーマンスコスト:**
- 同じチャンクに対して複数パス必要
- 生成時間の増加

### 3. SDF (符号付き距離場) 生成

**使用場所:** スムーズ地形デモ

**アプローチ:** 離散ブロックの代わりに距離場を生成

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)

                # 符号付き距離を計算
                var distance = _calculate_sdf(world_pos)

                # SDFチャネルに保存
                out_buffer.set_voxel_f(Vector3i(x, y, z), distance)
```

**SDFプロパティ:**
- 負の値: 地形内部(固体)
- 正の値: 地形外部(空気)
- ゼロ: 表面境界
- Transvoxelメッシングでスムーズ地形を可能にする

## ノイズ構成

### FastNoiseLite設定

#### 基本地形

```gdscript
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
noise.frequency = 0.005       # より大きなスケールの特徴
noise.fractal_octaves = 4     # 詳細レベル
noise.fractal_lacunarity = 2.0
noise.fractal_gain = 0.5
```

**周波数:** 特徴サイズを制御
- 低(0.001-0.005): 大きな大陸、山
- 中(0.01-0.02): 丘、谷
- 高(0.05-0.1): 小さな詳細

**オクターブ:** 重ねられた詳細
- 1: シンプルで滑らかなノイズ
- 3-4: 自然な地形の外観
- 6+: 非常に詳細(高コスト)

#### バイオーム変化

```gdscript
var biome_noise = FastNoiseLite.new()
biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
biome_noise.frequency = 0.001  # 大きなバイオーム領域
```

**ノイズタイプ:**
- **Simplex:** 滑らか、有機的な地形
- **Perlin:** クラシックな地形生成
- **Cellular:** バイオーム領域、洞窟システム
- **Value:** ブロック状の特徴

### ハイトマップ計算

#### 基本ハイトマップ

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var noise_value = _noise.get_noise_2d(x, z)  # 範囲: -1 to 1
    var height = BASE_HEIGHT + noise_value * AMPLITUDE
    return height
```

**設定例:**
```gdscript
const BASE_HEIGHT = 32
const AMPLITUDE = 20

# 結果: 高さ範囲 12 から 52
```

#### マルチオクターブハイトマップ

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var height = 0.0

    # 大きな特徴
    height += _noise_large.get_noise_2d(x, z) * 30.0

    # 中規模特徴
    height += _noise_medium.get_noise_2d(x, z) * 10.0

    # 細部
    height += _noise_small.get_noise_2d(x, z) * 3.0

    return BASE_HEIGHT + height
```

#### バイオームブレンドハイトマップ

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var biome_value = _biome_noise.get_noise_2d(x, z)

    var plains_height = _plains_noise.get_noise_2d(x, z) * 5.0
    var mountain_height = _mountain_noise.get_noise_2d(x, z) * 50.0

    # バイオームに基づいてブレンド
    var blend = (biome_value + 1.0) / 2.0  # 0-1に再マップ
    var height = lerp(plains_height, mountain_height, blend)

    return BASE_HEIGHT + height
```

## レイヤー充填戦略

### シンプルな成層レイヤー

```gdscript
func _determine_block(y: int, height: float) -> int:
    if y < height - 4:
        return STONE
    elif y < height:
        return DIRT
    elif y == int(height):
        return GRASS
    else:
        return AIR
```

### 水対応レイヤー

```gdscript
const WATER_LEVEL = 0

func _determine_block(y: int, height: float) -> int:
    if y < height:
        if y < height - 4:
            return STONE
        else:
            return DIRT
    elif y == int(height):
        if height < WATER_LEVEL:
            return SAND  # 水中地形
        else:
            return GRASS
    elif y <= WATER_LEVEL:
        return WATER
    else:
        return AIR
```

### 鉱石分布

```gdscript
func _determine_block(y: int, height: float, x: int, z: int) -> int:
    if y >= height:
        return AIR

    var base_block = STONE if y < height - 4 else DIRT

    # 3Dノイズを使用した鉱脈
    var ore_noise = _ore_noise.get_noise_3d(x, y, z)

    if base_block == STONE:
        if ore_noise > 0.7 and y < 20:
            return DIAMOND_ORE
        elif ore_noise > 0.6 and y < 40:
            return IRON_ORE
        elif ore_noise > 0.5 and y < 60:
            return COAL_ORE

    return base_block
```

## 構造物配置

### 事前生成パターン

**目的:** 地形生成中の構造物生成を回避

```gdscript
# 初期化
var _tree_structures: Array = []

func _ready():
    _generate_tree_structures()

func _generate_tree_structures():
    for i in range(16):
        var tree = _generate_single_tree()
        _tree_structures.append(tree)

func _generate_single_tree() -> Dictionary:
    var buffer = VoxelBuffer.new()
    buffer.create(7, 10, 7)  # 木のサイズ

    # バッファに木を構築
    # ... 木生成ロジック ...

    return {
        "buffer": buffer,
        "offset": Vector3i(3, 0, 3),  # 地面アンカーポイント
    }
```

### 生成中の配置

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # 1. 地形を生成
    _fill_terrain_layers(out_buffer, origin)

    # 2. 構造物を配置
    var voxel_tool = out_buffer.get_voxel_tool()

    for tree_pos in _get_tree_positions(origin):
        var tree = _tree_structures[randi() % _tree_structures.size()]

        # 境界チェック(Moore近傍)
        if _is_near_boundary(tree_pos, origin, tree.buffer.get_size()):
            continue

        # 木を配置
        voxel_tool.paste_masked(
            tree_pos - tree.offset,
            tree.buffer,
            AIR,  # マスク値(非空気を置換しない)
            0     # チャネル
        )
```

### 境界処理

**Moore近傍問題:** チャンク端近くの構造物は不完全になる可能性

```gdscript
func _is_near_boundary(pos: Vector3i, origin: Vector3i, size: Vector3i) -> bool:
    var local_pos = pos - origin
    var chunk_size = 16

    var margin = ceili(size.x / 2.0)  # 構造物サイズの半分

    if local_pos.x < margin or local_pos.x >= chunk_size - margin:
        return true
    if local_pos.z < margin or local_pos.z >= chunk_size - margin:
        return true

    return false
```

**解決策:** 境界近くの配置をスキップし、隣接チャンクに処理させる

### 決定論的配置

**要件:** 同じシードで同じ構造物を生成する必要

```gdscript
func _get_tree_positions(origin: Vector3i) -> Array:
    var positions = []
    var chunk_size = 16

    # 決定論的ランダム性のためチャンク位置をシードとして使用
    var seed_hash = hash(Vector2i(origin.x, origin.z))
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_hash

    for i in range(rng.randi_range(0, 3)):  # チャンクあたり0-3本の木
        var x = origin.x + rng.randi_range(MARGIN, chunk_size - MARGIN)
        var z = origin.z + rng.randi_range(MARGIN, chunk_size - MARGIN)
        var y = int(_get_height_at(x, z))

        positions.append(Vector3i(x, y, z))

    return positions
```

## 植物と詳細配置

### 散布パターン

```gdscript
func _place_foliage(out_buffer: VoxelBuffer, origin: Vector3i):
    var voxel_tool = out_buffer.get_voxel_tool()

    for z in range(out_buffer.get_size().z):
        for x in range(out_buffer.get_size().x):
            var world_x = origin.x + x
            var world_z = origin.z + z

            var height = int(_get_height_at(world_x, world_z))
            var local_y = height - origin.y

            if local_y < 0 or local_y >= out_buffer.get_size().y:
                continue

            var surface_block = voxel_tool.get_voxel(Vector3i(x, local_y, z))

            if surface_block == GRASS:
                # ランダム植物配置
                var foliage_noise = _foliage_noise.get_noise_2d(world_x, world_z)
                if foliage_noise > 0.3:
                    voxel_tool.set_voxel(Vector3i(x, local_y + 1, z), TALL_GRASS)
```

## 洞窟生成

### 3Dノイズ洞窟

```gdscript
func _generate_caves(out_buffer: VoxelBuffer, origin: Vector3i):
    var voxel_tool = out_buffer.get_voxel_tool()

    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)

                # 固体ブロックにのみ洞窟を掘る
                var current_block = voxel_tool.get_voxel(Vector3i(x, y, z))
                if current_block == AIR:
                    continue

                # 洞窟トンネル用の3Dノイズ
                var cave_noise = _cave_noise.get_noise_3d(
                    world_pos.x,
                    world_pos.y,
                    world_pos.z
                )

                if cave_noise > 0.6:  # 洞窟を掘る
                    voxel_tool.set_voxel(Vector3i(x, y, z), AIR)
```

### ワーム洞窟

```gdscript
func _generate_worm_cave(origin: Vector3i, seed_value: int):
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value

    var pos = origin + Vector3i(8, 32, 8)  # 開始位置
    var direction = Vector3(rng.randf(), rng.randf(), rng.randf()).normalized()

    var voxel_tool = terrain.get_voxel_tool()

    for i in range(200):  # トンネル長
        # 現在位置に球を掘る
        voxel_tool.do_sphere(pos, 3.0)

        # 位置を更新
        pos += direction * 2.0

        # ランダムに方向を調整
        direction += Vector3(
            rng.randf() - 0.5,
            rng.randf() - 0.5,
            rng.randf() - 0.5
        ) * 0.2
        direction = direction.normalized()
```

## パフォーマンス最適化

### チャンクキャッシング

```gdscript
var _generated_chunks: Dictionary = {}

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var chunk_key = Vector3i(origin.x / 16, origin.y / 16, origin.z / 16)

    if _generated_chunks.has(chunk_key):
        return  # すでに生成済み

    # チャンクを生成
    # ...

    _generated_chunks[chunk_key] = true
```

### LOD対応生成

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod  # 1, 2, 4, 8...

    if lod > 0:
        # 遠いチャンクの簡略化された生成
        _generate_simplified(out_buffer, origin, stride)
    else:
        # 近いチャンクの完全な詳細
        _generate_detailed(out_buffer, origin)
```

### 非同期構造物生成

```gdscript
func _ready():
    _generate_structures_async()

func _generate_structures_async():
    for i in range(16):
        var tree = _generate_single_tree()
        _tree_structures.append(tree)
        await get_tree().process_frame  # 複数フレームに分散
```

## VoxelBuffer操作

### ボクセルの書き込み

```gdscript
# 単一ボクセル
out_buffer.set_voxel(Vector3i(x, y, z), voxel_id, channel)

# 領域を充填
out_buffer.fill(voxel_id, channel)
out_buffer.fill_area(voxel_id, Vector3i(min), Vector3i(max), channel)
```

### 構造物の貼り付け

```gdscript
# すべてのボクセルを貼り付け
voxel_tool.paste(position, source_buffer, channel, mask_value)

# 非マスクボクセルのみを貼り付け
voxel_tool.paste_masked(position, source_buffer, mask_value, channel)
```

### チャネル

- **チャネル0:** ブロックタイプ(最も一般的)
- **チャネル1:** SDF値(スムーズ地形)
- **チャネル2-3:** カスタムデータ(メタデータ、回転など)

## テストとデバッグ

### デバッグ可視化

```gdscript
# チャンク境界を表示
DDD.draw_box(origin, Vector3(16, 16, 16), Color.RED)

# 構造物配置を表示
DDD.set_text("Trees Placed", tree_count)
```

### 生成メトリクス

```gdscript
var start_time = Time.get_ticks_usec()
_generate_block(out_buffer, origin, lod)
var end_time = Time.get_ticks_usec()

DDD.set_text("Gen Time (ms)", (end_time - start_time) / 1000.0)
```

## ファイルロケーション

| コンポーネント | パス |
|--------------|------|
| ブロックジェネレーター | `project/blocky_game/generator/generator.gd` |
| ツリージェネレーター | `project/blocky_game/generator/tree_generator.gd` |
| マルチパスジェネレーター | `project/multipass_generator/multipass_generator.gd` |
| スムーズ地形ジェネレーター | `project/smooth_terrain/*.tres` (リソースファイル) |
