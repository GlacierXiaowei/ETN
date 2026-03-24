# TimeSystem API 文档

时间系统单例，管理游戏时间、行动点和活动。

## 调试模式

| 属性 | 类型 | 说明 |
|------|------|------|
| `debug_mode` | `bool` | 是否输出调试日志（由 GameSettings 管理） |

调试模式由 `GameSettings` 单例管理，修改调试模式请使用：

```gdscript
GameSettings.set_debug_mode(true)   # 开启
GameSettings.set_debug_mode(false)  # 关闭
```

---

## 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| `period_changed` | `new_period: String, is_weekend: bool` | 时段变化时触发 |
| `day_changed` | `new_day: int, new_weekday: int` | 日期变化时触发 |
| `action_points_changed` | `new_points: int` | 行动点变化时触发 |
| `action_points_depleted` | 无 | 行动点耗尽时触发 |
| `activity_started` | `activity_id: String` | 活动开始时触发 |
| `activity_finished` | `activity_id: String` | 活动完成时触发 |
| `activity_cancelled` | `activity_id: String, refunded: bool` | 活动取消时触发 |

## 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `current_day` | `int` | 当前天数（从1开始） |
| `current_weekday` | `Weekday` | 当前星期（枚举） |
| `current_period` | `String` | 当前时段ID |
| `is_weekend` | `bool` | 是否周末 |
| `action_points` | `int` | 当前行动点 |
| `config` | `Dictionary` | 时间配置数据 |

## 枚举

```gdscript
enum Weekday { MON, TUE, WED, THU, FRI, SAT, SUN }
```

## 核心方法

### `get_period_name() -> String`
获取当前时段的中文名称。

**返回：** 时段名称，如"早读"、"大课间"

---

### `get_weekday_name() -> String`
获取当前星期的中文名称。

**返回：** 星期名称，如"周一"、"周六"

---

### `advance_period() -> void`
推进到下一个时段。如果是当天的最后时段，自动推进到下一天。

---

### `advance_day() -> void`
推进到下一天。自动更新星期、判断周末、重置时段。

---

## 即时行动

### `execute_action(action_id: String) -> bool`
执行即时行动（如发呆、吃饭），立即扣除行动点。

**参数：**
- `action_id`: 行动ID，如"idle"、"eat"

**返回：** 
- `true`: 执行成功
- `false`: 行动点不足或行动不存在

**行为：**
- 扣除行动点
- 行动点耗尽时自动推进时段

**示例：**
```gdscript
var success = TimeSystem.execute_action("idle")
if not success:
    print("行动点不足！")
```

---

## 活动系统

用于需要进入场景的活动（如图书馆、操场）。

### `start_activity(activity_id: String) -> bool`
开始一个活动，扣除行动点。

**参数：**
- `activity_id`: 活动ID，如"library"

**返回：**
- `true`: 开始成功
- `false`: 行动点不足或活动不存在

**行为：**
- 扣除行动点
- 设置 `is_activity_started = false`（可返还状态）
- 触发 `activity_started` 信号

**示例：**
```gdscript
func _on_library_button_pressed():
    if TimeSystem.start_activity("library"):
        get_tree().change_scene_to_file("res://scenes/library.tscn")
```

---

### `mark_activity_started() -> void`
标记活动已开始交互。调用后，取消活动将不再返还行动点。

**调用时机：** 玩家在活动场景中第一次交互时

**示例：**
```gdscript
# 图书馆场景
func _on_book_clicked():
    TimeSystem.mark_activity_started()  # 开始探索，不能退款了
    show_book_content()
```

---

### `finish_activity() -> void`
完成当前活动。

**行为：**
- 触发 `activity_finished` 信号
- 清除活动状态
- 如果行动点耗尽，自动推进时段

**示例：**
```gdscript
func _on_leave_library():
    TimeSystem.finish_activity()
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

---

### `cancel_activity() -> bool`
取消当前活动，返回上一场景。

**返回：**
- `true`: 返还了行动点
- `false`: 未返还行动点（活动已开始）

**行为：**
- 如果 `is_activity_started == false`：返还行动点
- 如果 `is_activity_started == true`：不返还
- 触发 `activity_cancelled` 信号

**示例：**
```gdscript
func _on_exit_button():
    var refunded = TimeSystem.cancel_activity()
    if refunded:
        show_message("离开了，行动点已返还")
    else:
        show_message("离开了")
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

---

### `is_in_activity() -> bool`
检查是否正在活动中。

**返回：** `true` 如果当前有活动

---

### `can_refund_activity() -> bool`
检查当前活动是否可以返还行动点。

**返回：** `true` 如果活动未开始交互

**用途：** 在离开按钮上显示提示

**示例：**
```gdscript
func _on_exit_hover():
    if TimeSystem.can_refund_activity():
        tooltip.text = "离开将返还行动点"
    else:
        tooltip.text = "离开将不会返还行动点"
```

---

## 完整使用示例

### 场景：图书馆

```gdscript
extends Node2D

func _ready():
    # 活动已在进入场景时扣点
    pass

func _on_first_book_clicked():
    # 玩家开始探索
    TimeSystem.mark_activity_started()

func _on_exit_button():
    if TimeSystem.can_refund_activity():
        # 弹窗确认
        $ConfirmDialog.show()
    else:
        _leave_scene()

func _on_confirm_leave():
    TimeSystem.cancel_activity()
    _leave_scene()

func _on_finish_exploring():
    # 找到所有道具
    TimeSystem.finish_activity()
    _leave_scene()

func _leave_scene():
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

---

## 配置格式 (time_config.json)

```json
{
  "periods": {
    "weekday": [...],
    "weekend": [...]
  },
  "actions": [
    { "id": "idle", "name": "发呆", "cost": 1, "type": "instant" },
    { "id": "library", "name": "去图书馆", "cost": 1, "type": "scene", "scene": "res://scenes/library.tscn" }
  ]
}
```

**行动类型：**
- `instant`: 即时行动，调用 `execute_action()`
- `scene`: 场景活动，调用 `start_activity()` / `finish_activity()`