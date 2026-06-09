import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'camp_detail_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final BookingService _service = BookingService();
  List<BookingModel> _items = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}