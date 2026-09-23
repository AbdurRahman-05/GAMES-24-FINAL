class CelebrationPackageModel {
  final String id;
  final String title;
  final String subtitle;
  final String sportName;
  final int capacity;
  final double basePrice;
  final String imageUrl;
  final List<String> highlights;
  final List<String> includedServices;

  const CelebrationPackageModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sportName,
    required this.capacity,
    required this.basePrice,
    required this.imageUrl,
    required this.highlights,
    required this.includedServices,
  });
}
