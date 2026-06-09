
import '../models/booking_model.dart';
import '../services/camp_service.dart';

class BookingService {
  final CampService _campService = CampService();

  Future<List<BookingModel>> getMyBookings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final camps = await _campService.searchCamps();

    return [
      BookingModel(
        id: 'b1',
        camp: camps[0],
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 8)),
        guests: 2,
        totalPrice: camps[0].pricePerNight * 3,
        status: 'confirmed',
      ),
      BookingModel(
        id: 'b2',
        camp: camps[1],
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().subtract(const Duration(days: 12)),
        guests: 3,
        totalPrice: camps[1].pricePerNight * 3,
        status: 'completed',
      ),
    ];
  }
}
