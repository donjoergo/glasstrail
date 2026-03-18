import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_scope.dart';
import '../models.dart';
import 'custom_drink_dialog.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _commentController = TextEditingController();
  final _volumeController = TextEditingController();

  DrinkDefinition? _selectedDrink;
  DrinkCategory? _expandedCategory;
  String? _imagePath;
  bool _autoExpandSearchResults = false;
  bool _volumeEditedManually = false;

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await AppScope.photoServiceOf(context).pickImage();
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _imagePath = path;
    });
  }

  Future<void> _openCustomDrinkDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const CustomDrinkDialog(),
    );
    if (!mounted) {
      return;
    }
    final message = AppScope.controllerOf(context).takeFlashMessage();
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _expandedCategory = null;
      _autoExpandSearchResults = false;
    });
  }

  void _selectDrink(DrinkDefinition drink) {
    final unit = AppScope.controllerOf(context).settings.unit;
    setState(() {
      _selectedDrink = drink;
      _expandedCategory = null;
      _autoExpandSearchResults = false;
      _volumeEditedManually = false;
      _volumeController.text = unit.formatVolumeInput(drink.volumeMl);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _selectedDrink == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRequired)));
      return;
    }

    final controller = AppScope.controllerOf(context);
    final volume = double.tryParse(_volumeController.text.trim());
    final success = await controller.addDrinkEntry(
      drink: _selectedDrink!,
      volumeMl: _volumeEditedManually
          ? (volume == null
                ? _selectedDrink!.volumeMl
                : controller.settings.unit.convertToMl(volume))
          : _selectedDrink!.volumeMl,
      comment: _commentController.text,
      imagePath: _imagePath,
    );
    if (!mounted) {
      return;
    }
    final message = controller.takeFlashMessage();
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.controllerOf(context);
    final theme = Theme.of(context);
    final localeCode = controller.settings.localeCode;
    final unit = controller.settings.unit;
    final search = _searchController.text.trim().toLowerCase();
    final isSearchActive = search.isNotEmpty;
    final expandsFromSearch = isSearchActive && _autoExpandSearchResults;
    final filteredDrinks = controller.availableDrinks.where((drink) {
      if (search.isEmpty) {
        return true;
      }
      return drink.displayName(localeCode).toLowerCase().contains(search);
    }).toList();
    final grouped = <DrinkCategory, List<DrinkDefinition>>{
      for (final category in DrinkCategory.values)
        category: <DrinkDefinition>[],
    };
    for (final drink in filteredDrinks) {
      grouped[drink.category]!.add(drink);
    }
    for (final drinks in grouped.values) {
      drinks.sort(
        (left, right) => left
            .displayName(localeCode)
            .compareTo(right.displayName(localeCode)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addDrink)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  key: const Key('drink-search-field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: l10n.searchDrinks,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('drink-search-clear-button'),
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) {
                    setState(() {
                      _expandedCategory = null;
                      _autoExpandSearchResults = _searchController.text
                          .trim()
                          .isNotEmpty;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (controller.recentDrinks.isNotEmpty) ...<Widget>[
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
                    children: controller.recentDrinks
                        .map(
                          (drink) => ChoiceChip(
                            selected: _selectedDrink?.id == drink.id,
                            avatar: Icon(
                              drink.category.icon,
                              key: Key('recent-drink-icon-${drink.id}'),
                              size: 18,
                            ),
                            label: Text(drink.displayName(localeCode)),
                            onSelected: (_) => _selectDrink(drink),
                          ),
                        )
                        .toList(),
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
                    final action = FilledButton.tonal(
                      onPressed: _openCustomDrinkDialog,
                      child: Text(l10n.createCustomDrink),
                    );

                    if (constraints.maxWidth < 480) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          heading,
                          const SizedBox(height: 12),
                          action,
                        ],
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
                    localeCode: localeCode,
                    unit: unit,
                    isExpanded: expandsFromSearch
                        ? grouped[category]!.isNotEmpty
                        : _expandedCategory == category,
                    isInteractive: !expandsFromSearch,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        _expandedCategory = isExpanded ? category : null;
                      });
                    },
                    selectedDrink: _selectedDrink,
                    onSelect: _selectDrink,
                  ),
                ),
                if (_selectedDrink != null) ...<Widget>[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selectedDrink!.displayName(localeCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.categoryLabel(_selectedDrink!.category)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('drink-volume-field'),
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '${l10n.volume} (${l10n.unitLabel(unit)})',
                    ),
                    onChanged: (_) {
                      _volumeEditedManually = true;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('drink-comment-field'),
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: '${l10n.comment} (${l10n.optional})',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _imagePath == null
                              ? l10n.pickPhoto
                              : l10n.changePhoto,
                        ),
                      ),
                      if (_imagePath != null) ...<Widget>[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _imagePath!.split(RegExp(r'[\\/]')).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _imagePath = null;
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('confirm-drink-button'),
                    onPressed: controller.isBusy ? null : _save,
                    child: Text(l10n.confirmDrink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  final ValueChanged<bool> onExpansionChanged;
  final DrinkDefinition? selectedDrink;
  final ValueChanged<DrinkDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key('drink-category-section-${category.name}-$isExpanded'),
        initiallyExpanded: isExpanded,
        enabled: isInteractive,
        onExpansionChanged: onExpansionChanged,
        tilePadding: EdgeInsets.zero,
        title: Text(label, key: Key('drink-category-title-${category.name}')),
        children: drinks
            .map(
              (drink) => ListTile(
                dense: true,
                leading: Icon(drink.category.icon),
                title: Text(drink.displayName(localeCode)),
                subtitle: drink.volumeMl == null
                    ? null
                    : Text(unit.formatVolume(drink.volumeMl)),
                trailing: selectedDrink?.id == drink.id
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () => onSelect(drink),
              ),
            )
            .toList(),
      ),
    );
  }
}
