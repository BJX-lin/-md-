# Android 接入 llama.cpp 本地 LLM（插件骨架）

> 本文档对应 **B 路线：接入 llama.cpp 本地 LLM**。
> 前提是**必须在真机/你的电脑上完成**：Godot 沙箱无法编译 Android、无法跑 Gradle、无法加载 GGUF。
>
> Godot 端已完成可插拔层（默认关闭、回退纯规则）：`LLMConfig.gd` / `LLMProvider.gd` / `LocalLLM.gd` / `ResponseGenerator.gd`，
> 以及 `DebateEngine.set_llm()` 与 `Main.gd` 的「模型」按钮。**本文只负责让那个接口真正跑起来。**

---

## 0. 总体思路（与 Godot 端接口一致）

```
Godot (LocalLLM.gd)
   │  Engine.get_singleton("LlamaCpp")
   ▼
Android 插件（Kotlin，单例名 "LlamaCpp"）
   │
   ▼
llama.cpp (JNI / llama-android)
   │
   ▼
GGUF 模型文件（user://model.gguf → 应用私有目录）
```

- Godot 端只认单例名 **`"LlamaCpp"`**（见 `LLMConfig.plugin_singleton`）。
- 插件必须实现这几个方法（签名要一致，否则 `LocalLLM` 会因 `has_method` 为 false 而自动回退纯规则，不报错）：
  - `boolean load_model(String path, int context_size)`
  - `void unload_model()`
  - `boolean is_loaded()`
  - `String generate(String prompt, int max_tokens)`
  - `void cancel()`

---

## 1. 前置：在 Godot 手机版里装 Android 构建模板

1. 打开项目 `godot_logic_game/project.godot`（Godot 4.7.2 手机版）。
2. 菜单 `项目 → 安装 Android 构建模板(Build Template)`。
3. 确认项目下出现 `android/` 目录（内含 Gradle 工程）。
4. 菜单 `项目 → 导出 → Android`，找到 **`Gradle Build`**，把它勾上/设为开启。

> ⚠️ 如果这一步**没有生成 `android/` 或没有 `Gradle Build` 选项**：说明你的 4.7.2 手机版还没安装构建模板，或编辑器不支持本机 Gradle。**不要自己乱建 `android` 文件夹**，也不要下载网上不知名的 Godot LLM 插件。把「项目 → 导出 → Android」整页截图给我，据此继续。

---

## 2. 插件目录结构（放在你已生成的 `android/` 里）

```
android/
├── build.gradle
├── settings.gradle
├── gradle.properties
├── app/
│   ├── build.gradle
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/example/logic_debate/
│       │   └── LlamaCppPlugin.kt        # 给 Godot 的单例（关键）
│       └── jniLibs/
│           ├── libllama.so              # llama.cpp 预编译 so（含 JNI 层）
│           ├── libggml.so
│           └── (其它依赖 so)
└── assets/ 或 应用私有目录放 model.gguf
```

---

## 3. 关键：`LlamaCppPlugin.kt`（Godot 单例）

Godot Android 插件要实现 `org.godotengine.plugin.v1.GodotPlugin`。下面是最小骨架（方法名与 Godot 端一一对应）。

```kotlin
package com.example.logic_debate

import android.content.Context
import org.godotengine.plugin.v1.GodotPlugin
import org.godotengine.plugin.v1.Godot
import android.util.Log

// llama.cpp 的 JNI 封装（需你自己用 llama.cpp 的 ndk 编译出 libllama.so 并配套 JNI 头函数）
// 这里用 name 占位，直观展示调用点。真正实现要按 llama.cpp JNI 暴露的函数写。
class LlamaCppPlugin(godot: Godot) : GodotPlugin(godot) {

    private val TAG = "LlamaCppPlugin"

    // 插件名：Godot 端 Engine.get_singleton("LlamaCpp")
    override fun getPluginName(): String = "LlamaCpp"

    // Godot 端 Engine.get_singleton(...) 返回的对象要实现这些方法
    // 需要注册哪些方法：用 @UsedByGodot 标注，Godot 自动反射
    @UsedByGodot
    fun load_model(path: String, context_size: Int): Boolean {
        // 1) 从 path 读取 GGUF 文件（path 是 user:// 解析后的绝对路径 / 或已复制到私有目录）
        // 2) llama 初始化模型 + context
        //    return LlamaBridge.loadModel(path, context_size)
        Log.i(TAG, "load_model($path, $context_size)")
        return true   // 占位：真机换成实际加载结果
    }

    @UsedByGodot
    fun unload_model() {
        // LlamaBridge.unloadModel()
    }

    @UsedByGodot
    fun is_loaded(): Boolean {
        return true  // 占位：返回模型是否在内存
    }

    @UsedByGodot
    fun generate(prompt: String, max_tokens: Int): String {
        // return LlamaBridge.generate(prompt, max_tokens)
        // 占位：返回一句中文，证明通了
        return "（本地模型）×" + max_tokens + " tokens"  // TODO 换真实推理
    }

    @UsedByGodot
    fun cancel() {
        // 取消正在生成的请求
    }
}
```

