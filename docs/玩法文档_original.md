# ETN — Embody The Now 完整设计 & 技术实现文档

本文档整合了游戏设计核心概念、所有系统设计以及 Godot 4.6/4.7 的具体实现方案，适用于单人独立开发者，目标 2026 年发布 Demo。

---

## 第一部分：游戏设计核心

### 1.1 项目概述

- **游戏名称**：ETN — Embody The Now（活在当下）
- **游戏类型**：剧情向 JRPG / 校园生活模拟 / 叙事驱动游戏
- **核心主题**："活在当下"，有些人注定只能陪你走一段路
- **改编来源**：作者真实高中经历，情感核心为转校生的到来与离去
- **目标平台**：PC（Steam/itch.io）
- **开发工具**：Godot 4.6/4.7（GDScript），AI辅助
- **视觉风格**：伪 3D 场景 + 像素风 2D 角色，固定视角

### 1.2 核心设计理念

- **叙事模拟**：轨迹随机性低，改编真实经历，玩家扮演作者体验青春。
- **循环暗线**：作为背景设定，不显式表现，通过异常、记忆碎片、造梦主暗示。
- **结局哲学**：离别无法改变，但可以选择如何面对（多结局+彩蛋结局）。
- **无战斗 JRPG**：用探索、情绪管理、收集、好感度替代传统战斗，情感本身就是奖励。

### 1.3 故事与角色设计

#### 1.3.1 故事时间线

- **时间跨度**：高中三年（高一 ~ 高三）
- **核心事件**：转校生的到来与离去
- **叙事结构**：改编真实经历，轨迹随机性低

#### 1.3.2 角色设定

- **核心角色数量**：10-20个
- **角色类型**：以同龄人（同年级同学）为主，无跨年级角色
- **差异化设计**：
  - 主线角色（2-3个）：完整剧情线、深度好感系统
  - 支线角色（5-8个）：独立支线任务、中等好感深度
  - 日常角色（10+个）：日常交互、简单好感

#### 1.3.3 关键角色：转校生

- **定位**：故事核心人物，转学来到主角所在班级
- **作用**：情感主线载体，玩家的选择将影响与转校生的关系走向
- **特殊性**：好感度培养不一定导向结局，需要与"合适的人"培养好感

### 1.4 核心系统概览

| 系统 | 简要说明 |
|------|----------|
| 存档/读档 | 系统自动存档，玩家只能在大选项节点读档回溯 |
| 选项系统 | 大选项影响剧情，小选项影响日常 |
| 事件系统 | 快乐/难过/关注/试探等多种事件类型 |
| 精神状态 | Overjoyed/空虚/内耗/抑郁等心理状态 |
| 情绪系统（G/D值） | 影响对话选项、心理状态、好感效果 |
| 好感度 | 双向好感度，试探机制获取对方好感 |
| 行动点 | 每日限制，模拟现实时间压力 |
| 收集品 | 主线/支线获得，用于解锁区域，永久保留 |
| 造梦主 | 每周/章节强制触发梦境指引 |
| 支线 | 时间窗口限制，过期无法开启 |
| 成绩 | 影响清北班淘汰、竞赛支线 |
| 时间/日程 | 每日时段推进，NPC 按日程移动 |
| 食堂 | 队列排队、多窗口购物系统 |

---

## 第二部分：核心系统详细设计

### 2.1 存档与读档系统

#### 2.1.1 核心原则

- **玩家不能主动存档**：存档是系统行为
- **大选项自动存档**：每次选择大选项时系统自动保存
- **读档入口**：第一天结束后，在[家]中可以通过读档电脑回溯

#### 2.1.2 读档机制

- **读档入口位置**：家中（第一天结束后解锁）
- **读档限制**：原则上可无限读档，但会影响剧情走向和成就获取
- **通关后特权**：游戏通关后，可以不付出任何代价回到存档点

#### 2.1.3 设计理念

