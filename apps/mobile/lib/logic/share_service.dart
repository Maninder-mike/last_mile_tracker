import 'package:share_plus/share_plus.dart';
import '../domain/models/shipment.dart';

class ShareService {
  static Future<void> shareShipment(Shipment shipment) async {
    final text =
        '''
📦 Shipment Details: ${shipment.id}
Status: ${shipment.status}
Origin: ${shipment.origin}
Destination: ${shipment.destination}
Last Update: ${_formatDate(shipment.eta)}

Tracked via Last Mile Tracker
''';

    await Share.share(text, subject: 'Shipment Update: ${shipment.id}');
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
