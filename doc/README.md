# SANHAI 项目目录指南

> 目标：统一目录职责，降低沟通成本，避免“资源 / 脚本 / 平台文件”混放。  
> 适用范围：所有参与 SANHAI 开发、导出、提审的成员。

## TL;DR（先看这里）

- 业务代码只进 `src/`
- 纯资源只进 `assets/`
- 第三方插件只进 `addons/`
- 平台相关文件只进 `platform/`
- 构建产物只进 `build/`（可再生，不当源码）

---

## 快速导航

- 想加新功能：看 `src/modules/`
- 想改公共能力：看 `src/core/`、`src/shared/`
- 想换图/音频/字体：看 `assets/`
- 想处理微信导出：看 `platform/wechat/`
- 想看规范文档：看 `doc/`

---

## 目录地图（层级线）

```text
SANHAI/
├─ src/                         # 运行时代码与场景（主开发区）
│  ├─ modules/                  # 功能模块（menu / gameplay / battle）
│  ├─ core/                     # 全局基础能力（autoload / config / save）
│  └─ shared/                   # 可复用组件与通用脚本
├─ assets/                      # 纯资源（图片 / 音频 / 字体 / 特效 / 本地化）
├─ addons/                      # Godot 插件（引擎约定目录）
├─ platform/                    # 平台发布资料（非运行时代码）
│  └─ wechat/
│     ├─ export_presets/        # 微信导出预设与配置备份
│     ├─ templates/             # 微信模板包（*.tpz）及分发文件
│     └─ docs/                  # 接入 / 导出 / 提审流程说明
├─ build/                       # 导出产物（可删除再生成）
├─ doc/                         # 项目文档（架构 / 规范 / 流程）
├─ .godot/                      # Godot 自动生成缓存（通常不手改）
└─ .cursor/                     # AI 规则与本地辅助配置