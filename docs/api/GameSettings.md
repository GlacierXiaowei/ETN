# GameSettings API 文档

全局设置单例，管理游戏设置项并持久化到本地。

## 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| `debug_mode_changed` | `enabled: bool` | 调试模式变化时触发 |

## 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `debug_mode` | `bool` | `false` | 调试模式开关 |

## 方法

### `load_settings() -> void`
从本地文件加载设置。游戏启动时自动调用。

---

### `save_settings() -> void`
保存设置到本地文件。

---

### `set_debug_mode(enabled: bool) -> void`
设置调试模式。

**参数：**
- `enabled`: 是否开启调试模式

**行为：**
- 更新 `debug_mode` 属性
- 自动保存到本地文件
- 触发 `debug_mode_changed` 信号

**示例：**
```gdscript
GameSettings.set_debug_mode(true)
```

---

### `get_debug_mode() -> bool`
获取当前调试模式状态。

**返回：** 调试模式是否开启

---

## 设置文件

设置保存在 `user://settings.json`，内容示例：

```json
{
  "debug_mode": false
}
```

---

## 使用示例

### 在UI中绑定调试开关

```gdscript
@onready var debug_checkbox: CheckBox = $DebugCheckBox

func _ready():
    debug_checkbox.button_pressed = GameSettings.debug_mode
    debug_checkbox.toggled.connect(_on_debug_toggled)
    GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)

func _on_debug_toggled(enabled: bool):
    GameSettings.set_debug_mode(enabled)

func _on_debug_mode_changed(enabled: bool):
    debug_checkbox.button_pressed = enabled
```

### 在其他系统中监听调试模式变化

```gdscript
func _ready():
    debug_mode = GameSettings.debug_mode
    GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)

func _on_debug_mode_changed(enabled: bool):
    debug_mode = enabled
```

---

## 扩展设置项

后续可添加的设置项：

| 设置项 | 类型 | 说明 |
|--------|------|------|
| `master_volume` | `float` | 主音量 |
| `music_volume` | `float` | 音乐音量 |
| `sfx_volume` | `float` | 音效音量 |
| `language` | `String` | 语言 |
| `fullscreen` | `bool` | 全屏模式 |