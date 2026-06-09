import 'camp_model.dart';

class BookingModel {
  final String id;
  final CampModel camp;
  final DateTime startDate;
  final DateTime endDate;
  final int guests;
  final int totalPrice;
  final String status; // confirmed, cancelled, pending

  BookingModel({
    required this.id,
    required this.camp,
    required this.startDate,
    required this.endDate,
    required this.guests,
    required this.totalPrice,
    required this.status,
  });
}
