# NPC日程系统设计文档

> 创建日期：2026-03-25
> 状态：待审批

---

## 1. 概述

### 1.1 设计目标

实现NPC日程系统原型，验证核心机制：
- 时段+天数+章节+章节阶段的日程查询
- 混合模式调度器架构
- Resource数据存储（可视化编辑友好）

### 1.2 原型范围

| 包含 | 不包含 |
|------|--------|
| 日程数据结构设计 | NPC导航移动 |
| 调度器单例 | NPC动画系统 |
| 原型NPC场景（2-3个） | 完整交互系统 |
| 与TimeSystem/GameState集成 | 存档系统联动 |

---

## 2. 系统架构

### 2.1 架构图

```
┌────────────────────────────────────────────────────────────┐
│                    TimeSystem (已有)                        │
│  signal period_changed, day_changed                        │
└────────────────────────────────────────────────────────────┘
                            │ 信号
                            ▼
┌────────────────────────────────────────────────────────────┐
│                 NPCScheduler (新增 Autoload)               │
│  - 持有 NPCScheduleDatabase (Resource)                     │
│  - 监听时间信号，计算所有NPC位置/状态                        │
│  - 缓存当前帧所有NPC状态                                    │
│  - 信号: npc_state_changed(npc_id, location, state)        │
│  - 接口: get_npc_state(npc_id) -> Dictionary               │
└────────────────────────────────────────────────────────────┘
                            │ 信号
                            ▼
┌────────────────────────────────────────────────────────────┐
│                     NPC实例 (场景节点)                       │
│  - 持有 npc_id: String                                      │
│  - 监听 npc_state_changed 更新显示                          │
│  - 提供交互：点击显示日程状态                                │
└────────────────────────────────────────────────────────────┘
```

### 2.2 目录结构

```
res://
├── systems/
│   └── npc_schedule/
│       ├── npc_scheduler.gd          # Autoload单例
│       ├── npc_schedule_entry.gd     # Resource类：日程条目
│       ├── npc_schedule_database.gd  # Resource类：日程数据库
│       └── npc_prototype.tscn/gd     # 原型NPC场景
├── data/
│   └── npc_schedules.tres            # 日程数据库资源
└── prototypes/
    └── npc_schedule_prototype.tscn   # 测试场景
```

### 2.3 Autoload配置

| 顺序 | 名称 | 脚本路径 | 说明 |
|------|------|----------|------|
| 1 | GameSettings | systems/game_settings/game_settings.gd | 全局设置 |
| 2 | TimeSystem | systems/time_system/time_system.gd | 时间系统 |
| 3 | GameState | systems/game_state/game_state.gd | 游戏状态 |
| 4 | NPCScheduler | systems/npc_schedule/npc_scheduler.gd | NPC调度器 |

---

## 3. 数据结构设计

### 3.1 NPCScheduleEntry (Resource)

单条日程数据。

```gdscript
# npc_schedule_entry.gd
class_name NPCScheduleEntry extends Resource

@export var npc_id: String = ""           # NPC唯一标识
@export var chapter: int = 0              # 章节，0=全章节通用
@export var chapter_stage: String = ""    # 章节阶段，空=全阶段通用
@export var day: int = 0                  # 天数，0=任意天
@export var period: String = ""           # 时段ID，空=全时段
@export var location: String = ""         # 位置ID
@export var state: String = "idle"        # NPC状态（idle/sit/stand等）
@export var visible: bool = true          # 是否可见，false=NPC消失
```

### 3.2 NPCScheduleDatabase (Resource)

日程数据库，包含所有NPC的日程条目。

```gdscript
# npc_schedule_database.gd
class_name NPCScheduleDatabase extends Resource

@export var entries: Array[NPCScheduleEntry] = []

var _index: Dictionary = {}  # 运行时索引

func build_index() -> void:
    # 构建嵌套索引: chapter -> stage -> npc_id -> day -> period -> entry
    pass

func get_entry(npc_id: String, chapter: int, stage: String, day: int, period: String) -> NPCScheduleEntry:
    # 按优先级查询：精确匹配 > 通配符匹配
    pass

func get_all_npc_ids() -> Array[String]:
    # 获取所有NPC ID列表
    pass
```

### 3.3 查询优先级

当多条目匹配时，按以下优先级选择（精确匹配优先）：

| 优先级 | 字段 | 精确值 | 通配符 |
|--------|------|--------|--------|
| 1 | chapter | 指定章节 | 0 |
| 2 | chapter_stage | 指定阶段 | 空字符串 |
| 3 | day | 指定天数 | 0 |
| 4 | period | 指定时段 | 空字符串 |

**示例：**

```
条目1: { npc_id="xiao_chi", chapter=1, stage="after_meeting", day=3, period="lunch", location="rooftop" }
条目2: { npc_id="xiao_chi", chapter=1, stage="", day=0, period="lunch", location="canteen" }

查询条件: chapter=1, stage="after_meeting", day=3, period="lunch"
结果: 匹配条目1，location="rooftop"（更精确）

查询条件: chapter=1, stage="", day=5, period="lunch"
结果: 匹配条目2，location="canteen"（条目1的stage不匹配）
```

---

## 4. NPCScheduler (Autoload)

### 4.1 核心职责

- 加载并持有 NPCScheduleDatabase
- 监听 TimeSystem 的时间变化信号
- 计算并缓存所有NPC的当前状态
- 提供 NPC 状态查询接口
- 发射状态变化信号供 NPC 实例监听

