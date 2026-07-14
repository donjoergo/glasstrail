import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../app_breakpoints.dart';
import '../app_scope.dart';
import '../l10n_extensions.dart';
import '../models.dart';
import 'adaptive_modal.dart';
import 'app_media.dart';

Future<DrinkDefinition?> showDrinkPickerSheet({
  required BuildContext context,
  required String title,
  required List<DrinkDefinition> availableDrinks,
  required List<DrinkDefinition> recentDrinks,
  required String localeCode,
  required AppUnit unit,
  DrinkDefinition? selectedDrink,
  bool enabled = true,
  VoidCallback? onCreateCustomDrink,
}) {
  return showAdaptiveSheetOrDialog<DrinkDefinition>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    dialogMaxHeightFactor: 0.9,
    builder: (context) {
      final theme = Theme.of(context);
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('drink-picker-close-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: DrinkPickerCatalog(
                availableDrinks: availableDrinks,
                recentDrinks: recentDrinks,
                localeCode: localeCode,
                unit: unit,
                selectedDrink: selectedDrink,
                enabled: enabled,
                onCreateCustomDrink: onCreateCustomDrink,
                onSelect: (drink) => Navigator.of(context).pop(drink),
              ),
            ),
          ),
        ],
      );

      if (AppBreakpoints.isExpanded(context)) {
        return content;
      }

      // Sheet-only chrome: keyboard insets and the 90% height factor.
      final viewInsets = MediaQuery.viewInsetsOf(context);
      return Padding(
        // Keeps the search field above the on-screen keyboard instead of
        // being covered by it.
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(heightFactor: 0.9, child: content),
      );
    },
  );
}

/// Which top-level view [DrinkPickerCatalog] renders below the search field
/// and recents (while a search isn't active).
enum DrinkCatalogMode {
  /// Every category rendered as a label + always-visible card grid, one
  /// after another. Used by the desktop pane and [showDrinkPickerSheet].
  flattened,

  /// A grid of category tiles (name + drink count) instead of individual
  /// drinks. Used by the mobile add-drink wizard's first step; tapping a
  /// tile is reported via [DrinkPickerCatalog.onSelectCategory] instead of
  /// [DrinkPickerCatalog.onSelect].
  categoryTiles,
}

/// Card grid column count for a given available [width], so the grid
/// naturally densifies on wider panes (desktop two-pane, wide sheets)
/// without hardcoding device breakpoints.
int drinkGridColumnsForWidth(double width) {
  return (width / 150).floor().clamp(2, 5);
}

/// Category tile column count for a given available [width]. Tiles are
/// larger than drink cards, so this uses its own breakpoints rather than
/// [drinkGridColumnsForWidth] — notably a step up to 4 columns on wider
/// "mobile" widths (large phones landscape, tablets under the desktop
/// two-pane breakpoint) instead of staying capped at 3.
int _categoryTileColumnsForWidth(double width) {
  if (width >= 700) {
    return 4;
  }
  if (width >= 420) {
    return 3;
  }
  return 2;
}

class DrinkPickerCatalog extends StatefulWidget {
  const DrinkPickerCatalog({
    super.key,
    required this.availableDrinks,
    required this.recentDrinks,
    required this.localeCode,
    required this.unit,
    required this.selectedDrink,
    required this.enabled,
    required this.onSelect,
    this.mode = DrinkCatalogMode.flattened,
    this.onSelectCategory,
    this.onCreateCustomDrink,
  }) : assert(
         mode != DrinkCatalogMode.categoryTiles || onSelectCategory != null,
         'onSelectCategory is required when mode is categoryTiles',
       );

  final List<DrinkDefinition> availableDrinks;
  final List<DrinkDefinition> recentDrinks;
  final String localeCode;
  final AppUnit unit;
  final DrinkDefinition? selectedDrink;
  final bool enabled;
  final ValueChanged<DrinkDefinition> onSelect;
  final DrinkCatalogMode mode;
  final ValueChanged<DrinkCategory>? onSelectCategory;
  final VoidCallback? onCreateCustomDrink;

  @override
  State<DrinkPickerCatalog> createState() => _DrinkPickerCatalogState();
}

