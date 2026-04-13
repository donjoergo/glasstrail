import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_routes.dart';
import '../app_controller.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import '../widgets/app_empty_state_card.dart';
import 'custom_drink_dialog.dart';

class BarScreen extends StatefulWidget {
  const BarScreen({
    super.key,
    required this.routeName,
    required this.onRouteSelected,
  });

  final String routeName;
  final ValueChanged<String> onRouteSelected;

  @override
  State<BarScreen> createState() => _BarScreenState();
}

class _BarScreenState extends State<BarScreen>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 2;
  static const _settledTabOffsetEpsilon = 0.0001;

  late final TabController _tabController;
  bool _isUpdatingControllerFromRoute = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: AppRoutes.barTabIndexForRoute(widget.routeName),
    )..addListener(_handleTabControllerChange);
  }

  @override
  void didUpdateWidget(covariant BarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = AppRoutes.barTabIndexForRoute(widget.routeName);
    if (_tabController.index == targetIndex) {
      return;
    }
    _isUpdatingControllerFromRoute = true;
    _tabController.index = targetIndex;
    _isUpdatingControllerFromRoute = false;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabControllerChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabControllerChange() {
    if (_isUpdatingControllerFromRoute ||
        !mounted ||
        _tabController.indexIsChanging ||
        _tabController.offset.abs() > _settledTabOffsetEpsilon) {
      return;
    }

    final currentIndex = AppRoutes.barTabIndexForRoute(widget.routeName);
    if (_tabController.index == currentIndex) {
      return;
    }

    widget.onRouteSelected(AppRoutes.barRouteForIndex(_tabController.index));
  }

  Future<void> _showCustomDrinkDialog([DrinkDefinition? drink]) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (_) => CustomDrinkDialog(initialDrink: drink),
    );
    if (!mounted) {
      return;
    }
    final message = AppScope.controllerOf(context).takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _runCatalogAction(
    Future<bool> Function(AppController controller) action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final success = await action(controller);
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage(l10n);
    if (message != null) {
      _showMessage(message);
      return;
    }
    if (!success) {
      _showMessage(l10n.somethingWentWrong);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              key: const Key('bar-tab-bar'),
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: <Widget>[
                Tab(
                  key: const Key('bar-sort-tab'),
                  text: l10n.barDrinkSortingTab,
                ),
                Tab(
                  key: const Key('bar-custom-tab'),
                  text: l10n.barCustomDrinksTab,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _BarDrinkSortingTab(runCatalogAction: _runCatalogAction),
              _BarCustomDrinksTab(
                showCustomDrinkDialog: _showCustomDrinkDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarDrinkSortingTab extends StatelessWidget {
  const _BarDrinkSortingTab({required this.runCatalogAction});

  final Future<void> Function(Future<bool> Function(AppController controller))
  runCatalogAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final unit = controller.settings.unit;
    final isBusy = controller.isBusy;
    final isUpdatingCatalog = controller.isBusyFor(
      AppBusyAction.updateSettings,
    );

    return ListView(
      key: const Key('bar-sort-list-view'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: <Widget>[
        Container(
          key: const Key('bar-global-section'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.barDrinkSortingTab,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.barGlobalDrinksBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isUpdatingCatalog) ...<Widget>[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 20),
              ...DrinkCategory.values.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GlobalDrinkCategoryCard(
                    category: category,
                    categoryHidden: controller.isGlobalCategoryHidden(category),
                    sortableDrinks: controller.sortableDrinksForCategory(
                      category,
                    ),
                    hiddenDrinks: controller.hiddenGlobalDrinksForCategory(
                      category,
                    ),
                    enabled: !isBusy,
                    unit: unit,
                    onHideDrink: (drinkId) => runCatalogAction(
                      (controller) => controller.hideGlobalDrink(drinkId),
                    ),
                    onShowDrink: (drinkId) => runCatalogAction(
                      (controller) => controller.showGlobalDrink(drinkId),
                    ),
                    onHideCategory: () => runCatalogAction(
                      (controller) => controller.hideGlobalCategory(category),
                    ),
                    onShowCategory: () => runCatalogAction(
                      (controller) => controller.showGlobalCategory(category),
                    ),
                    onReorder: (orderedDrinkIds) => runCatalogAction(
                      (controller) => controller.reorderGlobalDrinks(
                        category: category,
                        orderedDrinkIds: orderedDrinkIds,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarCustomDrinksTab extends StatelessWidget {
  const _BarCustomDrinksTab({required this.showCustomDrinkDialog});

  final Future<void> Function([DrinkDefinition? drink]) showCustomDrinkDialog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final unit = controller.settings.unit;
    final isBusy = controller.isBusy;

    return ListView(
      key: const Key('bar-custom-list-view'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: <Widget>[
        Container(
          key: const Key('bar-custom-drinks-section'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.customDrinks,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    key: const Key('bar-add-custom-drink-button'),
                    onPressed: isBusy ? null : () => showCustomDrinkDialog(),
                    child: Text(l10n.addCustomDrinkAction),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.barCustomDrinksBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (controller.customDrinks.isEmpty)
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: AppEmptyStateCard(
                      key: const Key('bar-custom-empty-state'),
                      icon: Icons.local_bar_outlined,
                      title: l10n.customDrinksEmptyTitle,
                      body: l10n.customDrinksEmptyBody,
                    ),
                  ),
                )
              else
                ...controller.customDrinks.map(
                  (drink) => ListTile(
                    key: Key('bar-custom-drink-${drink.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        drink.category.icon,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(drink.name),
                    subtitle: Text(
                      '${l10n.categoryLabel(drink.category)} • ${unit.formatVolume(drink.volumeMl)}',
                    ),
                    trailing: IconButton(
                      key: Key('bar-edit-custom-drink-${drink.id}'),
                      onPressed: isBusy
                          ? null
                          : () => showCustomDrinkDialog(drink),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlobalDrinkCategoryCard extends StatelessWidget {
  const _GlobalDrinkCategoryCard({
    required this.category,
    required this.categoryHidden,
    required this.sortableDrinks,
    required this.hiddenDrinks,
    required this.enabled,
    required this.unit,
    required this.onHideDrink,
    required this.onShowDrink,
    required this.onHideCategory,
    required this.onShowCategory,
    required this.onReorder,
  });

  final DrinkCategory category;
  final bool categoryHidden;
  final List<DrinkDefinition> sortableDrinks;
  final List<DrinkDefinition> hiddenDrinks;
  final bool enabled;
  final AppUnit unit;
  final ValueChanged<String> onHideDrink;
  final ValueChanged<String> onShowDrink;
  final VoidCallback onHideCategory;
  final VoidCallback onShowCategory;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: Key('bar-category-card-${category.storageValue}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: theme.colorScheme.primary,
                child: Icon(category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.categoryLabel(category),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                key: Key(
                  categoryHidden
                      ? 'bar-show-category-${category.storageValue}'
                      : 'bar-hide-category-${category.storageValue}',
                ),
                onPressed: enabled
                    ? (categoryHidden ? onShowCategory : onHideCategory)
                    : null,
                icon: Icon(
                  categoryHidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                label: Text(
                  categoryHidden ? l10n.showCategory : l10n.hideCategory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sortableDrinks.isEmpty)
            Text(
              l10n.allGlobalDrinksHidden,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ReorderableListView.builder(
              key: Key('bar-visible-list-${category.storageValue}'),
              shrinkWrap: true,
              primary: false,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortableDrinks.length,
              onReorder: enabled
                  ? (oldIndex, newIndex) {
                      final reordered = sortableDrinks.toList(growable: true);
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final movedDrink = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, movedDrink);
                      onReorder(
                        reordered
                            .map((drink) => drink.id)
                            .toList(growable: false),
                      );
                    }
                  : (_, _) {},
              itemBuilder: (context, index) {
                final drink = sortableDrinks[index];
                final itemKey = drink.isCustom
                    ? ValueKey('bar-visible-custom-drink-${drink.id}')
                    : ValueKey('bar-visible-global-drink-${drink.id}');
                return ListTile(
                  key: itemKey,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    drink.category.icon,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(drink.displayName(l10n.locale.languageCode)),
                  subtitle: drink.volumeMl == null
                      ? null
                      : Text(unit.formatVolume(drink.volumeMl)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!drink.isCustom)
                        IconButton(
                          key: Key('bar-hide-global-drink-${drink.id}'),
                          tooltip: l10n.hideDrink,
                          onPressed: enabled
                              ? () => onHideDrink(drink.id)
                              : null,
                          icon: const Icon(Icons.visibility_off_rounded),
                        ),
                      ReorderableDragStartListener(
                        index: index,
                        enabled: enabled,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            key: Key('bar-reorder-global-drink-${drink.id}'),
                            color: enabled
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.disabledColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (hiddenDrinks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Divider(),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: Key('bar-hidden-section-${category.storageValue}'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.hiddenDrinks,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: hiddenDrinks
                    .map(
                      (drink) => ListTile(
                        key: Key('bar-hidden-global-drink-${drink.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.visibility_off_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          drink.displayName(l10n.locale.languageCode),
                        ),
                        subtitle: drink.volumeMl == null
                            ? null
                            : Text(unit.formatVolume(drink.volumeMl)),
                        trailing: TextButton.icon(
                          key: Key('bar-unhide-global-drink-${drink.id}'),
                          onPressed: enabled && !categoryHidden
                              ? () => onShowDrink(drink.id)
                              : null,
                          icon: const Icon(Icons.visibility_rounded),
                          label: Text(l10n.showDrink),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
