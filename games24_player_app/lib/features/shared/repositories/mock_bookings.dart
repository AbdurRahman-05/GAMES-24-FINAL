import '../models/booking_model.dart';

class MockBookingsRepository {
  MockBookingsRepository._();

  static List<BookingModel> initialBookings = const [
    BookingModel(
      id: 'BK-98421',
      venueId: 'v1',
      venueName: 'Madurai Turf Arena',
      area: 'KK Nagar',
      sportName: 'Football',
      date: '28 Jul 2026',
      timeSlot: '07:00 PM - 08:00 PM',
      totalPrice: 1200.0,
      status: BookingStatus.upcoming,
      qrCodeData: 'PLAYHUB-MADURAI-BK98421',
      imageUrl: 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=800&q=80',
    ),
    BookingModel(
      id: 'BK-87110',
      venueId: 'v2',
      venueName: 'Royal Badminton Hub',
      area: 'Anna Nagar',
      sportName: 'Badminton',
      date: '20 Jul 2026',
      timeSlot: '06:00 PM - 07:00 PM',
      totalPrice: 450.0,
      status: BookingStatus.completed,
      qrCodeData: 'PLAYHUB-MADURAI-BK87110',
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80',
    ),
  ];
}
