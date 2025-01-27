import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/abs_underline_tabindicator.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/menu.dart';
import 'package:qinglong_app/base/ui/ql_context_menu.dart';
import 'package:qinglong_app/module/task/intime_log/intime_log_page.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/module/task/task_detail/task_detail_page.dart';
import 'package:qinglong_app/module/task/task_viewmodel.dart';
import 'package:qinglong_app/utils/utils.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseStateWidget<TaskViewModel>(
      builder: (ref, model, child) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            searchCell(ref),
            Expanded(
              child: DefaultTabController(
                length: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      tabs: const [
                        Tab(
                          text: "全部",
                        ),
                        Tab(
                          text: "正在运行",
                        ),
                        Tab(
                          text: "从未运行",
                        ),
                        Tab(
                          text: "拉库脚本",
                        ),
                        Tab(
                          text: "已禁用",
                        ),
                      ],
                      isScrollable: true,
                      indicator: AbsUnderlineTabIndicator(
                          wantWidth: 20,
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          body(model, model.list, ref),
                          body(model, model.running, ref),
                          body(model, model.neverRunning, ref),
                          body(model, model.notScripts, ref),
                          body(model, model.disabled, ref),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      model: taskProvider,
      onReady: (viewModel) {
        viewModel.loadData();
      },
    );
  }

  Widget body(TaskViewModel model, List<TaskBean> list, WidgetRef ref) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async {
        return model.loadData(false);
      },
      child: list.isEmpty
          ? const EmptyWidget()
          : ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemBuilder: (context, index) {
                TaskBean item = list[index];

                if (_searchController.text.isEmpty ||
                    (item.name?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                    (item.command?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                    (item.schedule?.contains(_searchController.text.toLowerCase()) ?? false)) {
                  return TaskItemCell(item, ref);
                } else {
                  return const SizedBox.shrink();
                }
              },
              itemCount: list.length,
            ),
    );
  }

  Widget searchCell(WidgetRef context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      child: CupertinoSearchTextField(
        onSubmitted: (value) {
          setState(() {});
        },
        onSuffixTap: () {
          _searchController.text = "";
          setState(() {});
        },
        controller: _searchController,
        borderRadius: BorderRadius.circular(
          30,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
        suffixInsets: const EdgeInsets.only(
          right: 15,
        ),
        prefixInsets: EdgeInsets.only(
          top: Platform.isAndroid ? 10 : 6,
          bottom: 6,
          left: 15,
        ),
        placeholderStyle: TextStyle(
          fontSize: 16,
          color: context.watch(themeProvider).themeColor.descColor(),
        ),
        style: const TextStyle(
          fontSize: 16,
        ),
        placeholder: "搜索",
      ),
    );
  }
}

class TaskItemCell extends StatelessWidget {
  final TaskBean bean;
  final WidgetRef ref;