> 从设计角度来说，作者并不推崇读档操作。作者和文中的故事一样，希望大家能够收获一个在自己操作下的结局，而不是执着。

#### 2.1.4 防误触机制

- 点击选项先查看详细说明
- 点击确认后再执行选择

### 2.2 选项系统

#### 2.2.1 小选项

- **定义**：日常生活、对话、购物等日常选择
- **特点**：
  - 不影响剧情走向
  - 可能略微影响好感度
  - 可根据个人喜好选择
  - 非对话场景可以不做出选择
- **标记**：无特殊标记

#### 2.2.2 大选项

- **定义**：会影响剧情走向的关键选择
- **特点**：
  - 每次选择自动存档
  - 触发不同事件，可能导致不同结局
  - 需要仔细思考后选择
- **标记**：有明显的大选项标识

#### 2.2.3 [Destiny] 命运

- **概念**：有些事情是一定会发生的
- **特点**：玩家的选择有时也没有那么强有力
- **作用**：强化"活在当下"主题，接受无法改变的事实

### 2.3 事件系统

游戏设置多种影响游戏结局走向和参数的事件。一切涉及心理活动的事件都将被定义为[事件]。

#### 2.3.1 事件类型总览

| 事件类型 | 触发方式 | 主要效果 |
|----------|----------|----------|
| [快乐] | 选择触发/偶遇 | +G值，改好感，双向 |
| [难过] | 选择触发/偶遇 | +D值，改好感，双向 |
| [被关注] | 被动触发(偶遇) | 反映对方好感，+G -D |
| [关注] | 主动触发 | 改好感，影响GD值 |
| [试探] | 主动触发 | 获取对方好感度信息 |
| [???] | 选择触发 | 未知结果，可能转换为其他类型 |
| [中立] | 默认 | 不影响主线和好感 |

#### 2.3.2 事件详细说明

**[快乐]**
- 一般为选择触发或偶遇
- 可能提升G值
- 触发精神状态
- 能够改变好感度（原则上为双向）
- 是绝大多数事件的定义类型

**[难过]**
- 一般为选择触发或偶遇
- 可能提升D值
- 触发精神状态
- 能够改变好感度（原则上为双向）
- 是绝大多数事件的定义类型

**[被关注]**
- 一般为偶遇即被动触发
- 可以反映对象对我们的[对我的好感]
- 会体现在好感度UI中
- [对我的好感]越高越容易触发
- 能够大大提升[对Ta的好感]
- 触发某种精神状态，提升G值减少D值

**[关注]**
- 主动触发
- 发挥主观能动性
- 发自内心或故意关注对象
- 以达到改变好感度为目的
- 可能触发其他事件类型
- 可能会影响GD值

**[试探]**
- 用于获取对象[对我的好感]
- 使用不恰当会影响GD值
- 更会影响好感
- 成功时提示冰川小未的心理状态和好感情况

**[???]**
- 现阶段不知道结果
- 选择后事件性质可能转换为上述其他选项
- 增加不确定性

**[中立]**
- 对主线和好感并无太大影响
- 可根据自己对于角色的理解和喜好选择
- 默认该选项不做标记

### 2.4 精神状态系统

精神状态通过选项直接或间接触发，对游戏体验产生深远影响。

#### 2.4.1 状态总览

| 状态 | 持续性 | 主要效果 | 风险 |
|------|--------|----------|------|
| [Overjoyed] | 当前事件段 | 免疫负面效果 | 结束后易触发内耗 |
| [空虚] | 持续 | 不增G，选项减少 | 可转为难过 |
| [内耗] | 持续 | 自我怀疑，好感度系统不稳定 | 可转为抑郁 |
| [抑郁] | 持续 | 好感度系统崩溃，关系风险 | 可能导致BE |
| [神威] | 隐藏 | 待定 | - |

#### 2.4.2 状态详细说明

**[Overjoyed] 心动**
- 仅当前事件段有效，游戏中会标明
- 此状态下触发的难过事件或遭到拒绝也不会对好感产生负面影响
- 不会触发负面精神状态
- 有助于提升G值和[对Ta的好感]
- 注意：结束后不要触发[内耗]

