import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Order")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order ID: ${data['id']}"),

                const SizedBox(height: 20),

                Text(
                  getStatusText(status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: getStatusColor(status),
                  ),
                ),

                const SizedBox(height: 30),

                _step("Accepted", status, "accepted"),
                _step("Preparing", status, "preparing"),
                _step("Ready", status, "ready"),
                _step("Completed", status, "completed"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _step(String label, String current, String step) {
    bool done = _order(current) >= _order(step);

    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }

  int _order(String s) {
    switch (s) {
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for vendor ⏳';
      case 'accepted':
        return 'Order Accepted ✅';
      case 'preparing':
        return 'Preparing 🍳';
      case 'ready':
        return 'Ready for Pickup 📦';
      case 'completed':
        return 'Completed 🎉';
      case 'rejected':
        return 'Rejected ❌';
      default:
        return 'Processing';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}