import 'package:flutter/material.dart';
import '../models/delivery_order.dart';
import '../services/delivery_service.dart';
import 'delivery_confirmation_screen.dart';
import 'delivery_files_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryDetailsScreen({super.key, required this.order});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  late DeliveryOrder currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentOrder.orderNumber),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Files viewer button for delivered orders
          if (currentOrder.status == DeliveryStatus.delivered)
            IconButton(
              onPressed: () => _viewDeliveryFiles(),
              icon: const Icon(Icons.folder_open),
              tooltip: 'View Delivery Files',
            ),
          if (currentOrder.status != DeliveryStatus.delivered &&
              currentOrder.status != DeliveryStatus.cancelled)
            PopupMenuButton<String>(
              onSelected: _updateStatus,
              itemBuilder: (BuildContext context) => _getStatusMenuItems(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildPartsCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Order Number', currentOrder.orderNumber),
            _buildInfoRow('Workshop', currentOrder.workshopName),
            _buildInfoRow('Mechanic', currentOrder.mechanicName),
            _buildInfoRow('Bay Number', currentOrder.bayNumber),
            _buildInfoRow('Required By', _formatDateTime(currentOrder.requiredBy)),
            if (currentOrder.status != DeliveryStatus.delivered && _isUrgent(currentOrder.requiredBy)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'URGENT DELIVERY',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This order needs to be delivered within ${_getHoursRemaining(currentOrder.requiredBy)} hours!',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildInfoRow('Created', _formatDateTime(currentOrder.createdAt)),
            if (currentOrder.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(currentOrder.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parts Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...currentOrder.parts.map((part) => _buildPartItem(part)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${currentOrder.parts.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartItem(PartItem part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  part.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Qty: ${part.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Part #: ${part.partNumber}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (part.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              part.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '\$${part.unitPrice.toStringAsFixed(2)} each',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentOrder.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(currentOrder.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  _getStatusIcon(currentOrder.status),
                  color: _getStatusColor(currentOrder.status),
                ),
              ],
            ),
            if (currentOrder.deliveredAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Delivered at: ${_formatDateTime(currentOrder.deliveredAt!)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            // Show signature requirement warning for en route orders
            if (currentOrder.status == DeliveryStatus.enRoute) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signature required to mark as delivered',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget? _buildBottomActions() {
    if (currentOrder.status == DeliveryStatus.cancelled) {
      return null;
    }

    if (currentOrder.status == DeliveryStatus.delivered) {
      // Show confirmation button only if not yet confirmed
      if (currentOrder.deliveryConfirmation == null || currentOrder.deliveryConfirmation!.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToConfirmation,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm Delivery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show confirmation completed message
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delivery Confirmed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Show status update button for other statuses
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(_getNextStatus()),
              icon: Icon(_getNextStatusIcon()),
              label: Text(_getNextStatusText()),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _getStatusMenuItems() {
    final items = <PopupMenuEntry<String>>[];
    
    if (currentOrder.status == DeliveryStatus.pending) {
      items.add(const PopupMenuItem(
        value: 'pickedUp',
        child: Text('Mark as Picked Up'),
      ));
    }
    
    if (currentOrder.status == DeliveryStatus.pickedUp) {
      items.add(const PopupMenuItem(
        value: 'enRoute',
        child: Text('Mark as En Route'),
      ));
    }
    
    if (currentOrder.status == DeliveryStatus.enRoute) {
      items.add(PopupMenuItem(
        value: 'delivered',
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Mark as Delivered'),
            ),
            const Icon(Icons.warning, color: Colors.orange, size: 16),
          ],
        ),
      ));
    }
    
    return items;
  }

  String _getNextStatus() {
    switch (currentOrder.status) {
      case DeliveryStatus.pending:
        return 'pickedUp';
      case DeliveryStatus.pickedUp:
        return 'enRoute';
      case DeliveryStatus.enRoute:
        return 'delivered';
      default:
        return '';
    }
  }

  IconData _getNextStatusIcon() {
    switch (currentOrder.status) {
      case DeliveryStatus.pending:
        return Icons.inventory;
      case DeliveryStatus.pickedUp:
        return Icons.local_shipping;
      case DeliveryStatus.enRoute:
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextStatusText() {
    switch (currentOrder.status) {
      case DeliveryStatus.pending:
        return 'Pick Up';
      case DeliveryStatus.pickedUp:
        return 'Start Delivery';
      case DeliveryStatus.enRoute:
        return 'Complete Delivery';
      default:
        return 'Update';
    }
  }

  void _updateStatus(String status) async {
    DeliveryStatus newStatus;
    switch (status) {
      case 'pickedUp':
        newStatus = DeliveryStatus.pickedUp;
        break;
      case 'enRoute':
        newStatus = DeliveryStatus.enRoute;
        break;
      case 'delivered':
        // Special validation for delivered status
        return await _handleDeliveredStatusUpdate();
      default:
        return;
    }

    try {
      await DeliveryService.updateDeliveryStatus(currentOrder.id, newStatus);
      
      setState(() {
        currentOrder = currentOrder.copyWith(status: newStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.blue[500],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.blue[600],
          ),
        );
      }
    }
  }

  Future<void> _handleDeliveredStatusUpdate() async {
    try {
      // Simplified approach: Always navigate to confirmation screen
      // This ensures signature is captured before status change
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✍️ Please complete delivery confirmation with signature to mark as delivered'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to confirmation screen immediately
        _navigateToConfirmation();
      }
    } catch (e) {
      print('❌ Error in _handleDeliveredStatusUpdate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _navigateToConfirmation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryConfirmationScreen(order: currentOrder),
      ),
    );

    if (result == true && mounted) {
      // Refresh the order data to get the latest status and confirmation
      try {
        final updatedOrder = await DeliveryService.getDeliveryOrder(currentOrder.id);
        if (updatedOrder != null) {
          setState(() {
            currentOrder = updatedOrder;
          });
        }
      } catch (e) {
        print('Error refreshing order data: $e');
        // Still refresh the UI even if there's an error
        setState(() {});
      }
    }
  }

  void _viewDeliveryFiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryFilesScreen(
          orderId: currentOrder.id,
          orderNumber: currentOrder.orderNumber,
        ),
      ),
    );
  }


  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.all:
        return const Color(0xFF6366F1); // Indigo
      case DeliveryStatus.pending:
        return const Color(0xFFF59E0B); // Amber/Orange
      case DeliveryStatus.pickedUp:
        return const Color(0xFF3B82F6); // Blue
      case DeliveryStatus.enRoute:
        return const Color(0xFF8B5CF6); // Purple
      case DeliveryStatus.delivered:
        return const Color(0xFF10B981); // Green
      case DeliveryStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.all:
        return Icons.list;
      case DeliveryStatus.pending:
        return Icons.schedule;
      case DeliveryStatus.pickedUp:
        return Icons.inventory;
      case DeliveryStatus.enRoute:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.all:
        return 'ALL ORDERS';
      case DeliveryStatus.pending:
        return 'PENDING';
      case DeliveryStatus.pickedUp:
        return 'PICKED UP';
      case DeliveryStatus.enRoute:
        return 'EN ROUTE';
      case DeliveryStatus.delivered:
        return 'DELIVERED';
      case DeliveryStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isUrgent(DateTime requiredBy) {
    final now = DateTime.now();
    final difference = requiredBy.difference(now);
    return difference.inHours <= 3;
  }

  String _getHoursRemaining(DateTime requiredBy) {
    final now = DateTime.now();
    final difference = requiredBy.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}';
    } else if (difference.inMinutes > 0) {
      return '${(difference.inMinutes / 60).toStringAsFixed(1)}';
    } else {
      return '0';
    }
  }
}