**[空虚]**
- 触发方式：接受和自己关系不是很好的人的邀请；戒断反应
- 该状态下[快乐]事件不会增加G
- 可触发选项减少
- 选项中的事件更多是中立和[难过]

**[内耗]**
- 进入自我怀疑和焦虑状态
- 甚至会怀疑好感度系统（此状态下请勿完全相信好感度系统，会明确标注"好感度不准确"）
- 降低[对Ta的好感]，降低G值，提升D值
- 如果多次触发可能会进入[抑郁]

**[抑郁]**
- 在GD较高时（较高的GD值都有触发风险）遭受打击触发
- 在[Overjoyed]结束后注意不要触发[内耗]
- 好感度系统崩溃，此时只能查看[对ta的好感]
- 该状态下可能会对关系造成严重影响（可能导致BE，速通该章节）
- 注意：避免前往有风险的地方，不要让主角死亡（死亡会达成某种结局）

**[神威]**
- 隐藏触发
- 具体效果待定

### 2.5 好感度系统

#### 2.5.1 双向好感度

- **[对TA的好感度]**：玩家可实时查看，表示玩家对角色的好感
- **[对我的好感]**：角色对玩家的好感，需要通过[试探]事件获取

#### 2.5.2 核心机制

- 获取对方好感需要通过[试探]事件
- 不恰当的[试探]可能会损失好感
- 想要获取游戏胜利，必须得知对方对我们的好感度
- 和某一些角色确实可以培养非常高的好感度，但不一定能够引导走向结局
- 需要和"合适的人"培养好感

#### 2.5.3 好感度UI

- 进度条显示
- 阶段标记（陌生人→认识→朋友→好友→挚友等）
- 抑郁状态下只能查看[对ta的好感]

### 2.6 G值与D值系统

#### 2.6.1 G值（Glad）

- 每次[快乐]事件可能增加G值
- 较好的G值有助于避免[内耗]并隐藏D值
- 越高G值下发生的[心动]事件越能减少D值
- 不同的GD值可能导致出现不同的选项

**G值与事件影响的关系：**
- 当前G值越高，越容易因事件或选择进入[内耗]
- 当前G值越高，[对Ta的好感度]越高，[难过]事件和[内耗]所造成的[对Ta好感度]和[D值]影响越严重

#### 2.6.2 D值（Depression）

- 每次[难过]事件可能增加D值
- 在较高D值下更容易触发[内耗][抑郁][心动]
- D值过高会快速扭转心理状态

**D值与事件影响的关系：**
- 当前D值越高，[对Ta的好感度]越高，[快乐]事件所造成的[对Ta好感度]和[G值]影响越大

#### 2.6.3 GD值交互

| 状态 | G值影响 | D值影响 |
|------|---------|---------|
| [快乐]事件 | +G | 可能减少D |
| [难过]事件 | 可能减少G | +D |
| 高G状态 | [心动]效果好 | 隐藏D值 |
| 高D状态 | 更易触发负面状态 | 更易抑郁 |

### 2.7 行动点系统

#### 2.7.1 每日行动点分配

| 时段 | 行动点 | 说明 |
|------|--------|------|
| 上午 | 2点 | 大课间 + 一节课间可离开教室 |
| 下午 | 1点 | 一节课间可离开教室 |
| 午饭 | 1点 | 不在本班区域用餐消耗行动点 |
| 晚饭 | 1点 | 同上 |
| 晚自习 | 1点 | - |
| 放学后 | 1点 | 选择回家不消耗，回家后可用1点读档 |

#### 2.7.2 设计目的

- 限制玩家活动，模拟现实时间限制
- 冰神没有过多精力同时干很多事情
- 让玩家必须精心于一个焦点

#### 2.7.3 行动点消耗

- 各类交互活动消耗行动点
- 行动点耗尽后只能推进时间
- 读档操作不消耗行动点（直接返回存档点）

