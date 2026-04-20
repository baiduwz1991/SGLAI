# `.cursor` 变更记录

## 2026-04-20

### 改进

- 将规则与技能分层固定为：`rules`（短且硬约束）+ `skills`（执行流程与模板）。
- 将 `ui-view-task-routing` 中的阶段性项目接入说明抽离到：
  - `.cursor/plans/ui-view-routing-project-notes.plan.md`
- 为 `ui-view-task-routing` 补充标准化 frontmatter：
  - `owner` / `status` / `last_updated` / `version` / `depends_on`
- 完善冲突处理闭环：
  - `globs 更窄 > 目录更近 > version/last_updated 更新 > owner 裁决`
- 在根 README 新增 changelog 入口，便于追踪规范演进。