class _DrinkPickerCatalogState extends State<DrinkPickerCatalog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(_searchController.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = AppScope.controllerOf(context);
    final search = _searchController.text.trim().toLowerCase();
    final isSearchActive = search.isNotEmpty;
    final filteredDrinks = widget.availableDrinks
        .where((drink) {
          if (search.isEmpty) {
            return true;
          }
          return drink
              .displayName(widget.localeCode)
              .toLowerCase()
              .contains(search);
        })
        .toList(growable: false);
    // Pre-seed every category so the map lookup below (`grouped[...]!`)
    // never needs a null check, and categories with zero matches are simply
    // skipped when rendering instead of needing a separate branch.
    final grouped = <DrinkCategory, List<DrinkDefinition>>{
      for (final category in DrinkCategory.values)
        category: <DrinkDefinition>[],
    };
    for (final drink in widget.availableDrinks) {
      grouped[drink.category]!.add(drink);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          key: const Key('drink-search-field'),
          controller: _searchController,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: l10n.searchDrinks,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('drink-search-clear-button'),
                    onPressed: widget.enabled ? _clearSearch : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: widget.enabled ? (_) => setState(() {}) : null,
        ),
        const SizedBox(height: 20),
        if (isSearchActive)
          _DrinkSearchResults(
            query: _searchController.text.trim(),
            results: filteredDrinks,
            localeCode: widget.localeCode,
            unit: widget.unit,
            selectedDrink: widget.selectedDrink,
            enabled: widget.enabled,
            onSelect: widget.onSelect,
            onCreateCustomDrink: widget.onCreateCustomDrink,
          )
        else ...<Widget>[
          if (widget.recentDrinks.isNotEmpty) ...<Widget>[
            Text(
              l10n.recentDrinks,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _RecentDrinkChips(
              // Capped so recents take at most two wrapped rows no matter
              // how many the user has, keeping catalog/category content
              // right below at a predictable scroll position.
              drinks: widget.recentDrinks.take(4).toList(growable: false),
              localeCode: widget.localeCode,
              selectedDrink: widget.selectedDrink,
              enabled: widget.enabled,
              onSelect: widget.onSelect,
            ),
            const SizedBox(height: 20),
          ],
          _CatalogHeading(
            mode: widget.mode,
            onCreateCustomDrink: widget.onCreateCustomDrink,
            enabled: widget.enabled,
          ),
          const SizedBox(height: 12),
          if (widget.mode == DrinkCatalogMode.categoryTiles)
            _CategoryTileGrid(
              grouped: grouped,
              orderedCategories: controller.orderedCategories,
              enabled: widget.enabled,
              onSelectCategory: widget.onSelectCategory!,
            )
          else
            ...controller.orderedCategories.map(
              (category) => _DrinkCategorySection(
                category: category,
                label: l10n.categoryLabel(category),
                drinks: grouped[category]!,
                localeCode: widget.localeCode,
                unit: widget.unit,
                enabled: widget.enabled,
                selectedDrink: widget.selectedDrink,
                onSelect: widget.onSelect,
              ),
            ),
        ],
      ],
    );
  }
}

class _CatalogHeading extends StatelessWidget {
  const _CatalogHeading({
    required this.mode,
    required this.onCreateCustomDrink,
    required this.enabled,
  });

  final DrinkCatalogMode mode;
  final VoidCallback? onCreateCustomDrink;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final heading = Text(
      mode == DrinkCatalogMode.categoryTiles
          ? l10n.addDrinkCategoriesHeading
          : l10n.catalog,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    final action = onCreateCustomDrink == null
        ? null
        : FilledButton.tonal(
            onPressed: enabled ? onCreateCustomDrink : null,
            child: Text(l10n.createCustomDrink),
          );

    if (action == null) {
      return heading;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack the "create custom drink" action under the heading on
        // narrow layouts instead of squeezing it into a Row, where it
        // would truncate or wrap awkwardly next to the heading text.
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[heading, const SizedBox(height: 12), action],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: heading),
            action,
          ],
        );
      },
    );
  }
}

class _RecentDrinkChips extends StatelessWidget {
  const _RecentDrinkChips({
    required this.drinks,
    required this.localeCode,
    required this.selectedDrink,
    required this.enabled,
    required this.onSelect,
  });

