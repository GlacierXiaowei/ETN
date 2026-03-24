# 时间系统原型实现计划

> **状态：已完成 ✓**

**Goal:** 在Godot中实现时间系统原型，验证时段切换、行动点消耗、时间信号核心机制。

**Architecture:** 采用Autoload单例管理时间状态，信号系统驱动UI和NPC响应，JSON配置数据驱动时段和行动配置。

**Tech Stack:** Godot 4.6/4.7, GDScript, JSON配置

---

## 前置条件

- [x] 用户已在Godot中创建项目
- [x] 用户已切换到dev分支

---

## Task 1: 创建项目目录结构

**Files:**
- Create: `systems/time_system/` 目录
- Create: `systems/game_state/` 目录
- Create: `prototypes/` 目录
- Create: `data/` 目录

**Step 1: 在Godot编辑器中创建目录**

在Godot的FileSystem面板中，右键 `res://` → New Folder，创建以下目录结构：

```
res://
├── systems/
│   ├── time_system/
│   └── game_state/
├── prototypes/
└── data/
```

**Step 2: 验证目录创建**

在Godot FileSystem面板中确认目录结构正确。

---

## Task 2: 创建时间配置数据

**Files:**
- Create: `data/time_config.json`

**Step 1: 创建JSON文件**

在Godot中右键 `data/` → New Resource → 选择 TextFile，命名为 `time_config.json`，填入以下内容：

```json
{
  "periods": {
    "weekday": [
      { "id": "morning_class", "name": "早读", "action_points": 0 },
      { "id": "break", "name": "大课间", "action_points": 1 },
      { "id": "lunch", "name": "午休", "action_points_random": [1, 2] },
      { "id": "after_school", "name": "放学后", "action_points_random": [1, 2] },
      { "id": "night", "name": "夜间", "action_points": 2 }
    ],
    "weekend": [
      { "id": "morning", "name": "上午", "action_points": 3 },
      { "id": "afternoon", "name": "下午", "action_points": 3 },
      { "id": "night", "name": "夜间", "action_points": 3 }
    ]
  },
  "weekday_names": ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
  "actions": [
    { "id": "idle", "name": "发呆", "cost": 1 },
    { "id": "rest", "name": "休息", "cost": 1 },
    { "id": "study", "name": "学习", "cost": 1 },
    { "id": "eat", "name": "吃饭", "cost": 0 },
    { "id": "social", "name": "社交", "cost": 2 }
  ]
}
```

**Step 2: 保存文件**

Ctrl+S 保存。

---

## Task 3: 实现TimeSystem单例

**Files:**
- Create: `systems/time_system/time_system.gd`

**Step 1: 创建脚本文件**

右键 `systems/time_system/` → New Script，命名为 `time_system.gd`。

**Step 2: 编写TimeSystem核心代码**

```gdscript
extends Node

# 信号
signal period_changed(new_period: String, is_weekend: bool)
signal day_changed(new_day: int, new_weekday: int)
signal action_points_changed(new_points: int)
signal action_points_depleted()

# 枚举
enum Weekday { MON, TUE, WED, THU, FRI, SAT, SUN }

# 时间状态
var current_day: int = 1
var current_weekday: Weekday = Weekday.MON
var current_period: String = "morning_class"
var is_weekend: bool = false

# 行动点
var action_points: int = 0

# 配置数据
var config: Dictionary = {}

# 时段顺序
var weekday_periods: Array[String] = ["morning_class", "break", "lunch", "after_school", "night"]
var weekend_periods: Array[String] = ["morning", "afternoon", "night"]

func _ready() -> void:
    load_config()
    init_time()

func load_config() -> void:
    var file = FileAccess.open("res://data/time_config.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        json.parse(file.get_as_text())
        config = json.data

func init_time() -> void:
    current_day = 1
    current_weekday = Weekday.MON
    is_weekend = false
    current_period = "morning_class"
    update_action_points()

func get_period_name() -> String:
    var periods = config.periods.weekday if not is_weekend else config.periods.weekend
    for p in periods:
        if p.id == current_period:
            return p.name
    return current_period

func get_weekday_name() -> String:
    return config.weekday_names[current_weekday]

func update_action_points() -> void:
    var periods = config.periods.weekday if not is_weekend else config.periods.weekend
    for p in periods:
        if p.id == current_period:
            if p.has("action_points"):
                action_points = p.action_points
            elif p.has("action_points_random"):
                action_points = p.action_points_random[randi() % 2]
            break
    action_points_changed.emit(action_points)

func execute_action(action_id: String) -> bool:
    for action in config.actions:
        if action.id == action_id:
            if action_points >= action.cost:
                action_points -= action.cost
                action_points_changed.emit(action_points)
                
                if action_points <= 0:
                    action_points_depleted.emit()
                    advance_period()
                return true
            else:
                return false
    return false

func advance_period() -> void:
    var periods = weekday_periods if not is_weekend else weekend_periods
    var current_index = periods.find(current_period)
    
    if current_index < periods.size() - 1:
        current_period = periods[current_index + 1]
    else:
        advance_day()
        return
    
    update_action_points()
    period_changed.emit(current_period, is_weekend)

func advance_day() -> void:
    current_day += 1
    current_weekday = (current_weekday + 1) % 7
    
    if current_weekday >= Weekday.SAT:
        is_weekend = true
    else:
        is_weekend = false
    
    current_period = weekend_periods[0] if is_weekend else weekday_periods[0]
    
    day_changed.emit(current_day, current_weekday)
    update_action_points()
    period_changed.emit(current_period, is_weekend)
```

