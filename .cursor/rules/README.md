# `.cursor/rules` 索引

## 现有规则

- `UI_LIFECYCLE.mdc`：`BaseUI` 生命周期定义与页面切换硬约束（实施流程下沉到 skill）
- `UI_VIEW_SCRIPT_REGION_STYLE.mdc`：`src/modules/**/view/*.gd` 的 region 组织与节点引用硬约束（模板与步骤下沉到 skill）

## 规则优先级

规则冲突时按以下顺序处理：

1. 命中范围更小（更具体 globs）的规则优先
2. 与当前业务目录更接近的规则优先
3. 若仍冲突，以较新版本（`version`/`last_updated`）为准
4. 若仍无法判定，由对应 `owner` 裁决，并在说明中记录取舍

## 新增规则建议

- 命名建议：`<DOMAIN>_<TOPIC>.mdc`（例如 `NET_REQUEST_CONVENTION.mdc`）
- 每个规则聚焦一个主题，避免超长“大全文档”
- frontmatter 建议至少包含：
  - `description`
  - `globs`
  - `alwaysApply`
  - `owner`
  - `status`（`active`/`deprecated`）
  - `last_updated`（`YYYY-MM-DD`）
  - `version`（例如 `1.0.0`）
