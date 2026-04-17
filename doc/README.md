# SANHAI 项目目录指南

> 目标：统一目录职责，降低沟通成本，避免“资源 / 脚本 / 平台文件”混放。  
> 适用范围：所有参与 SANHAI 开发、导出、提审的成员。

## TL;DR（先看这里）

- GDScript 业务代码只进 `src/`
- GDScript 网络底层只进 `script/network/`
- 第三方插件只进 `addons/`
- 运行时资源（字体/图片等）统一放 `assets/`
- 当前项目文档只进 `doc/`

---

## 快速导航

- 想加新功能：看 `src/modules/`
- 想改公共能力：看 `src/core/`
- 想改网络传输/HTTP：看 `script/network/`
- 想改登录到选服链路：看 `src/modules/login/` + `src/core/net/facade/`
- 想看迁移参考（U3D/Lua）：看 `docs/`
- 想看规范文档：看 `doc/README.md` 与 `.cursor/rules/`

---

## 目录地图（层级线）

```text
SANHAI/
├─ src/                                 # Godot GDScript 主代码
│  ├─ core/
│  │  ├─ font/                          # 字体服务
│  │  ├─ mvc/                           # MVC 基类与管理器
│  │  └─ net/                           # 网络中间层（GD）
│  │     ├─ facade/                     # facade/service 层
│  │     ├─ dispatch/                   # 请求分发与超时处理
│  │     ├─ protocol/                   # 编解码入口（当前 JSON，后续可切 PB）
│  │     └─ transport/                  # WebSocket/KCP 传输适配
│  └─ modules/
│     ├─ <module_name>/                 # 业务模块（示意）
│     │  ├─ core/                       # 领域/流程逻辑 + MVC 控制器（Controller 也放 core）
│     │  └─ view/                       # 规范：场景(.tscn)与挂载脚本(.gd)必须同名（如 LoginPanel.tscn + LoginPanel.gd）
│     └─ startgame/                     # 游戏启动编排入口（注册控制器、调用 on_game_start）
├─ script/
│  └─ network/                          # GDScript 网络底层（Socket/HTTP/Crypto/KCP）
├─ assets/                              # 运行时资源（字体/图片等，参与导出）
├─ doc/                                 # 当前项目文档（本文件等）
├─ docs/                                # 迁移参考（旧 U3D C# / XLua Lua）
├─ addons/                              # Godot 插件
├─ .godot/                              # Godot 自动生成缓存（通常不手改）
└─ .cursor/                             # AI 规则与本地辅助配置
```

## 命名规范（模块内）

- `view` 层：场景文件与挂载脚本必须同名（如 `LoginPanel.tscn` + `LoginPanel.gd`）
- `core` 层 Controller：文件名必须为 `*Controller.gd`（如 `LoginController.gd`、`HomeTestController.gd`）
- Controller 类名：必须与文件名一致并使用 `PascalCase`（如 `class_name LoginController`）
- Controller 继承：统一继承 `BaseController`，并实现生命周期方法（`on_game_start/on_login/on_reconnection/on_login_out/on_release`）
- `BaseUI` 子类：生命周期实现统一使用 `#region 生命周期` 代码区块（详见 `doc/UI_LIFECYCLE.md`）