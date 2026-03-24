# 时间系统原型技术设计文档

> 创建日期：2026-03-24
> 状态：已完成 ✓

---

## 1. 概述

### 1.1 原型目标

验证时间系统核心机制：
- 时段切换逻辑
- 行动点消耗与推进
- 时间信号系统
- NPC响应时间变化

### 1.2 原型范围

| 包含 | 不包含 |
|------|--------|
| 时间状态管理 | 伪3D场景渲染 |
| 行动点系统 | 完整NPC日程 |
| 信号系统 | 存档系统 |
| 简易UI | 音效动画 |
| 简易NPC展示 | 任务系统联动 |

---

## 2. 系统架构

### 2.1 目录结构

```
res://
├── systems/
│   ├── time_system/
│   │   ├── time_system.gd          # Autoload单例
│   │   ├── time_ui.tscn            # 时间显示UI场景
│   │   ├── time_ui.gd              # 时间显示UI脚本
│   │   ├── action_button.tscn      # 行动按钮场景
│   │   └── action_button.gd        # 行动按钮脚本
│   └── game_state/
│       └── game_state.gd           # Autoload单例
├── prototypes/
│   ├── time_prototype.tscn         # 时间原型场景
│   └── time_prototype.gd           # 时间原型脚本
├── data/
│   └── time_config.json            # 时间配置
└── assets/
    └── fonts/
        └── 中文12像素.ttf
```

### 2.2 Autoload配置

| 名称 | 脚本路径 | 说明 |
|------|----------|------|
| TimeSystem | systems/time_system/time_system.gd | 时间状态管理 |
| GameState | systems/game_state/game_state.gd | 游戏状态管理 |

---

## 3. 时间状态设计

### 3.1 时段定义

```gdscript
# 周内时段（5个）
enum WeekdayPeriod { MORNING_CLASS, BREAK, LUNCH, AFTER_SCHOOL, NIGHT }

# 周末时段（3个）
enum WeekendPeriod { MORNING, AFTERNOON, NIGHT }

# 星期
enum Weekday { MON, TUE, WED, THU, FRI, SAT, SUN }
```

### 3.2 时间数据结构

```gdscript
var current_day: int = 1          # 第几天（从1开始）
var current_weekday: Weekday      # 星期几
var current_period                # 当前时段
var is_weekend: bool              # 是否周末
```

### 3.3 时段推进规则

**周内推进顺序**：
```
早读 → 上课(大课间) → 午休 → 放学后 → 夜间 → (次日早读)
```

**周末推进顺序**：
```
上午 → 下午 → 夜间 → (次日或周一)
```

---

## 4. 行动点系统设计

### 4.1 行动点分配

| 时段 | 行动点 | 备注 |
|------|--------|------|
| 早读 | 0 | 强制，无行动点 |
| 上课（大课间） | 1 | 固定 |
| 午休 | 1-2 | 随机 |
| 放学后 | 1-2 | 随机 |
| 夜间 | 2 | 固定 |
| 周末上午 | 3 | 固定 |
| 周末下午 | 3 | 固定 |
| 周末夜间 | 3 | 固定 |

### 4.2 行动点数据

```gdscript
var action_points: int = 0
var max_action_points: int = 5  # 每时段上限
```

### 4.3 行动消耗逻辑

```gdscript
func execute_action(cost: int) -> bool:
    if action_points < cost:
        return false  # 行动点不足
    action_points -= cost
    action_points_changed.emit(action_points)
    
    if action_points <= 0:
        advance_period()  # 推进时段
    return true
```

### 4.4 行动点恢复

- 时段切换时恢复该时段对应的行动点
- 新的一天重置行动点

---

## 5. 时间信号系统

### 5.1 信号定义

```gdscript
signal period_changed(new_period, is_weekend)
signal day_changed(new_day, new_weekday)
signal action_points_changed(new_points)
signal action_points_depleted()
```

### 5.2 订阅模式

```gdscript
# NPC或其他系统订阅时间变化
func _ready():
    TimeSystem.period_changed.connect(_on_period_change)

func _on_period_change(new_period, is_weekend):
    update_position(new_period)
```

---

## 6. 行动配置

### 6.1 行动类型

