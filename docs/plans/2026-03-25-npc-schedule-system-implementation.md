# NPC日程系统实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现NPC日程系统原型，验证时段+天数+章节+章节阶段的日程查询机制。

**Architecture:** 混合模式调度器架构 - NPCScheduler(Autoload)集中管理日程数据和状态计算，NPC实例负责显示和交互。使用Resource类存储日程数据，运行时构建索引加速查询。

**Tech Stack:** Godot 4.6+, GDScript, Resource类

---

## Task 1: 创建 NPCScheduleEntry Resource类

**Files:**
- Create: `systems/npc_schedule/npc_schedule_entry.gd`

**Step 1: 创建目录和文件**

```bash
mkdir -p systems/npc_schedule
```

**Step 2: 编写 NPCScheduleEntry 类**

```gdscript
# systems/npc_schedule/npc_schedule_entry.gd
class_name NPCScheduleEntry extends Resource

@export var npc_id: String = ""
@export var chapter: int = 0
@export var chapter_stage: String = ""
@export var day: int = 0
@export var period: String = ""
@export var location: String = ""
@export var state: String = "idle"
@export var visible: bool = true
```

**Step 3: 验证语法**

在Godot编辑器中打开项目，确认无语法错误。

---

## Task 2: 创建 NPCScheduleDatabase Resource类

**Files:**
- Create: `systems/npc_schedule/npc_schedule_database.gd`

**Step 1: 编写 NPCScheduleDatabase 类（骨架）**

```gdscript
# systems/npc_schedule/npc_schedule_database.gd
class_name NPCScheduleDatabase extends Resource

@export var entries: Array[NPCScheduleEntry] = []

var _index: Dictionary = {}
var _npc_ids: Array[String] = []

func build_index() -> void:
    _index.clear()
    _npc_ids.clear()
    
    for entry in entries:
        if entry.npc_id not in _npc_ids:
            _npc_ids.append(entry.npc_id)
        
        var key = _make_key(entry.chapter, entry.chapter_stage, entry.npc_id, entry.day, entry.period)
        _index[key] = entry

func _make_key(chapter: int, stage: String, npc_id: String, day: int, period: String) -> String:
    return "%d|%s|%s|%d|%s" % [chapter, stage, npc_id, day, period]

func get_entry(npc_id: String, chapter: int, stage: String, day: int, period: String) -> NPCScheduleEntry:
    # 精确匹配
    var exact_key = _make_key(chapter, stage, npc_id, day, period)
    if _index.has(exact_key):
        return _index[exact_key]
    
    # 通配符匹配（按优先级降级）
    var patterns = [
        _make_key(chapter, stage, npc_id, day, ""),      # period通配
        _make_key(chapter, stage, npc_id, 0, period),    # day通配
        _make_key(chapter, stage, npc_id, 0, ""),        # day+period通配
        _make_key(chapter, "", npc_id, day, period),     # stage通配
        _make_key(chapter, "", npc_id, day, ""),         # stage+period通配
        _make_key(chapter, "", npc_id, 0, period),       # stage+day通配
        _make_key(chapter, "", npc_id, 0, ""),           # stage+day+period通配
        _make_key(0, stage, npc_id, day, period),        # chapter通配
        _make_key(0, stage, npc_id, day, ""),            # chapter+period通配
        _make_key(0, stage, npc_id, 0, period),          # chapter+day通配
        _make_key(0, stage, npc_id, 0, ""),              # chapter+day+period通配
        _make_key(0, "", npc_id, day, period),           # chapter+stage通配
        _make_key(0, "", npc_id, day, ""),               # chapter+stage+period通配
        _make_key(0, "", npc_id, 0, period),             # chapter+stage+day通配
        _make_key(0, "", npc_id, 0, ""),                 # 全通配
    ]
    
    for pattern in patterns:
        if _index.has(pattern):
            return _index[pattern]
    
    return null

func get_all_npc_ids() -> Array[String]:
    return _npc_ids.duplicate()
```

**Step 2: 验证语法**

在Godot编辑器中确认无错误。

---

## Task 3: 扩展 GameState

**Files:**
- Modify: `systems/game_state/game_state.gd`

**Step 1: 添加章节属性**