  final List<DrinkDefinition> drinks;
  final String localeCode;
  final DrinkDefinition? selectedDrink;
  final bool enabled;
  final ValueChanged<DrinkDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap chip width so exactly 2 fit per row (max 2 rows for 4 chips)
        // regardless of drink name length, keeping recents a predictable
        // height instead of growing with long names.
        final chipMaxWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: drinks
              .map(
                (drink) => ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: chipMaxWidth),
                  child: ChoiceChip(
                    key: Key('recent-drink-chip-${drink.id}'),
                    selected: selectedDrink?.id == drink.id,
                    showCheckmark: false,
                    avatar: AppAvatar(
                      key: Key('recent-drink-icon-${drink.id}'),
                      imagePath: drink.imagePath,
                      radius: 9,
                      backgroundColor: Colors.transparent,
                      fallback: Icon(drink.category.icon, size: 18),
                    ),
                    label: Text(
                      drink.displayName(localeCode),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onSelected: enabled ? (_) => onSelect(drink) : null,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DrinkSearchResults extends StatelessWidget {
  const _DrinkSearchResults({
    required this.query,
    required this.results,
    required this.localeCode,
    required this.unit,
    required this.selectedDrink,
    required this.enabled,
    required this.onSelect,
    required this.onCreateCustomDrink,
  });

  final String query;
  final List<DrinkDefinition> results;
  final String localeCode;
  final AppUnit unit;
  final DrinkDefinition? selectedDrink;
  final bool enabled;
  final ValueChanged<DrinkDefinition> onSelect;
  final VoidCallback? onCreateCustomDrink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.addDrinkSearchResultsCount(results.length),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...results.map((drink) {
          final metadata = <String>[
            if (drink.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
            if (drink.volumeMl != null) unit.formatVolume(drink.volumeMl),
          ].join(' • ');
          return ListTile(
            key: Key('drink-search-result-${drink.id}'),
            contentPadding: EdgeInsets.zero,
            leading: AppAvatar(
              imagePath: drink.imagePath,
              radius: 20,
              backgroundColor: Colors.transparent,
              fallback: Icon(drink.category.icon),
            ),
            title: Text(drink.displayName(localeCode)),
            subtitle: metadata.isEmpty ? null : Text(metadata),
            trailing: selectedDrink?.id == drink.id
                ? const Icon(Icons.check_circle_rounded)
                : null,
            onTap: enabled ? () => onSelect(drink) : null,
          );
        }),
        if (onCreateCustomDrink != null) ...<Widget>[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              key: const Key('drink-search-create-custom-button'),
              onPressed: enabled ? onCreateCustomDrink : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.createCustomDrinkWithQuery(query)),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTileGrid extends StatelessWidget {
  const _CategoryTileGrid({
    required this.grouped,
    required this.orderedCategories,
    required this.enabled,
    required this.onSelectCategory,
  });

  final Map<DrinkCategory, List<DrinkDefinition>> grouped;
  final List<DrinkCategory> orderedCategories;
  final bool enabled;
  final ValueChanged<DrinkCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = orderedCategories
        .where((category) => grouped[category]!.isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _categoryTileColumnsForWidth(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // A fixed height (rather than childAspectRatio) keeps the
            // larger icon/text from overflowing as columns narrow at
            // higher densities.
            mainAxisExtent: 108,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = grouped[category]!.length;
            return Material(
              key: Key('drink-category-tile-${category.name}'),
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: enabled ? () => onSelectCategory(category) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        category.icon,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.categoryLabel(category),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.addDrinkCategoryDrinkCount(count),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DrinkCategorySection extends StatelessWidget {
  const _DrinkCategorySection({
    required this.category,
    required this.label,
    required this.drinks,
    required this.localeCode,
    required this.unit,
    required this.enabled,
    required this.selectedDrink,
    required this.onSelect,
  });

  final DrinkCategory category;
  final String label;
  final List<DrinkDefinition> drinks;
  final String localeCode;
  final AppUnit unit;
  final bool enabled;
  final DrinkDefinition? selectedDrink;
  final ValueChanged<DrinkDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      // Extra bottom space between category sections so denser, larger
      // cards (with icons) don't feel cramped against the next heading.
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            key: Key('drink-category-title-${category.name}'),
            children: <Widget>[
              Icon(
                category.icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DrinkGridCard.grid(
            drinks: drinks,
            localeCode: localeCode,
            unit: unit,
            selectedDrink: selectedDrink,
            enabled: enabled,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

/// A tappable card for one drink, showing its name and volume. Used by the
/// flattened per-category grids and the mobile category-drink grid.
class DrinkGridCard extends StatelessWidget {
  const DrinkGridCard({
    super.key,
    required this.drink,
    required this.localeCode,
    required this.unit,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final DrinkDefinition drink;
  final String localeCode;
  final AppUnit unit;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  /// Lays out [drinks] as a card grid whose column count grows with the
  /// available width, via [drinkGridColumnsForWidth].
  static Widget grid({
    required List<DrinkDefinition> drinks,
    required String localeCode,
    required AppUnit unit,
    required DrinkDefinition? selectedDrink,
    required bool enabled,
    required ValueChanged<DrinkDefinition> onSelect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = drinkGridColumnsForWidth(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // A fixed height (rather than childAspectRatio) keeps the icon
            // and larger text from overflowing as columns narrow at higher
            // densities; taller than the category tile's extent since a
            // drink name can wrap to 2 lines where a category label can't.
            mainAxisExtent: 120,
          ),
          itemCount: drinks.length,
          itemBuilder: (context, index) {
            final drink = drinks[index];
            return DrinkGridCard(
              key: Key('drink-card-${drink.id}'),
              drink: drink,
              localeCode: localeCode,
              unit: unit,
              isSelected: selectedDrink?.id == drink.id,
              enabled: enabled,
              onTap: () => onSelect(drink),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mirrors the category tile's layout (icon on top, stacked text below)
    // so step 1 and step 2 — and the desktop/sheet catalog grid, which
    // shares this widget — read as one consistent card style.
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppAvatar(
                imagePath: drink.imagePath,
                radius: 15,
                backgroundColor: Colors.transparent,
                fallback: Icon(
                  drink.category.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                drink.displayName(localeCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (drink.volumeMl != null)
                Text(
                  unit.formatVolume(drink.volumeMl),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