**Step 3: 配置Autoload**

在Godot中：Project → Project Settings → Autoload → 点击文件夹图标选择 `time_system.gd` → Name填写 `TimeSystem` → Add。

---

## Task 4: 实现GameState单例

**Files:**
- Create: `systems/game_state/game_state.gd`

**Step 1: 创建脚本文件**

右键 `systems/game_state/` → New Script，命名为 `game_state.gd`。

**Step 2: 编写GameState代码**

```gdscript
extends Node

# 预留：情绪值、好感度等
var g_value: int = 0
var d_value: int = 0

signal g_changed(new_value: int)
signal d_changed(new_value: int)

func add_g(amount: int) -> void:
    g_value = clampi(g_value + amount, 0, 120)
    g_changed.emit(g_value)

func add_d(amount: int) -> void:
    d_value = clampi(d_value + amount, 0, 120)
    d_changed.emit(d_value)
```

**Step 3: 配置Autoload**

Project → Project Settings → Autoload → 添加 `game_state.gd`，Name为 `GameState`。

---

## Task 5: 创建TimeUI组件

**Files:**
- Create: `systems/time_system/time_ui.tscn`
- Create: `systems/time_system/time_ui.gd`

**Step 1: 创建场景**

右键 `systems/time_system/` → New Scene → 选择 User Interface，命名为 `time_ui`。

**Step 2: 设置场景节点**

场景根节点改为 `MarginContainer`，添加以下子节点：

```
MarginContainer (time_ui)
└── VBoxContainer
    ├── HBoxContainer (时间信息)
    │   ├── Label (day_label)
    │   ├── Label (weekday_label)
    │   └── Label (period_label)
    └── HBoxContainer (行动点)
        ├── Label (points_label)
        └── Label (points_text)
```

**Step 3: 创建脚本并绑定**

右键根节点 → Attach Script，保存为 `time_ui.gd`。

**Step 4: 编写UI脚本**

```gdscript
extends MarginContainer

@onready var day_label: Label = $VBoxContainer/HBoxContainer/day_label
@onready var weekday_label: Label = $VBoxContainer/HBoxContainer/weekday_label
@onready var period_label: Label = $VBoxContainer/HBoxContainer/period_label
@onready var points_label: Label = $VBoxContainer/HBoxContainer2/points_label
@onready var points_text: Label = $VBoxContainer/HBoxContainer2/points_text

func _ready() -> void:
    TimeSystem.period_changed.connect(_on_period_changed)
    TimeSystem.day_changed.connect(_on_day_changed)
    TimeSystem.action_points_changed.connect(_on_action_points_changed)
    update_display()

func update_display() -> void:
    day_label.text = "第" + str(TimeSystem.current_day) + "天"
    weekday_label.text = TimeSystem.get_weekday_name()
    period_label.text = TimeSystem.get_period_name()
    points_label.text = "行动点: "
    points_text.text = str(TimeSystem.action_points)

func _on_period_changed(_period: String, _is_weekend: bool) -> void:
    update_display()

func _on_day_changed(_day: int, _weekday: int) -> void:
    update_display()

func _on_action_points_changed(_points: int) -> void:
    points_text.text = str(_points)
```

**Step 5: 保存场景**

Ctrl+S 保存。

---

## Task 6: 创建ActionButton组件

**Files:**
- Create: `systems/time_system/action_button.tscn`
- Create: `systems/time_system/action_button.gd`

**Step 1: 创建场景**

右键 `systems/time_system/` → New Scene → User Interface，根节点改为 `Button`，命名为 `action_button`。

**Step 2: 创建脚本**

