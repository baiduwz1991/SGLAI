# `.cursor/skills` 索引

## 现有技能

- `ui-view-task-routing/SKILL.md`
  - 用于 `src/modules/**/view/*.gd` 新建/改造任务
  - 执行前先路由到：
    - `.cursor/rules/UI_LIFECYCLE.mdc`
    - `.cursor/rules/UI_VIEW_SCRIPT_REGION_STYLE.mdc`
  - 承载实施流程：最小模板、增量治理、接入参考、验证清单

## 新增技能建议

- 命名建议：`<task-domain>-<workflow>`（例如 `net-module-migration`）
- 单个技能聚焦一个高频任务场景，避免“大而全”
- 技能若依赖规则，需在文档中显式写明依赖项和触发条件
- 规则变更后应回查相关技能，避免“技能步骤”与“规则内容”漂移
- skill frontmatter 建议至少包含：
  - `name`
  - `description`
  - `owner`
  - `status`（`active`/`deprecated`）
  - `last_updated`（`YYYY-MM-DD`）
  - `version`
  - `depends_on`（依赖的 rules/skills 路径列表）
