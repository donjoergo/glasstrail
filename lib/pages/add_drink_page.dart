import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:glasstrail/l10n/l10n.dart';
import 'package:glasstrail/models/app_models.dart';
import 'package:glasstrail/state/app_controller.dart';

class AddDrinkPage extends StatefulWidget {
  const AddDrinkPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AddDrinkPage> createState() => _AddDrinkPageState();
}

class _AddDrinkPageState extends State<AddDrinkPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _currentStep = 0;
  DrinkType? _selectedDrink;
  String? _imagePath;
  bool _isSaving = false;
  final Set<String> _taggedFriendIds = <String>{};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) {
      return;
    }

    final file = result.files.single;
    setState(() {
      _imagePath = file.path;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.requiredDrinkError)));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.controller.addDrink(
      drink: _selectedDrink!,
      comment: _commentController.text,
      imagePath: _imagePath,
      taggedFriendIds: _taggedFriendIds.toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.drinkSavedSnack)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addDrinkTitle)),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() {
            _currentStep = step;
          }),
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 3;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (!isLast)
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(l10n.next),
                    ),
                  if (isLast)
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? l10n.saving : l10n.submitDrink),
                    ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.back),
                    ),
                ],
              ),
            );
          },
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() {
                _currentStep += 1;
              });
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            Step(
              title: Text(l10n.stepDrink),
              isActive: _currentStep >= 0,
              content: _DrinkSelectionStep(
                controller: widget.controller,
                selectedDrink: _selectedDrink,
                onSelected: (drink) => setState(() {
                  _selectedDrink = drink;
                }),
              ),
            ),
            Step(
              title: Text(l10n.stepMedia),
              isActive: _currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _imagePath == null ? l10n.pickPhoto : l10n.changePhoto,
                    ),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(hintText: l10n.commentHint),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.stepFriends),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taggedFriends,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.controller.acceptedFriends
                        .map(
                          (friend) => FilterChip(
                            label: Text(friend.name),
                            selected: _taggedFriendIds.contains(friend.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _taggedFriendIds.add(friend.id);
                                } else {
                                  _taggedFriendIds.remove(friend.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.stepConfirm),
              isActive: _currentStep >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selectedDrink?.name ?? '-'),
                    subtitle:
                        Text(_selectedDrink?.category.defaultLabel ?? '-'),
                  ),
                  if (_commentController.text.trim().isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.comment),
                      subtitle: Text(_commentController.text.trim()),
                    ),
                  if (_taggedFriendIds.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.withFriends),
                      subtitle: Text(
                        widget.controller.acceptedFriends
                            .where((f) => _taggedFriendIds.contains(f.id))
                            .map((f) => f.name)
                            .join(', '),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkSelectionStep extends StatelessWidget {
  const _DrinkSelectionStep({
    required this.controller,
    required this.selectedDrink,
    required this.onSelected,
  });

  final AppController controller;
  final DrinkType? selectedDrink;
  final ValueChanged<DrinkType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = <DrinkType>[];
    final seen = <String>{};

    for (final log in controller.logs) {
      DrinkType? match;
      for (final drink in controller.drinkCatalog) {
        if (drink.name == log.drinkName) {
          match = drink;
          break;
        }
      }
      if (match != null && !seen.contains(match.id)) {
        recent.add(match);
        seen.add(match.id);
      }
      if (recent.length == 4) {
        break;
      }
    }

    final grouped = <DrinkCategory, List<DrinkType>>{
      for (final category in DrinkCategory.values) category: <DrinkType>[],
    };
    for (final drink in controller.drinkCatalog) {
      grouped[drink.category]!.add(drink);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchAnchor.bar(
          barHintText: l10n.searchDrinkHint,
          suggestionsBuilder: (context, controllerSearch) {
            final query = controllerSearch.text.trim().toLowerCase();
            final results = controller.drinkCatalog.where((drink) {
              if (query.isEmpty) {
                return true;
              }
              return drink.name.toLowerCase().contains(query) ||
                  drink.category.defaultLabel.toLowerCase().contains(query);
            }).toList();

            return results
                .map(
                  (drink) => ListTile(
                    title: Text(drink.name),
                    subtitle: Text(drink.category.defaultLabel),
                    onTap: () {
                      onSelected(drink);
                      controllerSearch.closeView(drink.name);
                    },
                  ),
                )
                .toList();
          },
        ),
        const SizedBox(height: 12),
        if (selectedDrink != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(selectedDrink!.name),
              subtitle: Text(selectedDrink!.category.defaultLabel),
            ),
          ),
        const SizedBox(height: 8),
        Text(l10n.recentDrinks, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final drink = recent[index];
              return SizedBox(
                width: 160,
                child: Card(
                  child: ListTile(
                    title: Text(drink.name),
                    subtitle: Text(drink.category.defaultLabel),
                    onTap: () => onSelected(drink),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.categories, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SizedBox(
          height: 280,
          child: ListView(
            children: grouped.entries
                .map(
                  (entry) => ExpansionTile(
                    title: Text(entry.key.defaultLabel),
                    children: entry.value
                        .map(
                          (drink) => ListTile(
                            title: Text(drink.name),
                            subtitle: drink.volumeMl == null
                                ? null
                                : Text('${drink.volumeMl} ml'),
                            onTap: () => onSelected(drink),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