```gdscript
# systems/game_state/game_state.gd
extends Node

var g_value: int = 0
var d_value: int = 0

# 新增：章节系统
var chapter: int = 1
var chapter_stage: String = ""

signal g_changed(new_value: int)
signal d_changed(new_value: int)
signal chapter_changed(new_chapter: int)
signal chapter_stage_changed(new_stage: String)

func add_g(amount: int) -> void:
    g_value = clampi(g_value + amount, 0, 120)
    g_changed.emit(g_value)

func add_d(amount: int) -> void:
    d_value = clampi(d_value + amount, 0, 120)
    d_changed.emit(d_value)

func set_chapter(new_chapter: int) -> void:
    chapter = new_chapter
    chapter_changed.emit(chapter)

func set_chapter_stage(new_stage: String) -> void:
    chapter_stage = new_stage
    chapter_stage_changed.emit(chapter_stage)
```

---

## Task 4: 创建 NPCScheduler Autoload

**Files:**
- Create: `systems/npc_schedule/npc_scheduler.gd`

**Step 1: 编写 NPCScheduler 类**

```gdscript
# systems/npc_schedule/npc_scheduler.gd
extends Node

signal npc_state_changed(npc_id: String, location: String, state: String, visible: bool)

var _database: NPCScheduleDatabase
var _current_states: Dictionary = {}

var debug_mode: bool = false

func _ready() -> void:
    debug_mode = GameSettings.debug_mode
    GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)
    _load_database()
    _connect_time_signals()
    _update_all_npc_states()

func _on_debug_mode_changed(enabled: bool) -> void:
    debug_mode = enabled

func _log(message: String) -> void:
    if debug_mode:
        print("[NPCScheduler] %s" % message)

func _load_database() -> void:
    var db_path = "res://data/npc_schedules.tres"
    if ResourceLoader.exists(db_path):
        _database = load(db_path)
        _database.build_index()
        _log("Database loaded, entries: %d, NPCs: %d" % [_database.entries.size(), _database.get_all_npc_ids().size()])
    else:
        _database = NPCScheduleDatabase.new()
        _log("Database not found, using empty database")

func _connect_time_signals() -> void:
    TimeSystem.period_changed.connect(_on_period_changed)
    TimeSystem.day_changed.connect(_on_day_changed)

func get_npc_state(npc_id: String) -> Dictionary:
    return _current_states.get(npc_id, {})

func get_all_npc_states() -> Dictionary:
    return _current_states.duplicate()

func _on_period_changed(new_period: String, is_weekend: bool) -> void:
    _log("Period changed: %s" % new_period)
    _update_all_npc_states()

func _on_day_changed(new_day: int, new_weekday: int) -> void:
    _log("Day changed: %d" % new_day)
    _update_all_npc_states()

func _update_all_npc_states() -> void:
    if not _database:
        return
    
    for npc_id in _database.get_all_npc_ids():
        var entry = _database.get_entry(
            npc_id,
            GameState.chapter,
            GameState.chapter_stage,
            TimeSystem.current_day,
            TimeSystem.current_period
        )
        
        if entry:
            _current_states[npc_id] = {
                "location": entry.location,
                "state": entry.state,
                "visible": entry.visible
            }
            npc_state_changed.emit(npc_id, entry.location, entry.state, entry.visible)
            _log("NPC %s: location=%s, state=%s, visible=%s" % [npc_id, entry.location, entry.state, entry.visible])
        else:
            _current_states[npc_id] = {
                "location": "unknown",
                "state": "idle",
                "visible": false
            }
            npc_state_changed.emit(npc_id, "unknown", "idle", false)
            _log("NPC %s: no matching entry, hidden" % npc_id)
```

---

## Task 5: 配置 Autoload

**Files:**
- Modify: `project.godot` (通过编辑器)

**Step 1: 在Godot编辑器中添加Autoload**

菜单: Project → Project Settings → Autoload

添加:
| 名称 | 路径 |
|------|------|
| NPCScheduler | res://systems/npc_schedule/npc_scheduler.gd |

确保加载顺序: GameSettings → TimeSystem → GameState → NPCScheduler

---

## Task 6: 创建原型NPC场景

**Files:**
- Create: `systems/npc_schedule/npc_prototype.tscn`
- Create: `systems/npc_schedule/npc_prototype.gd`

**Step 1: 编写 NPC 原型脚本**