| 行动ID | 名称 | 消耗 |
|--------|------|------|
| idle | 发呆 | 1 |
| rest | 休息 | 1 |
| study | 学习 | 1 |
| eat | 吃饭 | 0 |
| social | 社交 | 2 |

---

## 7. UI界面设计

### 7.1 时间显示组件

```
┌─────────────────────────────────┐
│  第3天  周二  午休              │
│  行动点: ●●○  (2/2)             │
└─────────────────────────────────┘
```

### 7.2 原型界面布局

```
┌────────────────────────────────────────┐
│  [时间显示区域]                         │
├────────────────────────────────────────┤
│  [NPC状态区域]                          │
│  小明: 教室                             │
├────────────────────────────────────────┤
│  [行动按钮区域]                         │
│  [发呆] [休息] [学习] [吃饭] [社交]      │
├────────────────────────────────────────┤
│  [调试信息]                             │
└────────────────────────────────────────┘
```

---

## 8. 配置数据

### 8.1 time_config.json

```json
{
  "periods": {
    "weekday": [
      { "id": "morning_class", "name": "早读", "action_points": 0 },
      { "id": "break", "name": "大课间", "action_points": 1 },
      { "id": "lunch", "name": "午休", "action_points": [1, 2] },
      { "id": "after_school", "name": "放学后", "action_points": [1, 2] },
      { "id": "night", "name": "夜间", "action_points": 2 }
    ],
    "weekend": [
      { "id": "morning", "name": "上午", "action_points": 3 },
      { "id": "afternoon", "name": "下午", "action_points": 3 },
      { "id": "night", "name": "夜间", "action_points": 3 }
    ]
  },
  "weekday_names": ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
}
```

### 8.2 actions.json

```json
{
  "actions": [
    { "id": "idle", "name": "发呆", "cost": 1 },
    { "id": "rest", "name": "休息", "cost": 1 },
    { "id": "study", "name": "学习", "cost": 1 },
    { "id": "eat", "name": "吃饭", "cost": 0 },
    { "id": "social", "name": "社交", "cost": 2 }
  ]
}
```

---

## 9. 简易NPC设计

### 9.1 NPC时间响应

```gdscript
extends Node

@export var npc_name: String = "小明"
var current_location: String = "教室"

func _ready():
    TimeSystem.period_changed.connect(_on_period_change)

func _on_period_change(new_period, is_weekend):
    match new_period:
        "lunch":
            current_location = "食堂"
        "after_school":
            current_location = "操场"
        "night":
            current_location = "寝室"
        _:
            current_location = "教室"
```

---

## 10. 后续扩展

原型验证后需要扩展的功能：

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 完整NPC日程系统 | 天数+时段+章节的日程配置 | 高 |
| 任务系统联动 | 任务完成影响时间/NPC | 高 |
| 存档系统 | 保存时间状态 | 高 |
| 章节系统 | 提前完成→章节提前结束 | 中 |
| UI动画效果 | 像素风、过渡动画 | 低 |

---

## 12. 活动系统设计（新增）

### 12.1 活动流程

```
点击活动按钮 → start_activity() → 进入场景 → mark_activity_started() → 完成探索 → finish_activity()
                    ↓
               扣除行动点
                    ↓
            is_activity_started = false
                    ↓
              可取消并返还点数
```

### 12.2 活动状态

| 状态 | 说明 | 取消返还 |
|------|------|----------|
| 进入场景后 | `is_activity_started = false` | ✓ 返还 |
| 第一次交互后 | `is_activity_started = true` | ✗ 不返还 |

### 12.3 API

- `start_activity(activity_id)` - 开始活动
- `mark_activity_started()` - 标记活动已开始交互
- `finish_activity()` - 完成活动
- `cancel_activity()` - 取消活动
- `is_in_activity()` - 是否在活动中
- `can_refund_activity()` - 是否可返还行动点

---

## 11. 实现检查清单

- [x] 创建Godot项目
- [x] 实现TimeSystem.gd（autoload）
- [x] 实现GameState.gd（autoload）
- [x] 创建time_config.json
- [x] 创建TimeUI场景和脚本
- [x] 创建ActionButton场景和脚本
- [x] 创建原型主场景
- [x] 实现简易NPC响应
- [x] 测试验证核心机制
- [x] 实现活动系统（新增）
- [x] 添加调试模式开关
- [x] 添加配置加载错误处理