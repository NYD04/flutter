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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Schedule'),
            Text(
              'Filter: ${_getStatusText(selectedStatus)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<DeliveryStatus>(
            icon: const Icon(Icons.filter_list),
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
      body: StreamBuilder<List<DeliveryOrder>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          // Debug information
          print('Filter: ${selectedStatus.toString()}');
          print('Connection State: ${snapshot.connectionState}');
          print('Has Error: ${snapshot.hasError}');
          if (snapshot.hasData) {
            print('Data Count: ${snapshot.data?.length ?? 0}');
          }
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
                  const SizedBox(height: 8),
                  Text('Filter: ${selectedStatus.toString().split('.').last}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _updateStream();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedStatus = DeliveryStatus.all;
                        _updateStream();
                      });
                    },
                    child: const Text('Clear Filter'),
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
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
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
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order.status),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${order.workshopName} - Bay ${order.bayNumber}'),
                      Text('Mechanic: ${order.mechanicName}'),
                      Text(
                        'Required by: ${_formatDateTime(order.requiredBy)}',
                        style: TextStyle(
                          color: _isUrgent(order.requiredBy) ? Colors.red : null,
                          fontWeight: _isUrgent(order.requiredBy) 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Parts: ${order.parts.length} items',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryDetailsScreen(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.all:
        return Colors.grey;
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.pickedUp:
        return Colors.blue;
      case DeliveryStatus.enRoute:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
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
    return difference.inHours <= 2;
  }
}
