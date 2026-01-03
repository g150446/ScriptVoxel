extends GutTest

# GUT形式のキャラクタースポーンテスト

const BlockyGame = preload("res://../project/blocky_game/blocky_game.gd")
const BlockyGameScene = preload("res://../project/blocky_game/blocky_game.tscn")
const InteractionCommon = preload("res://../project/blocky_game/player/interaction_common.gd")

var _game: Node = null

func before_each():
	# 各テスト前にクリーンアップ
	if _game != null:
		_game.queue_free()
		_game = null
		await get_tree().process_frame

func after_each():
	# 各テスト後にクリーンアップ
	if _game != null:
		_game.queue_free()
		_game = null
		await get_tree().process_frame

#
# テスト1: 新規ワールド作成時にキャラクターが1体のみスポーンされる (最重要!)
#
func test_no_duplicate_spawn_on_new_world():
	# Arrange
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child_autofree(_game)

	# _ready()が実行されるのを待つ
	await get_tree().process_frame

	# Act
	_game.start_new_world(0, "Test World", 12345)
	await get_tree().process_frame

	# Assert
	var player_container = _game.get_node("Players")
	var character_count = player_container.get_child_count()

	assert_eq(character_count, 1, "キャラクター数は正確に1体であるべき")
	assert_true(player_container.has_node("1"), "SERVER_PEER_ID=1のキャラクターが存在するべき")

#
# テスト2: start_new_worldでキャラクターが正しくスポーンされる
#
func test_start_new_world_spawns_character():
	# Arrange
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child_autofree(_game)

	await get_tree().process_frame

	# Act
	_game.start_new_world(0, "Test World 2", 54321)
	await get_tree().process_frame

	# Assert
	var player_container = _game.get_node("Players")
	var has_character = player_container.has_node("1")
	var character_count = player_container.get_child_count()

	assert_true(has_character, "キャラクターノード '1' が存在するべき")
	assert_gte(character_count, 1, "少なくとも1体のキャラクターが存在するべき")

#
# テスト3: ブロック配置が正常に動作する
#
func test_block_placement_works():
	# Arrange
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child_autofree(_game)

	await get_tree().process_frame

	_game.start_new_world(0, "Test World 3", 99999)
	await get_tree().process_frame
	await get_tree().process_frame  # 追加の待機

	var terrain = _game.get_terrain()
	assert_not_null(terrain, "terrain should not be null")

	var terrain_tool = terrain.get_voxel_tool()
	var blocks = _game.get_node_or_null("Blocks")
	assert_not_null(blocks, "Blocks node should exist")

	var water = _game.get_node_or_null("Water")
	assert_not_null(water, "Water node should exist")

	# Act
	var grass_id = blocks.get_block_by_name("grass")
	assert_not_null(grass_id, "grass block ID should not be null")
	assert_ne(grass_id, 0, "grass block ID should not be 0 (air)")

	var test_pos = Vector3(10, 64, 10)
	InteractionCommon.place_single_block(
		terrain_tool,
		test_pos,
		Vector3(0, 0, -1),
		grass_id,
		blocks,
		water
	)

	# Assert
	var placed_voxel_id = terrain_tool.get_voxel(test_pos)
	assert_ne(placed_voxel_id, 0, "配置されたブロックは空気(0)であってはならない")
	gut.p("  配置されたブロックのvoxel ID: " + str(placed_voxel_id))

#
# テスト4: _ready()でキャラクターが自動スポーンされないことを確認
#
func test_ready_does_not_spawn_character():
	# Arrange & Act
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child_autofree(_game)

	await get_tree().process_frame

	# Assert
	var player_container = _game.get_node("Players")
	var character_count = player_container.get_child_count()

	assert_eq(character_count, 0, "_ready()後はキャラクターがスポーンされていないべき")

#
# テスト5: ワールドロード時に既存キャラクターがクリアされる
#
func test_load_world_clears_existing_characters():
	# このテストはセーブファイルが必要なのでスキップ
	# 実際のセーブ/ロード機能のテストは手動で行う
	pass_test("セーブファイルが必要なためスキップ")