### 2.8 每日时间流程

#### 2.8.1 时段设计（参考，可调整）

| 时段 | 时间范围 | 行动点 | 可用活动 |
|------|----------|--------|----------|
| 早读 | 早上 | 0 | 剧情推进 |
| 上午课间 | 上午 | 2 | 自由活动/学习 |
| 午休 | 中午 | 1 | 用餐/自由活动 |
| 下午课程 | 下午 | 0 | 剧情推进 |
| 放学后 | 傍晚 | 1 | 自由活动 |
| 晚自习 | 晚上 | 1 | 学习/自由活动 |
| 夜间 | 深夜 | 1 | 回家/读档 |

#### 2.8.2 周循环

- 自然周为单位
- 每周可能有特殊事件
- 造梦主梦境定期触发

---

## 第三部分：食堂与商业系统

### 3.1 食堂系统

#### 3.1.1 排队机制

- 队列排队系统：交互即在队尾排队
- 排队后解锁该列食谱
- 排上队后显示菜单，购买后传送至第一个，播放购买动画
- 根据高三实际情况，阿姨有时会认识玩家
- 只能在队尾排队，交互后直接传送到第一个
- 可以放弃排队，但要重新排队
- 只能重排两次（第一次不说，让玩家吃不成饭，调整队列长度）

#### 3.1.2 窗口类型

**盖浇窗口（16元）**
- 牛肉、卤肉、茄子、蒸蛋、鱼香肉丝

**大炒窗口（10元）**
- 低配：回锅肉、土豆烧排骨、猪肝、酥肉汤、胡萝卜炖肉、韭菜肉丝、白菜炒肉、番茄炒蛋
- 标配/高配：回锅肉、土豆烧排骨、猪肝、酥肉汤、胡萝卜炖肉、韭菜肉丝、白菜炒肉、黄焖鸡(随机)、干锅标配(随机)、豇豆肉丝(随机)、番茄炒蛋

**小炒窗口**
- 干锅、小煎肉、干锅高配(随机)、鱼香肉丝、酥肉汤(高配)、水煮肉片(随机)、豇豆肉丝、毛血旺(随机)、土豆烧排骨(随机)、蒸蛋、韭黄肉丝(随机)

**晚饭窗口**

*米粉类（一周吃三次后不能再购买）：*
- 绵阳米线（清汤/红汤/清红汤）
- 特色提示："我一贯吃不来米粉这样的食物，还是下次别买了吧……"

*面类：*
- 面（牛肉/豌杂/酸菜）、刀削面

*米饭类：*
- 米饭（白饭/炒饭/八宝粥/稀饭）+ 大小炒全部随机刷新5种

*点心类：*
- 包子、馒头、鸡肉卷、玉米卷、蒸饺、煎饺、奶黄包

*炸串类：*
- 肉肠4.5、腊肠4、郡肝3、鸡米花3.5、鸡块3.5、玉米4、鸡皮3、里脊3、鸡柳3、方形鸡排3、圆形鸡排3、带串鸡排4.5、鱼排2、年糕2、土豆鸡柳卷5.5
- 肉饼/茄饼/土豆饼4、卤鸡蛋2、卤鸡腿4.5
- 银耳汤2、醪糟汤圆2

**早饭窗口**
- 包子、馒头、鸡肉卷、玉米卷、蒸饺、煎饺、奶黄包

### 3.2 面包房系统

#### 3.2.1 触发机制

- 前两次触发可以选择去不去
- 第三次强制触发，推动剧情

**触发对话示例：**
```
// 回去路上选择要不要去面包房（即使去了也可以不买）
肖迟：话说，我来学校之前听说学校有面包房，你知道吗？
冰川小未：我也听说过
A. （去面包房）好像就在这边，我们去看看
B. (暂时不去，后面可以去)就是不知道具体在哪里。下次看到了再说吧
```

#### 3.2.2 商品列表

