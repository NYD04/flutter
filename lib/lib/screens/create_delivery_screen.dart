import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/delivery_order.dart';
import '../services/delivery_service.dart';
import '../services/firestore_data_service.dart';

class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedWorkshop;
  String? _selectedMechanic;
  String? _selectedBayNumber;
  DateTime _requiredBy = DateTime.now().add(const Duration(hours: 2));
  final List<PartItem> _parts = [];
  bool _isLoading = false;
  String _generatedOrderNumber = '';

  // Firestore data
  List<Workshop> _workshops = [];
  List<Part> _partsCatalog = [];
  bool _dataLoading = true;

  @override
  void initState() {
    super.initState();
    _generateOrderNumber();
    _loadFirestoreData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFirestoreData() async {
    try {
      final workshops = await FirestoreDataService.getWorkshops();
      final parts = await FirestoreDataService.getParts();

      setState(() {
        _workshops = workshops;
        _partsCatalog = parts;
        _dataLoading = false;
      });
    } catch (e) {
      setState(() {
        _dataLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateOrderNumber() async {
    try {
      final orderNumber = await DeliveryService.generateUniqueOrderNumber();
      setState(() {
        _generatedOrderNumber = orderNumber;
      });
    } catch (e) {
      setState(() {
        _generatedOrderNumber = 'Error generating order number';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Delivery Order'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading || _dataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderInfoSection(),
              const SizedBox(height: 24),
              _buildPartsSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Auto-generated Order Number (Read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[100],
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _generatedOrderNumber.isEmpty ? 'Generating...' : _generatedOrderNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _generateOrderNumber,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Generate new order number',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Workshop Dropdown
            DropdownButtonFormField<String>(
              value: _selectedWorkshop,
              decoration: const InputDecoration(
                labelText: 'Workshop Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _workshops.map((Workshop workshop) {
                return DropdownMenuItem<String>(
                  value: workshop.name,
                  child: Text(workshop.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWorkshop = newValue;
                  _selectedMechanic = null; // Reset mechanic when workshop changes
                  _selectedBayNumber = null; // Reset bay number when workshop changes
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a workshop';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Mechanic Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMechanic,
              decoration: const InputDecoration(
                labelText: 'Mechanic Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _selectedWorkshop != null
                  ? _workshops
                  .firstWhere((w) => w.name == _selectedWorkshop)
                  .mechanics
                  .map((String mechanic) {
                return DropdownMenuItem<String>(
                  value: mechanic,
                  child: Text(mechanic),
                );
              }).toList()
                  : [],
              onChanged: _selectedWorkshop != null
                  ? (String? newValue) {
                setState(() {
                  _selectedMechanic = newValue;
                  _selectedBayNumber = null; // Reset bay number when mechanic changes
                });
              }
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a mechanic';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Bay Number Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBayNumber,
              decoration: const InputDecoration(
                labelText: 'Bay Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.garage),
              ),
              items: _selectedWorkshop != null
                  ? _workshops
                  .firstWhere((w) => w.name == _selectedWorkshop)
                  .bay
                  .map((String bay) {
                return DropdownMenuItem<String>(
                  value: bay,
                  child: Text(bay),
                );
              }).toList()
                  : [],
              onChanged: _selectedWorkshop != null
                  ? (String? newValue) {
                setState(() {
                  _selectedBayNumber = newValue;
                });
              }
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a bay number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Required By Date/Time
            InkWell(
              onTap: _selectRequiredByDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Required By',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_requiredBy.day}/${_requiredBy.month}/${_requiredBy.year} ${_requiredBy.hour.toString().padLeft(2, '0')}:${_requiredBy.minute.toString().padLeft(2, '0')}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Additional notes for this delivery',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parts (${_parts.length}/10)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _parts.length >= 10 ? null : _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Part'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_parts.isEmpty)
              const Center(
                child: Text(
                  'No parts added yet. Click "Add Part" to add parts to this delivery.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: [
                  // Scrollable table with header and rows using same scroll bar
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300, // Maximum height for the scrollable area
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 800, // Fixed width to enable horizontal scrolling
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(width: 200, child: Text('Part Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 100, child: Text('Part Number', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 200, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 100, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 80, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Parts rows
                                ..._parts.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final part = entry.value;
                                  return _buildPartRow(index, part);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTotalSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartRow(int index, PartItem part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              part.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              part.partNumber,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              part.description,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '\$${part.unitPrice.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              part.quantity.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: IconButton(
              onPressed: () => _removePart(index),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: 'Remove part',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalAmount = _parts.fold<double>(
      0.0,
          (sum, part) => sum + (part.quantity * part.unitPrice),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _parts.isEmpty ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: const Text(
        'Create Delivery Order',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _selectRequiredByDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _requiredBy,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_requiredBy),
      );

      if (pickedTime != null) {
        setState(() {
          _requiredBy = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addPart() {
    if (_parts.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 parts allowed per delivery order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddPartDialog(
        partsCatalog: _partsCatalog,
        onPartAdded: (part) {
          setState(() {
            _parts.add(part);
          });
        },
      ),
    );
  }

  void _removePart(int index) {
    setState(() {
      _parts.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one part to the delivery order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final order = DeliveryOrder(
        id: '', // Will be set by Firestore
        orderNumber: _generatedOrderNumber,
        workshopName: _selectedWorkshop!,
        mechanicName: _selectedMechanic!,
        bayNumber: _selectedBayNumber!,
        requiredBy: _requiredBy,
        createdAt: DateTime.now(),
        status: DeliveryStatus.pending,
        parts: _parts,
        notes: _notesController.text.trim(),
      );

      await DeliveryService.createDelivery(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating delivery order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AddPartDialog extends StatefulWidget {
  final List<Part> partsCatalog;
  final Function(PartItem) onPartAdded;

  const _AddPartDialog({
    required this.partsCatalog,
    required this.onPartAdded,
  });

  @override
  State<_AddPartDialog> createState() => _AddPartDialogState();
}

class _AddPartDialogState extends State<_AddPartDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  Part? _selectedPart;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1'; // Initialize with default value
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Part'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: double.maxFinite, // Ensure dialog takes full width
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Part Selection Dropdown
                DropdownButtonFormField<Part>(
                  value: _selectedPart,
                  decoration: const InputDecoration(
                    labelText: 'Select Part',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  isExpanded: true,
                  items: widget.partsCatalog.map((Part part) {
                    return DropdownMenuItem<Part>(
                      value: part,
                      child: Text(
                        part.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (Part? newValue) {
                    setState(() {
                      _selectedPart = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a part';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity Input
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _quantity = int.tryParse(value) ?? 1;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Part Details Display
                if (_selectedPart != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Part Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${_selectedPart!.name}'),
                        Text('Part Number: ${_selectedPart!.partNumber}'),
                        Text('Description: ${_selectedPart!.description}'),
                        Text(
                          'Unit Price: \$${_selectedPart!.unitPrice.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${(_quantity * _selectedPart!.unitPrice).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addPart,
          child: const Text('Add Part'),
        ),
      ],
    );
  }



  void _addPart() {
    if (_formKey.currentState!.validate() && _selectedPart != null) {
      final part = PartItem(
        id: _selectedPart!.id,
        name: _selectedPart!.name,
        partNumber: _selectedPart!.partNumber,
        quantity: _quantity,
        description: _selectedPart!.description,
        unitPrice: _selectedPart!.unitPrice,
      );

      widget.onPartAdded(part);
      Navigator.of(context).pop();
    }
  }
}