import '../models/celebration_package_model.dart';

class MockCelebrationsRepository {
  MockCelebrationsRepository._();

  static const List<CelebrationPackageModel> packages = [
    CelebrationPackageModel(
      id: 'c1',
      title: 'Turf Birthday Bash',
      subtitle: 'Ideal for Sports-themed Birthday Parties',
      sportName: 'Football & Box Cricket',
      capacity: 30,
      basePrice: 4999.0,
      imageUrl: 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?auto=format&fit=crop&w=800&q=80',
      highlights: ['3 Hours Full Turf Access', 'Custom Balloon Decor', 'Sound System & Mic'],
      includedServices: [
        'Dedicated Event Coordinator',
        'Referee for Friendly Matches',
        'Snack & Drink Bar Counter Setup',
        'Customized Winner Trophies',
      ],
    ),
    CelebrationPackageModel(
      id: 'c2',
      title: 'Corporate Sports Cup',
      subtitle: 'Team Building Tournament Package',
      sportName: 'Cricket, Football & Badminton',
      capacity: 100,
      basePrice: 14999.0,
      imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80',
      highlights: ['Full Day Multi-Sport Arena', 'Live Score Board Screen', 'Buffet Catering Area'],
      includedServices: [
        'Professional Match Umpires',
        'Corporate Branding & Banners',
        'Medals & Championship Shield',
        'First Aid & Hydration Station',
      ],
    ),
    CelebrationPackageModel(
      id: 'c3',
      title: 'VR & Go-Kart Blast Party',
      subtitle: 'High-speed Thrill Party',
      sportName: 'Go Karting, Bowling & VR Pods',
      capacity: 20,
      basePrice: 7999.0,
      imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
      highlights: ['Unlimited Kart Laps (2 Hrs)', 'Dedicated Bowling Lane', 'VIP VR Lounge'],
      includedServices: [
        'Safety Marshals & Instructors',
        'Pizza & Mocktail Platters',
        'Podium Ceremony & Photo Shoot',
      ],
    ),
  ];
}