- 蛋挞（大/小）、甜甜圈、脏脏包、牛角包、豆沙包、菠萝包
- 三明治

#### 3.2.3 社交功能

- 和朋友一起买：+2好感度
- 买了分享：+2好感度
- 请对方吃饭：+4好感度
- 随机刷新商品：20%概率刷新"请客"选项

### 3.3 奶茶店系统

#### 3.3.1 触发机制

同面包房，前两次可选，第三次强制

**触发对话示例：**
```
// 主动触发时
肖迟：走，去奶茶店
小未：彳亍，正好口渴了。
```

#### 3.3.2 商品列表

*小吃类：*
- 脆骨肠、肉肠、鸡排、汉堡(10元)、鸡翅包饭、丸子、肉排

*饮品类：*
- 珍珠奶茶（大/小）、茉香牛乳、满杯百香果、草莓啵啵啵
- 葡萄啵啵啵、红糖芋圆、咖啡、热可可

---

## 第四部分：Godot 技术实现方案

### 4.1 项目结构与全局设置

#### 4.1.1 文件夹组织

```
res://
├── assets/
│   ├── models/        # 3D模型（.glb）或 GridMap 材质
│   ├── textures/      # 像素风格贴图
│   ├── sprites/       # 2D角色立绘/动画帧
│   ├── fonts/         # 像素字体
│   ├── sounds/        # 音效/BGM
│   └── shaders/       # 自定义着色器（像素化滤镜）
├── scenes/
│   ├── world/         # 校园场景（教学楼、食堂等）
│   ├── ui/            # UI场景（主菜单、背包、任务面板、对话弹窗）
│   ├── characters/    # 角色场景（Player, NPC）
│   └── systems/       # 系统场景（读档电脑、造梦主梦境）
├── scripts/
│   ├── global/        # 全局自动加载脚本
│   ├── systems/       # 各系统脚本
│   └── ui/            # UI脚本
├── data/              # 游戏数据（对话、任务、物品、NPC日程）
└── addons/            # 第三方插件
```

#### 4.1.2 全局自动加载（Autoload）

需在项目设置中添加：
- `GameState`：管理 G/D值、好感度字典、全局标志、精神状态
- `SaveManager`：存档/读档
- `InventoryManager`：背包管理
- `TaskManager`：任务追踪
- `TimeSystem`：日期/时间推进，行动点管理，NPC 日程调度
- `DialogSystem`：对话控制（可封装插件或自定义）
- `CanteenManager`：食堂系统管理

### 4.2 伪3D场景搭建（无需 Blender）

#### 4.2.1 使用 GridMap 构建校园

- **创建 MeshLibrary**：
  - 新建 `MeshLibrary` 资源
  - 添加基本几何体（`BoxMesh`、`CylinderMesh` 等），设置材质为像素风格贴图
  - 导出为 `.tres` 文件
- **搭建场景**：
  - 添加 `GridMap` 节点，指定 `mesh_library`
  - 设置 `cell_size` 为网格单元大小（如 2.0）
  - 手动放置方块组合成教学楼、走廊、食堂等
- **复杂形状**：使用 `CSG` 节点组合特殊结构
- **碰撞**：`GridMap` 可自动生成碰撞

#### 4.2.2 像素化视觉效果

- 在 `WorldEnvironment` 中添加 `Environment`，设置 `tonemap` 为 `Filmic`，加轻微晕影
- 添加自定义着色器模拟像素化

### 4.3 角色系统

#### 4.3.1 玩家角色（Player）

**节点结构**：
```
CharacterBody3D (Player)
├── CollisionShape3D (胶囊形)
├── Sprite3D (2D角色，billboard 模式)
│   └── AnimationPlayer (控制帧动画)
├── CameraPivot (Node3D)
│   └── Camera3D (固定视角，如斜45度)
└── InteractionArea (Area3D，用于检测交互)
```

