import 'package:flutter/material.dart';
import '../models/delivery_order.dart';
import '../services/delivery_service.dart';
import 'delivery_details_screen.dart';

class DeliveryScheduleScreen extends StatefulWidget {
  const DeliveryScheduleScreen({super.key});

  @override
  State<DeliveryScheduleScreen> createState() => _DeliveryScheduleScreenState();
}

class _DeliveryScheduleScreenState extends State<DeliveryScheduleScreen> {
  DeliveryStatus selectedStatus = DeliveryStatus.all;
  late Stream<List<DeliveryOrder>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    _ordersStream = DeliveryService.getDeliveryOrdersByStatus(selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            color: const Color(0xFF1E3A8A), // Dark blue header
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              children: [
                // Top row with back button, title, and filter
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Delivery Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    PopupMenuButton<DeliveryStatus>(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onSelected: (DeliveryStatus status) {
                        setState(() {
                          selectedStatus = status;
                          _updateStream();
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<DeliveryStatus>(
                          value: DeliveryStatus.all,
                          child: Text('All Orders'),
                        ),
                        const PopupMenuItem<DeliveryStatus>(
                          value: DeliveryStatus.pending,
                          child: Text('Pending'),
                        ),
                        const PopupMenuItem<DeliveryStatus>(
                          value: DeliveryStatus.pickedUp,
                          child: Text('Picked Up'),
                        ),
                        const PopupMenuItem<DeliveryStatus>(
                          value: DeliveryStatus.enRoute,
                          child: Text('En Route'),
                        ),
                        const PopupMenuItem<DeliveryStatus>(
                          value: DeliveryStatus.delivered,
                          child: Text('Delivered'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter indicator
                Text(
                  'Filter: ${_getStatusText(selectedStatus)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: StreamBuilder<List<DeliveryOrder>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading delivery orders...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _updateStream();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No delivery orders found'),
                        const SizedBox(height: 16),
                        if (selectedStatus == DeliveryStatus.all) ...[
                          const Text('Try initializing sample data from the home screen'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await DeliveryService.initializeFakeData();
                                if (mounted) {
                                  setState(() {
                                    _updateStream();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sample data initialized!'),
                                          backgroundColor: Colors.blue,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                          backgroundColor: Colors.blue[600],
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Initialize Sample Data'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location with map pin icon
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.workshopName} - Bay ${order.bayNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mechanic with person icon
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.mechanicName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Due time with clock icon (only show for non-delivered orders)
              if (order.status != DeliveryStatus.delivered) ...[
                Row(
                  children: [
                    Icon(
                      _isUrgent(order.requiredBy) ? Icons.warning : Icons.access_time,
                      size: 16,
                      color: _isUrgent(order.requiredBy) ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                          _isUrgent(order.requiredBy) 
                            ? 'URGENT: Delivery needed within 3 hours' 
                            : 'Due ${_formatTime(order.requiredBy)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isUrgent(order.requiredBy) ? Colors.red : Colors.grey[700],
                            fontWeight: _isUrgent(order.requiredBy) ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                    ),
                    // Items count with cube icon
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.parts.length} Items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              // Items count for delivered orders (always show)
              if (order.status == DeliveryStatus.delivered) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${order.parts.length} Items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              // Urgent warning banner (only for non-delivered orders)
              if (order.status != DeliveryStatus.delivered && _isUrgent(order.requiredBy)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This order needs to be delivered within 3 hours!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'OVERDUE';
    }
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
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'OVERDUE';
    }
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
