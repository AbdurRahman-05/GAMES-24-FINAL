class ReviewModel {
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String date;

  const ReviewModel({
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class VenueModel {
  final String id;
  final String name;
  final String area;
  final String address;
  final List<String> sports;
  final double rating;
  final int reviewCount;
  final double pricePerHour;
  final List<String> imageUrls;
  final List<String> amenities;
  final List<String> availableSlots;
  final double latitude;
  final double longitude;
  final bool isFeatured;
  final bool isPopular;
  final String description;
  final List<ReviewModel> reviews;

  const VenueModel({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.sports,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.imageUrls,
    required this.amenities,
    required this.availableSlots,
    required this.latitude,
    required this.longitude,
    this.isFeatured = false,
    this.isPopular = false,
    required this.description,
    required this.reviews,
  });
}
