import 'package:flutter/material.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import '../models.dart';
import 'drink_picker_catalog.dart';

/// The mobile add-drink wizard's second step: every drink in a single
/// [category], with a local filter field scoped to that category.
class DrinkCategoryGrid extends StatefulWidget {
  const DrinkCategoryGrid({
    super.key,
    required this.category,
    required this.drinks,
    required this.localeCode,
    required this.unit,
    required this.selectedDrink,
    required this.enabled,
    required this.onSelect,
  });

  final DrinkCategory category;
  final List<DrinkDefinition> drinks;
  final String localeCode;
  final AppUnit unit;
  final DrinkDefinition? selectedDrink;
  final bool enabled;
  final ValueChanged<DrinkDefinition> onSelect;

  @override
  State<DrinkCategoryGrid> createState() => _DrinkCategoryGridState();
}

class _DrinkCategoryGridState extends State<DrinkCategoryGrid> {
  final _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _filterController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.drinks
        : widget.drinks
              .where(
                (drink) => drink
                    .displayName(widget.localeCode)
                    .toLowerCase()
                    .contains(query),
              )
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          key: const Key('drink-category-filter-field'),
          controller: _filterController,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: l10n.searchDrinks,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _filterController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: widget.enabled
                        ? () => setState(_filterController.clear)
                        : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: widget.enabled ? (_) => setState(() {}) : null,
        ),
        const SizedBox(height: 16),
        DrinkGridCard.grid(
          drinks: filtered,
          localeCode: widget.localeCode,
          unit: widget.unit,
          selectedDrink: widget.selectedDrink,
          enabled: widget.enabled,
          onSelect: widget.onSelect,
        ),
      ],
    );
  }
}