```gdscript
# systems/npc_schedule/npc_prototype.gd
extends Control

@export var npc_id: String = ""
@export var npc_display_name: String = ""

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _location_label: Label = $VBoxContainer/LocationLabel
@onready var _state_label: Label = $VBoxContainer/StateLabel
@onready var _visible_label: Label = $VBoxContainer/VisibleLabel

func _ready() -> void:
    _name_label.text = "NPC: %s" % npc_display_name
    NPCScheduler.npc_state_changed.connect(_on_npc_state_changed)
    call_deferred("_update_display")

func _on_npc_state_changed(id: String, location: String, state: String, visible: bool) -> void:
    if id == npc_id:
        _update_display()

func _update_display() -> void:
    var state_data = NPCScheduler.get_npc_state(npc_id)
    
    if state_data.is_empty():
        _location_label.text = "位置: 未知"
        _state_label.text = "状态: 未知"
        _visible_label.text = "可见: 否"
        return
    
    _location_label.text = "位置: %s" % state_data.get("location", "未知")
    _state_label.text = "状态: %s" % state_data.get("state", "未知")
    _visible_label.text = "可见: %s" % ("是" if state_data.get("visible", true) else "否")
    visible = state_data.get("visible", true)

func _on_detail_button_pressed() -> void:
    var state_data = NPCScheduler.get_npc_state(npc_id)
    var info = """[%s] 详细状态:
章节: %d
阶段: %s
天数: %d
时段: %s
位置: %s
状态: %s
可见: %s""" % [
        npc_display_name,
        GameState.chapter,
        GameState.chapter_stage if GameState.chapter_stage != "" else "(默认)",
        TimeSystem.current_day,
        TimeSystem.get_period_name(),
        state_data.get("location", "未知"),
        state_data.get("state", "未知"),
        "是" if state_data.get("visible", true) else "否"
    ]
    print(info)
```

**Step 2: 创建 tscn 文件**

在Godot编辑器中:
1. 创建新场景，根节点为 Control
2. 添加 VBoxContainer 子节点
3. 添加 Label (NameLabel), Label (LocationLabel), Label (StateLabel), Label (VisibleLabel), Button
4. 附加 npc_prototype.gd 脚本
5. 连接 Button 的 pressed 信号到 _on_detail_button_pressed
6. 保存为 npc_prototype.tscn

---

## Task 7: 创建示例日程数据

**Files:**
- Create: `data/npc_schedules.tres`

**Step 1: 在Godot编辑器中创建Resource**

1. 右键 data 文件夹 → New Resource → NPCScheduleDatabase
2. 保存为 npc_schedules.tres
3. 在Inspector中添加entries数组

**Step 2: 添加示例条目**

在Inspector中添加以下条目（手动或通过脚本）:

```
# 肖迟日程
npc_id="xiao_chi", chapter=1, chapter_stage="", day=0, period="morning_class", location="classroom_302", state="sit", visible=true
npc_id="xiao_chi", chapter=1, chapter_stage="", day=0, period="break", location="classroom_302", state="stand", visible=true
npc_id="xiao_chi", chapter=1, chapter_stage="", day=0, period="lunch", location="canteen_1", state="stand", visible=true
npc_id="xiao_chi", chapter=1, chapter_stage="", day=0, period="after_school", location="playground", state="stand", visible=true
npc_id="xiao_chi", chapter=1, chapter_stage="", day=0, period="night", location="dorm_301", state="sit", visible=true

# 何景明日程
npc_id="he_jingming", chapter=1, chapter_stage="", day=0, period="morning_class", location="classroom_302", state="sit", visible=true
npc_id="he_jingming", chapter=1, chapter_stage="", day=0, period="lunch", location="canteen_2", state="stand", visible=true
npc_id="he_jingming", chapter=1, chapter_stage="", day=0, period="after_school", location="club_room", state="stand", visible=true
npc_id="he_jingming", chapter=1, chapter_stage="", day=0, period="night", location="dorm_302", state="sit", visible=true

# 林小婉日程
npc_id="lin_xiaowan", chapter=1, chapter_stage="", day=0, period="morning_class", location="classroom_302", state="sit", visible=true
npc_id="lin_xiaowan", chapter=1, chapter_stage="", day=0, period="lunch", location="library", state="sit", visible=true
npc_id="lin_xiaowan", chapter=1, chapter_stage="", day=0, period="after_school", location="classroom_302", state="sit", visible=true
npc_id="lin_xiaowan", chapter=1, chapter_stage="", day=0, period="night", location="dorm_303", state="sit", visible=true
# 特殊：第3天请假
npc_id="lin_xiaowan", chapter=1, chapter_stage="", day=3, period="", location="", state="", visible=false
```