> 上面 `load_model/generate` 里的 `LlamaBridge` 是你**真正接 llama.cpp JNI** 的地方。llama.cpp 官方 Android 文档给了 `llama.cpp` 的绑定与加载 GGUF 的示例（github.com/crc-org/llama.cpp/blob/main/docs/android.md）。你需要：
> 1. 用 NDK 把 llama.cpp 编成 `libllama.so` 放进 `android/app/src/main/jniLibs/`；
> 2. 写一层 JNI 把 `loadModel/unloadModel/generate` 暴露给 Kotlin；
> 3. 把量化 GGUF（手机先上小模型，见下）放进 `android/app/src/main/assets/` 或在启动时复制到 `context.filesDir`。

---

## 4. 模型选择（关键：手机先小、短上下文）

同样遵循 Godot 端 `LLMConfig` 的保守设定（这些都已在 `LLMConfig.gd` 里能改）：

| 参数 | 建议值 | 原因 |
|---|---|---|
| 模型 | **0.5B~3B 量化 GGUF**（如 Qwen2.5-0.5B/1.5B、Llama-3.2-1B、Phi-3-mini-4k 量化） | 手机内存/速度限制 |
| context_size | **512**（已默认） | llama.cpp 文档明确：过大内存暴涨 |
| max_tokens | **80**（已默认） | 短回答即可 |
| 温度 | 0.7（已默认） | 规则型回复，别太随机 |

**为什么小模型就够**：我们的规则引擎已承担"判定逻辑错误"的重活，LLM 只负责**把判定结果自然语言化**（"怎么说"），不需要它自己推理对错。所以小模型+短回答完全够用。

---

## 5. Godot 端操作顺序

1. 把上面生成的 `android/` 放回项目。
2. 项目里放一个 `model.gguf`（或让启动时复制到 `user://`）。
3. 运行 App，点底部「模型」按钮：
   - 若插件存在且能 `load_model` → 显示「已启用本地模型（已加载）」→ 之后 AI 回复会由本地 LLM 润色。
   - 若检测不到插件 → 显示「未检测到模型插件，使用纯规则引擎」→ **游戏照常可玩**（这就是"默认降级、不破坏"）。

> `LocalLLM.is_available()` 在未注册插件或未加载模型时返回 false，`DebateEngine` 自动回退纯规则，**绝不会因缺少模型而报错或空回应**。

---

## 6. 排查清单

- [ ] 「项目→安装 Android 构建模板」成功，`android/` 已生成。
- [ ] 「导出→Android」里有 `Gradle Build` 且已开启。
- [ ] `libllama.so` 等放在 `android/app/src/main/jniLibs/`（架构 v8a/arm64-v8a 要匹配），且 `abiFilters` 配好。
- [ ] 插件类 `LlamaCppPlugin` 实现了 `getPluginName()="LlamaCpp"`，方法用 `@UsedByGodot` 标注。
- [ ] Godot 端「模型」按钮显示「已启用（已加载）」，且 AI 回复变成了模型生成的口吻。
- [ ] 若按钮显示「已开但模型未加载」→ 检查 GGUF 路径是否为 `user://model.gguf`、`load_model` 是否真的返回 true。

> ⚠️ 重要安全提醒：**这是真机才能完成的步骤**。Godot 沙箱仓库里我已写好 Godot 端可插拔层并做静态校验，但**上面的 Android/Gradle/JNI/GGUF 部分我无法在此编译验证**——请你在手机端一步步来，任何一步报错（尤其「没有 Gradle Build」）**截图给我**，我据此调整，不要自己乱建 `android/` 或下不明插件。

---

## 参考（可靠来源）
- Godot 4.7 Android 构建模板（GABE）：docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html
- Godot 4.7 Android 插件（GodotPlugin）：docs.godotengine.org/en/4.7/tutorials/platform/android/javaclasswrapper_and_androidruntimeplugin.html
- llama.cpp Android 绑定（加载 GGUF、context 内存警告）：github.com/crc-org/llama.cpp/blob/main/docs/android.md