**Player.gd（简化）**：
```gdscript
extends CharacterBody3D

@export var speed = 5.0
@export var interaction_distance = 2.0

func _physics_process(delta):
    var input_dir = Input.get_vector("left", "right", "forward", "back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    move_and_slide()

func _input(event):
    if event.is_action_pressed("interact"):
        interact()

func interact():
    var space = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(global_position, global_position - global_transform.basis.z * interaction_distance)
    query.collision_mask = 2
    var result = space.intersect_ray(query)
    if result and result.collider.has_method("on_interact"):
        result.collider.on_interact()
```

#### 4.3.2 NPC 角色（带日程、自动导航、动画）

**节点结构**：
```
CharacterBody3D (NPC)
├── CollisionShape3D
├── Sprite3D + AnimationPlayer
├── NavigationAgent3D
└── InteractionArea (触发对话)
```

**NPC.gd**：
```gdscript
extends CharacterBody3D

@export var npc_id: String
@export var schedule_data: Dictionary
@export var speed = 3.0

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer

var current_target: Vector3
var current_animation = "idle"

func _ready():
    TimeSystem.time_advanced.connect(_on_time_advanced)
    update_schedule()

func _physics_process(delta):
    if nav_agent.is_navigation_finished():
        if anim_player.current_animation != current_animation:
            anim_player.play(current_animation)
        return
    var next = nav_agent.get_next_path_position()
    var direction = (next - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
    if anim_player.current_animation != "walk":
        anim_player.play("walk")

func _on_time_advanced(day: int, period: String):
    update_schedule(day, period)

func update_schedule(day: int, period: String):
    var entry = find_schedule_entry(day, period)
    if entry:
        var target_pos = get_location_from_id(entry.location)
        move_to(target_pos)
        current_animation = entry.animation

func move_to(pos: Vector3):
    current_target = pos
    nav_agent.target_position = pos

func on_interact():
    DialogSystem.start_dialogue(npc_id)
```

**日程数据格式（JSON）**：
```json
[
  { "day": 1, "period": "morning", "location": "dorm_301", "animation": "sleep" },
  { "day": 1, "period": "class", "location": "classroom_302", "animation": "sit" }
]
```

### 4.4 对话系统（长剧情优化）

#### 4.4.1 数据格式选择

为避免大 JSON 加载缓慢，采用分章节 Resource 二进制格式：
- 每个章节的对话数据保存为 .tres 资源
- 动态加载当前章节，完成后可卸载

**DialogueNode 示例**：
```gdscript
# dialogue_node.gd
extends Resource
class_name DialogueNode

@export var id: String
@export var speaker: String
@export var text: String
@export var next_id: String
@export var choices: Array[DialogueChoice]
@export var condition: String
@export var effects: Dictionary  # {"g": 5, "d": -2, "love_xiaochi": 3}
@export var is_major_choice: bool  # 是否为大选项
@export var event_type: String  # 事件类型：happy/sad/attention/probe等
```

**DialogueChoice 示例**：
```gdscript
# dialogue_choice.gd
extends Resource
class_name DialogueChoice

@export var text: String
@export var next_id: String
@export var condition: String
@export var effects: Dictionary
@export var event_type: String
@export var is_major: bool  # 是否为大选项
```

#### 4.4.2 对话系统管理器

