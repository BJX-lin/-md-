class_name ExportManager
extends RefCounted

# ============================================================
#  导出管理器（V2.1）
#  把整段对话导出到 user:// 下，返回是否成功（供 UI 提示）。
#  纯离线，本地文件写入。
# ============================================================

# 导出对话；成功返回文件路径，失败返回空串
func export_transcript(transcript: String) -> String:
	var path := "user://辩论记录_%s.md" % str(int(Time.get_unix_time_from_system()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string("# 逻辑辩论记录\n\n" + transcript)
	f.close()
	return path

# 去 bbcode 标记（供导出纯净文本）
func strip_bbcode(s: String) -> String:
	var out := s
	out = out.replace("[b]", "").replace("[/b]", "")
	out = out.replace("[i]", "").replace("[/i]", "")
	var re := RegEx.create_from_string("\\\\[/?color[^\\\\]]*\\\\]")
	if re != null and re.is_valid():
		out = re.sub(out, "", true)
	return out
