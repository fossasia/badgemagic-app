import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BadgeScanSettingsWidget extends StatefulWidget {
  final Function(BadgeScanMode mode, List<String> names)? onSave;

  const BadgeScanSettingsWidget({super.key, this.onSave});

  @override
  State<BadgeScanSettingsWidget> createState() =>
      _BadgeScanSettingsWidgetState();
}

class _BadgeScanSettingsWidgetState extends State<BadgeScanSettingsWidget> {
  late BadgeScanMode _mode;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BadgeScanProvider>(context, listen: false);
    _mode = provider.mode;
  }

  void _addBadgeName() {
    setState(() {
      _controllers.add(TextEditingController());
    });
    final provider = Provider.of<BadgeScanProvider>(context, listen: false);
    provider.addBadgeName(''); // Add empty badge name to provider
  }

  Future<void> _onSave() async {
    final updatedNames = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final provider = Provider.of<BadgeScanProvider>(context, listen: false);
    provider.setMode(_mode);
    provider.setBadgeNames(updatedNames);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan settings saved successfully')),
    );

    widget.onSave?.call(_mode, updatedNames);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeScanProvider>(
      builder: (context, provider, child) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_controllers.isEmpty) {
          // Initialize controllers only after provider is loaded
          for (var name in provider.badgeNames) {
            _controllers.add(TextEditingController(text: name));
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Badge Scan Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _onSave,
              ),
            ],
          ),
          body: Column(
            children: [
              RadioListTile<BadgeScanMode>(
                title: const Text('Connect to any badge'),
                value: BadgeScanMode.any,
                groupValue: _mode,
                onChanged: (val) => setState(() => _mode = val!),
              ),
              RadioListTile<BadgeScanMode>(
                title: const Text('Connect to badges with the following names'),
                value: BadgeScanMode.specific,
                groupValue: _mode,
                onChanged: (val) => setState(() => _mode = val!),
              ),
              if (_mode == BadgeScanMode.specific) ...[
                // Selection controls
                if (_controllers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => provider.selectAll(),
                              child: const Text('Select All'),
                            ),
                            TextButton(
                              onPressed: () => provider.clearSelection(),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        if (provider.selectedIndices.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              // Remove selected controllers
                              final sortedIndices = provider.selectedIndices
                                  .toList()
                                ..sort((a, b) => b.compareTo(a));

                              for (final index in sortedIndices) {
                                if (index < _controllers.length) {
                                  _controllers[index].dispose();
                                  _controllers.removeAt(index);
                                }
                              }

                              provider.removeSelectedDevices();
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: Text(
                                'Remove (${provider.selectedIndices.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                // Badge list with checkboxes
                Expanded(
                  child: ListView.builder(
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      final isSelected = provider.isSelected(index);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) =>
                                  provider.toggleSelection(index),
                              activeColor: Colors.blue,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: TextField(
                                  controller: _controllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Badge Name',
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    // Update the provider when text changes
                                    provider.updateBadgeName(index, value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Add more button
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: _addBadgeName,
                    icon: const Icon(Icons.add),
                    label: const Text("Add more"),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
