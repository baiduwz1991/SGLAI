# SANHAI `.cursor` 目录说明

本目录用于沉淀项目内的 AI 协作规范与执行辅助文件。

## 当前结构

- `roles/*.mdc`：角色边界与交付约束（工程、策划、美术、测试等）
- `rules/*.mdc`：项目级行为约束（生命周期、代码组织、命名等）
- `skills/<name>/SKILL.md`：按场景执行的任务流程
- `plans/*.plan.md`：任务计划与实施记录
- `docs/*.md`（可选）：项目工作文档模板（仅在目录存在时使用）

## 索引入口

- `rules/README.md`：规则索引与优先级说明
- `skills/README.md`：技能索引与依赖约定
- `roles/README.md`：角色索引与元数据约定
- `CHANGELOG.md`：`.cursor` 规范变更记录

## 使用约定

1. 新增“长期规范”优先放在：
   - 角色边界类 → `roles/`
   - 长期约束 → `rules/`
2. 新增“任务执行流程”放在：
   - `skills/`
3. 新增“业务模板/清单”放在：
   - `docs/`
4. 临时任务分解与阶段计划放在：
   - `plans/`

## 规则优先级（冲突处理）

当多个规范同时命中时，按以下顺序决策：

1. 更具体目录/模块规则（例如仅匹配某子目录）
2. 通用项目规则（`rules/`）
3. 角色边界与协作规则（`roles/`）

若仍冲突，以“更靠近当前业务目录”的规则为准，并在提交说明中写明取舍。

可执行判定顺序建议：`globs 更窄 > 目录更近 > version/last_updated 更新 > owner 裁决`。

## 维护建议

- 规则文档尽量单一职责（一个文件只管一个主题）。
- 变更规则时同步更新引用入口（如 `rules` 索引、`skills` 索引、`roles` 索引、项目 `README`）。
- 规则 frontmatter 建议统一包含：`description`、`globs`、`alwaysApply`、`owner`、`status`、`last_updated`、`version`。
- 若规则已废弃，显式标注“废弃”或及时删除，避免冲突。
