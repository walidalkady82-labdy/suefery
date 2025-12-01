import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/model/model_order.dart'; // Import ModelOrderItem

class EditOrderItemDialog extends StatefulWidget {
  final ModelOrderItem item;

  const EditOrderItemDialog({super.key, required this.item});

  @override
  State<EditOrderItemDialog> createState() => _EditOrderItemDialogState();
}

class _EditOrderItemDialogState extends State<EditOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _unitPriceController;
  late TextEditingController _brandController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toString());
    _brandController = TextEditingController(text: widget.item.brand);
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return AlertDialog(
      title: Text(strings.edit),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: strings.itemName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings.errorFieldRequired(strings.itemName);
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: strings.quantity),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings.errorFieldRequired(  strings.quantity);
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return strings.errorFieldInvalid(strings.quantity );
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(labelText: strings.unit),
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: InputDecoration(labelText: strings.price),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings.errorFieldRequired(strings.price);
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return strings.errorFieldInvalid(strings.price );
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(labelText: strings.brand),
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: strings.notes),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final updatedItem = widget.item.copyWith(
                description: _descriptionController.text,
                quantity: double.parse(_quantityController.text),
                unit: _unitController.text,
                unitPrice: double.parse(_unitPriceController.text),
                brand: _brandController.text,
                notes: _notesController.text,
              );
              Navigator.of(context).pop(updatedItem);
            }
          },
          child: Text(strings.save),
        ),
      ],
    );
  }
}