---

## Task 8: 创建测试场景

**Files:**
- Create: `prototypes/npc_schedule_prototype.tscn`
- Create: `prototypes/npc_schedule_prototype.gd`

**Step 1: 编写测试场景脚本**

```gdscript
# prototypes/npc_schedule_prototype.gd
extends Node2D

@onready var _time_ui: Control = $TimeUI
@onready var _npc_container: VBoxContainer = $NPCContainer

func _ready() -> void:
    _setup_npcs()
    _setup_time_ui()

func _setup_npcs() -> void:
    var npc_prototype = preload("res://systems/npc_schedule/npc_prototype.tscn")
    
    var npcs = [
        {"id": "xiao_chi", "name": "肖迟"},
        {"id": "he_jingming", "name": "何景明"},
        {"id": "lin_xiaowan", "name": "林小婉"}
    ]
    
    for npc_data in npcs:
        var instance = npc_prototype.instantiate()
        instance.npc_id = npc_data["id"]
        instance.npc_display_name = npc_data["name"]
        _npc_container.add_child(instance)

func _setup_time_ui() -> void:
    # 复用现有时间UI
    pass

func _on_advance_period_button() -> void:
    TimeSystem.advance_period()

func _on_advance_day_button() -> void:
    TimeSystem.advance_day()

func _on_set_day_3_button() -> void:
    # 测试林小婉第3天请假
    TimeSystem.current_day = 3
    TimeSystem.day_changed.emit(3, TimeSystem.current_weekday)
```

**Step 2: 创建测试场景**

在Godot编辑器中:
1. 创建新场景，根节点为 Node2D
2. 添加 CanvasLayer 子节点
3. 在 CanvasLayer 下添加:
   - TimeUI (现有时间UI)
   - NPCContainer (VBoxContainer)
   - HBoxContainer 包含按钮: 推进时段, 推进天数, 设为第3天
4. 附加脚本并连接按钮信号
5. 保存为 npc_schedule_prototype.tscn

---

## Task 9: 验证功能

**Step 1: 运行测试场景**

在Godot编辑器中运行 npc_schedule_prototype.tscn

**Step 2: 验证点**

| 测试项 | 预期结果 |
|--------|----------|
| 初始状态 | 3个NPC显示正确位置 |
| 点击推进时段 | NPC位置更新，日志输出 |
| 点击推进天数 | NPC位置更新 |
| 设为第3天 | 林小婉消失(visible=false) |
| 控制台日志 | 显示调试信息 |

---

## Task 10: 编写API文档

**Files:**
- Create: `docs/api/NPCScheduler.md`

**Step 1: 编写文档**

```markdown
# NPCScheduler API 文档

NPC日程调度系统单例，管理所有NPC的位置和状态。

## 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| npc_state_changed | npc_id: String, location: String, state: String, visible: bool | NPC状态变化时触发 |

## 方法

### get_npc_state(npc_id: String) -> Dictionary

获取指定NPC的当前状态。

**参数：**
- npc_id: NPC唯一标识

**返回：**
```gdscript
{
    "location": String,  # 位置ID
    "state": String,     # 状态
    "visible": bool      # 是否可见
}
```

### get_all_npc_states() -> Dictionary

获取所有NPC的当前状态。

**返回：** npc_id -> state字典 的映射

## 依赖

- GameSettings (debug_mode)
- TimeSystem (period_changed, day_changed, current_day, current_period)
- GameState (chapter, chapter_stage)

## 日程数据格式

见 NPCScheduleDatabase 和 NPCScheduleEntry Resource类。
```

---

## Task 11: 更新玩法文档

**Files:**
- Modify: `docs/玩法文档.md` (2.3.2节)

**Step 1: 更新NPC日程数据格式说明**

将JSON格式改为Resource格式说明，保持与设计一致。

---

## 实现顺序总结

1. ✅ NPCScheduleEntry (Resource类)
2. ✅ NPCScheduleDatabase (Resource类)
3. ✅ GameState扩展
4. ✅ NPCScheduler (Autoload)
5. ✅ Autoload配置
6. ✅ npc_prototype场景
7. ✅ 示例日程数据
8. ✅ 测试场景
9. ✅ 功能验证
10. ✅ API文档
11. ✅ 玩法文档更新