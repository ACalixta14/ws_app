import 'package:flutter/material.dart';

import '../models/client.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import 'client_form_screen.dart';

class ClientsListScreen extends StatefulWidget {
  final ClientRepository clientRepo;
  final ServiceOrderRepository? orderRepo; //limpar ordens do cliente depois

  const ClientsListScreen({
    super.key,
    required this.clientRepo,
    this.orderRepo
  });

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  @override
  Widget build(BuildContext context) {
    final clients = widget.clientRepo.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ClientFormScreen(clientRepo: widget.clientRepo),
            ),
          );

          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client saved')),
            );
          }

          setState(() {}); // refresh list
        },
        child: const Icon(Icons.add),
      ),
       body: clients.isEmpty
          ? const Center(child: Text('No clients yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (_, index) {
                final Client client = clients[index];
                return ListTile(
                  title: Text(client.name),
                  subtitle: Text(client.address),
                  onLongPress: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete client?'),
                        content: const Text('This will delete the client. Orders will remain for now.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    await widget.clientRepo.delete(client.id);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client deleted')),
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
