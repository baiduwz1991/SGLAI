# UI 生命周期规范（落地版）

## 页面模式
- `replace`：压入主栈新页面，旧页面 `hide`，由 `close_ui` 时恢复。
- `overlay`：覆盖层叠加显示，不触发下层页面 `hide/show` 生命周期。
- `attach`：挂载到父页面 slot，默认策略为“每次切换重建”。

## BaseUI 业务生命周期
- `on_ui_create(params)`：实例创建后仅一次（由框架在首次打开时直接调度）。
- `on_ui_open(params)`：每次打开时调用。
- `on_ui_show()`：页面进入可见可交互状态。
- `on_ui_hide()`：页面离开可见状态。
- `on_ui_close()`：页面关闭阶段。
- `on_ui_destroy()`：页面销毁前最终清理。

## BaseUI 子类书写约定
- 所有 `BaseUI` 子类实现生命周期函数时，统一使用 `#region 生命周期` / `#endregion` 区块包裹。
- 推荐顺序保持与 `BaseUI` 一致：`on_ui_create -> on_ui_open -> on_ui_show -> on_ui_hide -> on_ui_close -> on_ui_destroy`。

## 约束
- 业务侧不直接 `change_scene_to_packed`、不直接跨模块 `add_child` 打开页面。
- 页面切换统一走 `UIManager`。
- UI 子类初始化优先放在 `on_ui_create`，`_ready` 仅保留给底层节点就绪需求（尽量避免承载业务流程）。
- `BaseUI` 子类默认不覆写 `_ready`；若确需覆写，必须只做底层节点就绪处理，禁止写页面业务流程与跳转逻辑。
- 主页面通过 `ui_stack` 管理，覆盖层通过 `overlay_stack` 管理。
- 设置 `root_ui_id` 作为栈底根页面，`close_ui` 不允许弹出栈底根页面。
- `attach` 以 `parent_ui_id + slot_id` 作为唯一键，同一 slot 只允许一个活跃页面。

## 首批接入
- 启动入口由 `UIBootstrap` 统一调用 `UIManager.open_ui(UIRegistry.START_GAME_SCENE)`。
- `StartGameScene` 通过 `UIManager.open_attach(ui_id, slot_id, UIRegistry.LOGIN_PANEL)` 以 `MODE_ATTACH` 打开登录页。
- `LoginPanel` 通过 `UIManager.open_ui(UIRegistry.HOME_TEST_PANEL)` 切换到 homeTest。

## 验证清单
- 场景替换：启动后打开登录页，再切换到 homeTest，观察登录页进入隐藏状态并压入主栈。
- 页面恢复：调用 `close_ui()` 后，当前主页面关闭且自动恢复上一页并输出恢复日志。
- 覆盖层：调用 `UIManager.open_overlay()` 打开覆盖层，关闭后下层页面恢复显示。
- attach 切换：同一 `parent_ui_id + slot_id` 连续切换 A/B 页面，确认 A 被销毁后再创建 B。
- 父页关闭：关闭主页面时，关联 attach 页面执行 `hide -> close -> destroy` 且不残留。