  const TaskItemCell(this.bean, this.ref, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ref.watch(themeProvider).themeColor.settingBgColor(),
      child: QlCupertinoContextMenu(
        bean: bean,
        actions: [
          QLCupertinoContextMenuAction(
            child: Text(
              bean.status! == 1 ? "运行" : "停止运行",
            ),
            trailingIcon: bean.status! == 1 ? CupertinoIcons.memories : CupertinoIcons.stop_circle,
            onPressed: () {
              Navigator.of(context).pop();
              if (bean.status! == 1) {
                startCron(context, ref);
              } else {
                stopCron(context, ref);
              }
            },
          ),
          QLCupertinoContextMenuAction(
            child: const Text("查看日志"),
            onPressed: () {
              Navigator.of(context).pop();
              logCron(context, ref);
            },
            trailingIcon: CupertinoIcons.clock,
          ),
          QLCupertinoContextMenuAction(
            child: const Text("编辑"),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.routeAddTask, arguments: bean);
            },
            trailingIcon: CupertinoIcons.pencil_outline,
          ),
          QLCupertinoContextMenuAction(
            child: Text(bean.isPinned! == 0 ? "置顶" : "取消置顶"),
            onPressed: () {
              Navigator.of(context).pop();
              pinTask();
            },
            trailingIcon: bean.isPinned! == 0 ? CupertinoIcons.pin : CupertinoIcons.pin_slash,
          ),
          QLCupertinoContextMenuAction(
            child: Text(bean.isDisabled! == 0 ? "禁用" : "启用"),
            onPressed: () {
              Navigator.of(context).pop();
              enableTask();
            },
            isDestructiveAction: true,
            trailingIcon: bean.isDisabled! == 0 ? Icons.dnd_forwardslash : Icons.check_circle_outline_sharp,
          ),
          QLCupertinoContextMenuAction(
            child: const Text("删除"),
            onPressed: () {
              Navigator.of(context).pop();
              delTask(context, ref);
            },
            isDestructiveAction: true,
            trailingIcon: CupertinoIcons.delete,
          ),
        ],
        previewBuilder: (context, anima, child) {
          bool isDark = ref.watch(themeProvider).darkMode;
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              color: isDark ? const Color(0xff333333) : Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.only(
                left: 5,
                right: 5,
                top: 5,
                bottom: isDark ? 5 : 20,
              ),
              child: SizedBox(
                height: 200,
                child: TaskDetailPage(
                  bean,
                  hideAppbar: true,
                ),
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              color: bean.isPinned == 1 ? ref.watch(themeProvider).themeColor.pinColor() : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            bean.status == 1
                                ? const SizedBox.shrink()
                                : SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ref.watch(themeProvider).primaryColor,
                                    ),
                                  ),
                            SizedBox(
                              width: bean.status == 1 ? 0 : 5,
                            ),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  bean.name ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: ref.watch(themeProvider).themeColor.titleColor(),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          (bean.lastExecutionTime == null || bean.lastExecutionTime == 0) ? "-" : Utils.formatMessageTime(bean.lastExecutionTime!),
                          maxLines: 1,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: ref.watch(themeProvider).themeColor.descColor(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bean.isDisabled == 1
                          ? const Icon(
                              Icons.dnd_forwardslash,
                              size: 12,
                              color: Colors.red,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(
                        width: 5,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          bean.schedule ?? "",
                          maxLines: 1,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: ref.watch(themeProvider).themeColor.descColor(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: Text(
                      bean.command ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: ref.watch(themeProvider).themeColor.descColor(),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              indent: 15,
            ),
          ],
        ),
      ),
    );
  }

  startCron(BuildContext context, WidgetRef ref) async {
    await ref.read(taskProvider).runCrons(bean.sId!);
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      logCron(context, ref);
    });
  }

  stopCron(BuildContext context, WidgetRef ref) {
    ref.read(taskProvider).stopCrons(bean.sId!);
  }

  logCron(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      showCupertinoDialog(
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(
                "${bean.name}运行日志",
                maxLines: 1,
                style: const TextStyle(overflow: TextOverflow.ellipsis),
              ),
              content: InTimeLogPage(bean.sId!, bean.status == 0),
              actions: [
                CupertinoDialogAction(
                  child: Text(
                    "知道了",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(taskProvider).loadData(false);
                  },
                ),
              ],
            );
          },
          context: context);
    });
  }

  void enableTask() {
    ref.read(taskProvider).enableTask(bean.sId!, bean.isDisabled!);
  }

  void pinTask() {
    ref.read(taskProvider).pinTask(bean.sId!, bean.isPinned!);
  }

  void delTask(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除定时任务 ${bean.name ?? ""} 吗"),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "取消",
              style: TextStyle(
                color: Color(0xff999999),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: Text(
              "确定",
              style: TextStyle(
                color: ref.watch(themeProvider).primaryColor,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(taskProvider).delCron(bean.sId!);
            },
          ),
        ],
      ),
    );
  }
}