```gdscript
# DialogSystem.gd (autoload)
extends Node

var current_dialogue: Resource
var current_node_id: String

func start_dialogue(npc_id: String, chapter: String = "chapter1"):
    current_dialogue = load("res://data/dialogues/" + chapter + ".tres")
    current_node_id = "start"
    show_dialogue_balloon()

func show_dialogue_balloon():
    var node = get_node_by_id(current_node_id)
    if not node:
        return
    if node.condition and not evaluate_condition(node.condition):
        current_node_id = node.next_id
        show_dialogue_balloon()
        return
    
    # 大选项自动存档
    if node.is_major_choice:
        SaveManager.create_story_save(node.id, node.text)
    
    var balloon = preload("res://scenes/ui/DialogueBalloon.tscn").instantiate()
    balloon.set_data(node)
    add_child(balloon)
    balloon.choice_selected.connect(_on_choice_selected)

func _on_choice_selected(choice: DialogueChoice):
    apply_effects(choice.effects)
    
    # 处理事件类型
    if choice.event_type == "probe":
        handle_probe_event(choice)
    
    current_node_id = choice.next_id
    show_dialogue_balloon()

func apply_effects(effects: Dictionary):
    if effects.has("g"):
        GameState.add_g(effects.g)
    if effects.has("d"):
        GameState.add_d(effects.d)
    if effects.has("love"):
        for npc_id in effects.love:
            GameState.add_love(npc_id, effects.love[npc_id])

func handle_probe_event(choice: DialogueChoice):
    # 试探事件处理
    var success = randf() > 0.3  # 70%成功率
    if success:
        var love_value = GameState.get_love_to_player(choice.target_npc)
        show_probe_result(love_value)
    else:
        GameState.add_love(choice.target_npc, -2)
        show_message("试探失败，好感度下降")
```

### 4.5 精神状态系统实现

```gdscript
# MentalState.gd (在GameState中)
enum MentalState { NORMAL, OVERJOYED, EMPTY, INTERNAL_CONFLICT, DEPRESSION, DIVINE }

var current_mental_state: MentalState = MentalState.NORMAL
var mental_state_duration: int = 0  # 持续时间（事件数）

func set_mental_state(new_state: MentalState, duration: int = -1):
    current_mental_state = new_state
    mental_state_duration = duration
    mental_state_changed.emit(new_state)

func check_mental_state_triggers():
    # 检查是否触发精神状态变化
    if g_value > 80 and d_value < 20:
        # 可能触发Overjoyed
        pass
    if d_value > 70:
        # 可能触发抑郁
        pass

func can_view_full_affection() -> bool:
    return current_mental_state != MentalState.DEPRESSION
```

### 4.6 行动点系统实现

```gdscript
# TimeSystem.gd (autoload)
extends Node

var day: int = 1
var period_index: int = 0
var action_points: int = 0

var periods = ["morning", "break1", "lunch", "afternoon", "dinner", "evening_study", "night"]

var period_action_points = {
    "morning": 0,
    "break1": 2,  # 大课间
    "lunch": 1,
    "afternoon": 1,
    "dinner": 1,
    "evening_study": 1,
    "night": 1
}

signal time_advanced(day, period)
signal action_points_changed(points)

func _ready():
    reset_action_points()

func reset_action_points():
    var current_period = periods[period_index]
    action_points = period_action_points.get(current_period, 0)
    action_points_changed.emit(action_points)

func use_action_point(amount: int = 1) -> bool:
    if action_points >= amount:
        action_points -= amount
        action_points_changed.emit(action_points)
        return true
    return false

func advance_period():
    period_index += 1
    if period_index >= periods.size():
        period_index = 0
        day += 1
    reset_action_points()
    time_advanced.emit(day, periods[period_index])
```

### 4.7 食堂系统实现

```gdscript
# CanteenManager.gd (autoload)
extends Node

var queue_positions: Dictionary = {}  # window_id: [players in queue]
var max_queue_retry: int = 2
var player_queue_retry: Dictionary = {}  # window_id: retry_count

signal queue_joined(window_id)
signal order_completed(window_id, items)

func join_queue(window_id: String) -> bool:
    if not queue_positions.has(window_id):
        queue_positions[window_id] = []
    queue_positions[window_id].append("player")
    player_queue_retry[window_id] = 0
    queue_joined.emit(window_id)
    return true

func leave_queue(window_id: String):
    if queue_positions.has(window_id):
        queue_positions[window_id].erase("player")

func complete_order(window_id: String, items: Array):
    # 传送至第一个，播放动画
    order_completed.emit(window_id, items)
    leave_queue(window_id)

func can_requeue(window_id: String) -> bool:
    var retry = player_queue_retry.get(window_id, 0)
    if retry < max_queue_retry:
        player_queue_retry[window_id] = retry + 1
        return true
    return false  # 超过重排次数，吃不成饭
```