```gdscript
extends Button

@export var action_id: String = ""
@export var action_name: String = ""
@export var action_cost: int = 1

signal action_pressed(action_id: String)

func _ready() -> void:
    text = action_name + " (" + str(action_cost) + "点)"
    TimeSystem.action_points_changed.connect(_on_action_points_changed)
    update_state()

func _on_action_points_changed(points: int) -> void:
    update_state()

func update_state() -> void:
    disabled = TimeSystem.action_points < action_cost

func _on_pressed() -> void:
    action_pressed.emit(action_id)
```

**Step 3: 连接pressed信号**

在编辑器中，选择Button节点 → Node面板 → Signals → 双击 `pressed` → 连接到 `_on_pressed` 方法。

---

## Task 7: 创建简易NPC组件

**Files:**
- Create: `systems/time_system/simple_npc.tscn`
- Create: `systems/time_system/simple_npc.gd`

**Step 1: 创建场景**

右键 `systems/time_system/` → New Scene → User Interface，根节点改为 `HBoxContainer`，命名为 `simple_npc`。

**Step 2: 添加子节点**

```
HBoxContainer (simple_npc)
├── Label (name_label)
└── Label (location_label)
```

**Step 3: 创建脚本**

```gdscript
extends HBoxContainer

@export var npc_name: String = "小明"
var current_location: String = "教室"

@onready var name_label: Label = $name_label
@onready var location_label: Label = $location_label

func _ready() -> void:
    name_label.text = npc_name + ": "
    location_label.text = current_location
    TimeSystem.period_changed.connect(_on_period_changed)

func _on_period_changed(new_period: String, _is_weekend: bool) -> void:
    match new_period:
        "lunch":
            current_location = "食堂"
        "after_school":
            current_location = "操场"
        "night":
            current_location = "寝室"
        _:
            current_location = "教室"
    location_label.text = current_location
```

---

## Task 8: 创建原型主场景

**Files:**
- Create: `prototypes/time_prototype.tscn`
- Create: `prototypes/time_prototype.gd`

**Step 1: 创建场景**

右键 `prototypes/` → New Scene → User Interface，根节点改为 `VBoxContainer`，命名为 `time_prototype`。

**Step 2: 设置节点结构**

```
VBoxContainer (time_prototype)
├── MarginContainer
│   └── TimeUI (实例化time_ui.tscn)
├── HSeparator
├── VBoxContainer (NPC区域)
│   └── SimpleNPC (实例化simple_npc.tscn)
├── HSeparator
├── GridContainer (行动按钮区域)
│   ├── ActionButton (发呆)
│   ├── ActionButton (休息)
│   ├── ActionButton (学习)
│   ├── ActionButton (吃饭)
│   └── ActionButton (社交)
└── HSeparator
    └── Label (调试信息)
```

**Step 3: 创建主场景脚本**

```gdscript
extends VBoxContainer

@onready var action_container: GridContainer = $GridContainer

func _ready() -> void:
    setup_action_buttons()

func setup_action_buttons() -> void:
    var actions = TimeSystem.config.actions
    for child in action_container.get_children():
        child.queue_free()
    
    for action in actions:
        var btn = preload("res://systems/time_system/action_button.tscn").instantiate()
        btn.action_id = action.id
        btn.action_name = action.name
        btn.action_cost = action.cost
        btn.action_pressed.connect(_on_action_pressed)
        action_container.add_child(btn)

func _on_action_pressed(action_id: String) -> void:
    var success = TimeSystem.execute_action(action_id)
    if not success:
        print("行动点不足！")
```

**Step 4: 设置为主场景**

右键 `time_prototype.tscn` → Set as Main Scene。

**Step 5: 运行测试**

按F5运行，验证：
- 时间显示正确
- 点击按钮消耗行动点
- 行动点耗尽后推进时段
- NPC位置随时间变化

---

## Task 9: 验证核心机制

**Step 1: 运行原型**

按F5运行游戏。

**Step 2: 测试行动点消耗**

- 点击"发呆"按钮，观察行动点减少
- 点击"社交"按钮（消耗2点），观察行动点变化

**Step 3: 测试时段推进**

- 持续点击行动按钮直到行动点耗尽
- 观察时段是否自动推进

**Step 4: 测试日期推进**

- 持续推进时段，观察天数和星期变化
- 验证周末切换是否正确

**Step 5: 测试NPC响应**

- 观察NPC位置是否随时段变化

---

## 完成检查

- [x] TimeSystem单例正常工作
- [x] 时间显示正确
- [x] 行动点消耗正确
- [x] 时段推进正确
- [x] 日期推进正确
- [x] NPC位置响应正确
- [x] 行动点耗尽后自动推进时段
- [x] 活动系统正常工作
- [x] 调试模式开关
- [x] 配置加载错误处理

---

## 后续扩展

原型验证通过后：
1. 添加更多NPC
2. 添加完整NPC日程配置
3. 集成情绪系统
4. 添加UI美化
5. 集成存档系统