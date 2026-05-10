import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../l10n_extensions.dart';
import '../models.dart';

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
  return showModalBottomSheet<DrinkDefinition>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final viewInsets = MediaQuery.viewInsetsOf(context);
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
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
          ),
        ),
      );
    },
  );
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
    this.collapseAfterSelect = false,
    this.onCreateCustomDrink,
  });

  final List<DrinkDefinition> availableDrinks;
  final List<DrinkDefinition> recentDrinks;
  final String localeCode;
  final AppUnit unit;
  final DrinkDefinition? selectedDrink;
  final bool enabled;
  final ValueChanged<DrinkDefinition> onSelect;
  final bool collapseAfterSelect;
  final VoidCallback? onCreateCustomDrink;

  @override
  State<DrinkPickerCatalog> createState() => _DrinkPickerCatalogState();
}

class _DrinkPickerCatalogState extends State<DrinkPickerCatalog> {
  final _searchController = TextEditingController();
  DrinkCategory? _expandedCategory;
  bool _autoExpandSearchResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _expandedCategory = null;
      _autoExpandSearchResults = false;
    });
  }

  void _selectDrink(DrinkDefinition drink) {
    widget.onSelect(drink);
    if (!widget.collapseAfterSelect || !mounted) {
      return;
    }
    setState(() {
      _expandedCategory = null;
      _autoExpandSearchResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final search = _searchController.text.trim().toLowerCase();
    final isSearchActive = search.isNotEmpty;
    final expandsFromSearch = isSearchActive && _autoExpandSearchResults;
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
    final grouped = <DrinkCategory, List<DrinkDefinition>>{
      for (final category in DrinkCategory.values)
        category: <DrinkDefinition>[],
    };
    for (final drink in filteredDrinks) {
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
          onChanged: widget.enabled
              ? (_) {
                  setState(() {
                    _expandedCategory = null;
                    _autoExpandSearchResults = _searchController.text
                        .trim()
                        .isNotEmpty;
                  });
                }
              : null,
        ),
        const SizedBox(height: 20),
        if (widget.recentDrinks.isNotEmpty) ...<Widget>[
          Text(
            l10n.recentDrinks,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.recentDrinks
                .map(
                  (drink) => ChoiceChip(
                    selected: widget.selectedDrink?.id == drink.id,
                    showCheckmark: false,
                    avatar: Icon(
                      drink.category.icon,
                      key: Key('recent-drink-icon-${drink.id}'),
                      size: 18,
                    ),
                    label: Text(
                      drink.shouldShowAlcoholFreeMarker
                          ? '${drink.displayName(widget.localeCode)} • ${l10n.alcoholFree}'
                          : drink.displayName(widget.localeCode),
                    ),
                    onSelected: widget.enabled
                        ? (_) => _selectDrink(drink)
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Text(
              l10n.catalog,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
            final action = widget.onCreateCustomDrink == null
                ? null
                : FilledButton.tonal(
                    onPressed: widget.enabled
                        ? widget.onCreateCustomDrink
                        : null,
                    child: Text(l10n.createCustomDrink),
                  );

            if (action == null) {
              return heading;
            }

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
        ),
        const SizedBox(height: 12),
        ...DrinkCategory.values.map(
          (category) => _DrinkCategorySection(
            category: category,
            label: l10n.categoryLabel(category),
            drinks: grouped[category]!,
            localeCode: widget.localeCode,
            unit: widget.unit,
            isExpanded: expandsFromSearch
                ? grouped[category]!.isNotEmpty
                : _expandedCategory == category,
            isInteractive: !expandsFromSearch,
            enabled: widget.enabled,
            onExpansionChanged: (isExpanded) {
              setState(() {
                _expandedCategory = isExpanded ? category : null;
              });
            },
            selectedDrink: widget.selectedDrink,
            onSelect: _selectDrink,
          ),
        ),
      ],
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
    required this.isExpanded,
    required this.isInteractive,
    required this.enabled,
    required this.onExpansionChanged,
    required this.selectedDrink,
    required this.onSelect,
  });

  final DrinkCategory category;
  final String label;
  final List<DrinkDefinition> drinks;
  final String localeCode;
  final AppUnit unit;
  final bool isExpanded;
  final bool isInteractive;
  final bool enabled;
  final ValueChanged<bool> onExpansionChanged;
  final DrinkDefinition? selectedDrink;
  final ValueChanged<DrinkDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key('drink-category-section-${category.name}-$isExpanded'),
        initiallyExpanded: isExpanded,
        enabled: enabled && isInteractive,
        onExpansionChanged: enabled ? onExpansionChanged : null,
        tilePadding: EdgeInsets.zero,
        title: Text(label, key: Key('drink-category-title-${category.name}')),
        children: drinks
            .map((drink) {
              final metadata = <String>[
                if (drink.shouldShowAlcoholFreeMarker) l10n.alcoholFree,
                if (drink.volumeMl != null) unit.formatVolume(drink.volumeMl),
              ].join(' • ');
              return ListTile(
                dense: true,
                leading: Icon(drink.category.icon),
                title: Text(drink.displayName(localeCode)),
                subtitle: metadata.isEmpty ? null : Text(metadata),
                trailing: selectedDrink?.id == drink.id
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: enabled ? () => onSelect(drink) : null,
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
