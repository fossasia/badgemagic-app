import 'package:flutter/material.dart';
import 'package:badgemagic/constants.dart'; // Assuming you have colors defined

class TransferMethodTray extends StatelessWidget {
  final Function(ConnectionType) onMethodSelected;
  final VoidCallback onCancel;

  const TransferMethodTray({
    Key? key,
    required this.onMethodSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 3.8,
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            'Choose Transfer Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Transfer options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTransferOption(
                context,
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                type: ConnectionType.bluetooth,
              ),
              _buildTransferOption(
                context,
                icon: Icons.usb,
                label: 'USB',
                type: ConnectionType.usb,
              ),
            ],
          ),

          const Spacer(),

          // Cancel button
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ConnectionType type,
  }) {
    return GestureDetector(
      onTap: () => onMethodSelected(type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