### 4.2 API设计

```gdscript
# npc_scheduler.gd
extends Node

signal npc_state_changed(npc_id: String, location: String, state: String, visible: bool)

var _database: NPCScheduleDatabase
var _current_states: Dictionary = {}  # npc_id -> {location, state, visible}

func _ready() -> void:
    _load_database()
    _connect_time_signals()
    _update_all_npc_states()

func get_npc_state(npc_id: String) -> Dictionary:
    # 返回 { "location": String, "state": String, "visible": bool }
    pass

func get_all_npc_states() -> Dictionary:
    # 返回所有NPC状态
    pass

func _on_period_changed(new_period: String, is_weekend: bool) -> void:
    _update_all_npc_states()

func _on_day_changed(new_day: int, new_weekday: int) -> void:
    _update_all_npc_states()

func _update_all_npc_states() -> void:
    # 遍历所有NPC，查询并更新状态
    pass
```

---

## 5. GameState扩展

需要扩展 GameState 添加章节相关属性：

```gdscript
# game_state.gd (修改)
extends Node

var g_value: int = 0
var d_value: int = 0

# 新增
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

# 新增方法
func set_chapter(new_chapter: int) -> void:
    chapter = new_chapter
    chapter_changed.emit(chapter)

func set_chapter_stage(new_stage: String) -> void:
    chapter_stage = new_stage
    chapter_stage_changed.emit(chapter_stage)
```

---

## 6. 原型NPC场景

### 6.1 场景结构

```
npc_prototype.tscn
├── Node2D (根节点)
│   ├── Label (NPC名称)
│   ├── Label (当前位置)
│   ├── Label (当前状态)
│   └── Button (查看详情按钮)
```

### 6.2 脚本

```gdscript
# npc_prototype.gd
extends Node2D

@export var npc_id: String = ""
@export var npc_name: String = ""

@onready var _name_label: Label = $NameLabel
@onready var _location_label: Label = $LocationLabel
@onready var _state_label: Label = $StateLabel

func _ready() -> void:
    _name_label.text = npc_name
    NPCScheduler.npc_state_changed.connect(_on_npc_state_changed)
    _update_display()

func _on_npc_state_changed(id: String, location: String, state: String, visible: bool) -> void:
    if id == npc_id:
        _update_display()

func _update_display() -> void:
    var state_data = NPCScheduler.get_npc_state(npc_id)
    if state_data.is_empty():
        _location_label.text = "未知"
        _state_label.text = "未知"
        return
    
    _location_label.text = state_data.get("location", "未知")
    _state_label.text = state_data.get("state", "未知")
    visible = state_data.get("visible", true)

func _on_detail_button_pressed() -> void:
    # 显示详细状态弹窗
    var state_data = NPCScheduler.get_npc_state(npc_id)
    var info = "%s 当前状态:\n位置: %s\n状态: %s" % [
        npc_name,
        state_data.get("location", "未知"),
        state_data.get("state", "未知")
    ]
    print(info)
```

---

## 7. 示例日程数据

### 7.1 npc_schedules.tres 示例内容

创建3个NPC的示例日程：

**NPC: xiao_chi (肖迟)**
- 章节1，任意天，早读 → 教室，坐着
- 章节1，任意天，午休 → 食堂
- 章节1，stage="after_rooftop"，任意天，放学后 → 天台
- 章节1，任意天，夜间 → 寝室

**NPC: he_jingming (何景明)**
- 章节1，任意天，早读 → 教室
- 章节1，周一/周三(通过day%7)，放学后 → 社团
- 章节1，任意天，夜间 → 寝室

**NPC: lin_xiaowan (林小婉)**
- 章节1，day=3，全时段 → 不出现（请假）
- 章节1，任意天，午休 → 图书馆
- 章节1，任意天，放学后 → 教室

---

## 8. 与现有系统集成

### 8.1 TimeSystem集成

| TimeSystem信号 | NPCScheduler响应 |
|----------------|------------------|
| period_changed | 重新计算所有NPC状态 |
| day_changed | 重新计算所有NPC状态 |

### 8.2 GameState集成

| GameState属性 | 用途 |
|---------------|------|
| chapter | 日程查询条件 |
| chapter_stage | 日程查询条件 |

---

## 9. 实现检查清单

- [ ] 创建 NPCScheduleEntry Resource类
- [ ] 创建 NPCScheduleDatabase Resource类
- [ ] 实现 build_index() 方法
- [ ] 实现 get_entry() 查询方法（含优先级逻辑）
- [ ] 创建 NPCScheduler Autoload
- [ ] 扩展 GameState（添加chapter/chapter_stage）
- [ ] 创建 npc_prototype.tscn/gd
- [ ] 创建测试日程数据 npc_schedules.tres
- [ ] 创建测试场景 npc_schedule_prototype.tscn
- [ ] 验证时间变化时NPC状态更新
- [ ] 编写 API 文档

---

## 10. 后续扩展

原型验证后需要扩展的功能：

| 功能 | 说明 | 优先级 |
|------|------|--------|
| NPC导航移动 | NavigationAgent3D 自动寻路 | 高 |
| NPC动画 | 坐/站/走动画切换 | 高 |
| 对话集成 | 点击NPC触发对话 | 高 |
| 存档系统联动 | 保存NPC状态 | 中 |
| 性能优化 | 场景切换时卸载远处NPC | 中 |