enum BookingStatus { upcoming, completed, cancelled }

class BookingModel {
  final String id;
  final String venueId;
  final String venueName;
  final String area;
  final String sportName;
  final String date;
  final String timeSlot;
  final double totalPrice;
  final BookingStatus status;
  final String qrCodeData;
  final String imageUrl;

  const BookingModel({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.area,
    required this.sportName,
    required this.date,
    required this.timeSlot,
    required this.totalPrice,
    required this.status,
    required this.qrCodeData,
    required this.imageUrl,
  });
}
