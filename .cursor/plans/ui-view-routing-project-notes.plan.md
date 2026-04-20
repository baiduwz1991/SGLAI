# UI View Routing 项目接入参考（阶段性）

> 说明：本文件存放“当前项目阶段”的接入链路示例。  
> 若项目入口、页面命名或启动流程调整，请同步更新本文件。  
> 通用执行步骤请以 `skills/ui-view-task-routing/SKILL.md` 为准。

## 当前接入链路示例

- 启动入口由 `UIBootstrap` 统一调用 `UIManager.open_ui(UIRegistry.START_GAME_SCENE)`。
- `StartGameScene` 通过 `UIManager.open_attach(ui_id, slot_id, UIRegistry.LOGIN_PANEL)` 以 `MODE_ATTACH` 打开登录页。
- `LoginPanel` 通过 `UIManager.open_ui(UIRegistry.HOME_TEST_PANEL)` 切换到 homeTest。

## 维护约定

- 本文件属于“阶段性参考”，不是长期硬约束。
- 若链路过期，优先更新或删除，避免误导。