### 4.8 存档系统完善

```gdscript
# SaveManager.gd (autoload)
extends Node

const SAVE_DIR = "user://saves/"
const STORY_SAVE_DIR = "user://story_saves/"

func create_story_save(story_point_id: String, story_point_name: String):
    var data = collect_save_data()
    data.save_id = story_point_id
    data.story_point_name = story_point_name
    data.timestamp = Time.get_unix_time_from_system()
    
    var file = FileAccess.open(STORY_SAVE_DIR + story_point_id + ".tres", FileAccess.WRITE)
    file.store_var(data)

func collect_save_data() -> SaveDataContainer:
    var data = SaveDataContainer.new()
    data.g_value = GameState.g_value
    data.d_value = GameState.d_value
    data.mental_state = GameState.current_mental_state
    data.love = GameState.love.duplicate()
    data.day = TimeSystem.day
    data.period = TimeSystem.period_index
    data.action_points = TimeSystem.action_points
    data.inventory = InventoryManager.get_item_ids()
    data.tasks = TaskManager.get_task_states()
    data.story_flags = GameState.story_flags.duplicate()
    return data

func load_story_save(save_id: String) -> bool:
    var path = STORY_SAVE_DIR + save_id + ".tres"
    if not FileAccess.file_exists(path):
        return false
    
    var file = FileAccess.open(path, FileAccess.READ)
    var data = file.get_var() as SaveDataContainer
    
    # 恢复状态
    GameState.g_value = data.g_value
    GameState.d_value = data.d_value
    GameState.current_mental_state = data.mental_state
    GameState.love = data.love.duplicate()
    GameState.story_flags = data.story_flags.duplicate()
    TimeSystem.day = data.day
    TimeSystem.period_index = data.period
    TimeSystem.action_points = data.action_points
    
    return true
```

### 4.9 性能优化要点

- 使用 GridMap 合并网格减少 draw call
- NPC 使用 NavigationAgent3D 时，导航网格不宜过大
- 对话资源分章节加载，及时卸载
- 远处 NPC 可暂停动画或降低更新频率

### 4.10 开发路线图（2026 Demo）

1. **阶段一（1-2个月）**：搭建小型场景，实现核心系统框架
   - 教学楼一层场景
   - 玩家移动与交互
   - 一个NPC（肖迟）日程+对话
   - 情绪系统（G/D值）
   - 大选项存档

2. **阶段二（3-4个月）**：完善UI与核心功能
   - 像素化UI风格
   - 精神状态系统
   - 行动点系统
   - 食堂系统原型
   - 扩展NPC数量（3-5个）

3. **阶段三（5-8个月）**：内容填充
   - 批量导入剧情数据（高一章节）
   - 造梦主梦境
   - 支线时间窗口
   - 成绩系统
   - 完善食堂/商业系统

4. **阶段四（9-12个月）**：打磨与发布
   - 完成全部校园建模
   - 填充所有NPC日程
   - 测试平衡
   - 发布Demo

---

## 第五部分：待确认事项

### 5.1 系统层面

- [ ] 具体剧情存档触发点列表
- [ ] 读档地点和条件详细设计
- [ ] 二周目继承数据的具体范围
- [ ] 是否需要章节选择功能（通关后）
- [ ] 下午是否增加课间时段

### 5.2 内容层面

- [ ] 各角色详细背景故事
- [ ] 三年剧情大纲细化
- [ ] 多结局具体设计
- [ ] 造梦主具体内容

### 5.3 平衡层面

- [ ] GD值数值范围与增长曲线
- [ ] 精神状态触发阈值
- [ ] 好感度获取/损失数值
- [ ] 行动点消耗平衡

---

**文档版本**: 2.0  
**最后更新**: 2026-03-20  
**下次讨论**: 角色详细设计、剧情大纲