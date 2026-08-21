extends Node
# Integrity

##     python3 tools/gen_integrity.py --write

const MANIFEST := {
	"autoload/config.gd": "6550c92e5ca43f1feb14aefeed03b1f853078c2403113151b864ff4b800514d3",
	"autoload/game_state.gd": "48597561277212cdd21e14e85acb79b38789d06fd24790be325ddd1a56cf7fa3",
	"autoload/save_system.gd": "c10c7d20a041b82e583b96c3ed256d79e5d39992bb2e96a31db7fd4e451ecc36",
	"autoload/story_engine.gd": "f8bcc800bcefae6c8f0e1fd6022f5c889fbae533853beffdc4c994bdb466a696",
}

const SALT := "The13thPeriod::integrity::v1"

var _failed: Array[String] = []
var _checked := false

static func _sha256_hex(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

func _ready() -> void:
	verify()

# Cache
func verify() -> void:
	if _checked:
		return
	_checked = true
	_failed.clear()
	for rel in MANIFEST:
		var path := "res://" + String(rel)
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			_failed.append(String(rel))
			continue
		var data := f.get_buffer(f.get_length())
		f.close()
		var salted := SALT.to_utf8_buffer()
		salted.append_array(data)
		if _sha256_hex(salted) != String(MANIFEST[rel]):
			_failed.append(String(rel))
	if not _failed.is_empty():
		push_warning("[完整性] 以下核心文件与发行版不一致：%s" % ", ".join(_failed))

func is_intact() -> bool:
	return _failed.is_empty()

func failed_files() -> Array[String]:
	return _failed

func notice() -> String:
	if _failed.is_empty():
		return ""
	return ("检测到游戏核心文件与官方发行版不一致：\n%s\n\n" +
		"这可能是因为你下载到了被第三方修改过的版本。\n" +
		"建议从官方发布页重新下载。") % ", ".join(_failed)
