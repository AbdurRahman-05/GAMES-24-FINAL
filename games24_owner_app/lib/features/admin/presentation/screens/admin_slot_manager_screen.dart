import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/admin_providers.dart';

class AdminSlotManagerScreen extends ConsumerStatefulWidget {
  const AdminSlotManagerScreen({super.key});

  @override
  ConsumerState<AdminSlotManagerScreen> createState() => _AdminSlotManagerScreenState();
}

class _AdminSlotManagerScreenState extends ConsumerState<AdminSlotManagerScreen> {
  String? _selectedCourt;

  String _offerType = 'percent'; // 'percent' or 'price'
  DateTime _selectedDate = DateTime.now();

  final List<String> _weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  late final TextEditingController _discountPercentController;
  late final TextEditingController _offerLabelController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _discountedPriceController;

  @override
  void initState() {
    super.initState();
    _discountPercentController = TextEditingController(text: '20');
    _offerLabelController = TextEditingController(text: 'Happy Hour');
    _originalPriceController = TextEditingController(text: '1000');
    _discountedPriceController = TextEditingController(text: '800');
  }

  @override
  void dispose() {
    _discountPercentController.dispose();
    _offerLabelController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  String _buildConfiguredOfferString() {
    if (_offerType == 'percent') {
      final percentStr = _discountPercentController.text.trim();
      final label = _offerLabelController.text.trim();
      return 'PERCENT|${percentStr.isEmpty ? "0" : percentStr}|$label';
    } else {
      final origStr = _originalPriceController.text.trim();
      final discStr = _discountedPriceController.text.trim();
      return 'PRICE|${origStr.isEmpty ? "0" : origStr}|${discStr.isEmpty ? "0" : discStr}';
    }
  }

  Widget _buildOfferContent(String offerText, Color textColor) {
    if (offerText.startsWith('PERCENT|')) {
      final parts = offerText.split('|');
      final percent = parts[1];
      final label = parts.length > 2 ? parts[2] : '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$percent% OFF',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      );
    } else if (offerText.startsWith('PRICE|')) {
      final parts = offerText.split('|');
      final original = parts[1];
      final discounted = parts[2];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹$original',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: textColor.withValues(alpha: 0.8),
                  decorationThickness: 2,
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '₹$discounted',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Special Price',
            style: TextStyle(
              fontSize: 8,
              color: textColor.withValues(alpha: 0.8),
            ),
          )
        ],
      );
    } else {
      return Text(
        offerText,
        style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  void _showCustomOfferConfiguratorSheet(String slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String sheetOfferType = _offerType;
        final TextEditingController sheetPercentController = TextEditingController(text: _discountPercentController.text);
        final TextEditingController sheetLabelController = TextEditingController(text: _offerLabelController.text);
        final TextEditingController sheetOriginalPriceController = TextEditingController(text: _originalPriceController.text);
        final TextEditingController sheetDiscountedPriceController = TextEditingController(text: _discountedPriceController.text);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            String buildOfferString() {
              if (sheetOfferType == 'percent') {
                final percentStr = sheetPercentController.text.trim();
                final label = sheetLabelController.text.trim();
                return 'PERCENT|${percentStr.isEmpty ? "0" : percentStr}|$label';
              } else {
                final origStr = sheetOriginalPriceController.text.trim();
                final discStr = sheetDiscountedPriceController.text.trim();
                return 'PRICE|${origStr.isEmpty ? "0" : origStr}|${discStr.isEmpty ? "0" : discStr}';
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Set Custom Offer - $slot',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => sheetOfferType = 'percent'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sheetOfferType == 'percent' ? AppColors.primary : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.primary),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Percentage (%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sheetOfferType == 'percent' ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => sheetOfferType = 'price'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sheetOfferType == 'price' ? AppColors.primary : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.primary),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Price Cut (₹)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sheetOfferType == 'price' ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sheetOfferType == 'percent') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: sheetPercentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              prefixIcon: Icon(Icons.percent_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: sheetLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Tag Label',
                              prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: sheetOriginalPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Original Price (₹)',
                              prefixIcon: Icon(Icons.money_off_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: sheetDiscountedPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Offer Price (₹)',
                              prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Preview:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slot,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildOfferContent(buildOfferString(), AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final newOffer = buildOfferString();
                        final dateKey = _getDateKey(_selectedDate);
                        ref.read(adminSlotProvider.notifier).toggleSlotDiscount(slot, newOffer, dateKey);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Applied custom offer tag to $slot!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Text('Apply Offer Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  void _showOfferActions(String slot, String? currentOffer) {
    final defaultOfferString = _buildConfiguredOfferString();
    
    String defaultOfferDesc = 'Apply current configurator preset';
    if (defaultOfferString.startsWith('PERCENT|')) {
      final parts = defaultOfferString.split('|');
      defaultOfferDesc = 'PERCENT: ${parts[1]}% OFF ${parts.length > 2 ? parts[2] : ""}';
    } else if (defaultOfferString.startsWith('PRICE|')) {
      final parts = defaultOfferString.split('|');
      defaultOfferDesc = 'PRICE: ₹${parts[1]} -> ₹${parts[2]}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Manage Offer - $slot',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: AppColors.primary),
                  title: const Text('Set Default Offer', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(defaultOfferDesc),
                  onTap: () {
                    final dateKey = _getDateKey(_selectedDate);
                    ref.read(adminSlotProvider.notifier).toggleSlotDiscount(slot, defaultOfferString, dateKey);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Applied configurator offer preset to $slot.'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  title: const Text('Set Custom Offer', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Configure and apply custom percentage/price tag'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomOfferConfiguratorSheet(slot);
                  },
                ),
                if (currentOffer != null) ...[
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                    title: const Text('Remove Offer Tag', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    subtitle: const Text('Clear existing discount from this slot'),
                    onTap: () {
                      final dateKey = _getDateKey(_selectedDate);
                      ref.read(adminSlotProvider.notifier).toggleSlotDiscount(slot, '', dateKey);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Offer tag removed from $slot.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminSlotState = ref.watch(adminSlotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slot & Offer Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operating Hours Header Banner
            AppCard(
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Turf Operating Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          adminSlotState.weekdayOpeningTime == '24 Hours'
                              ? 'Open 24 Hours (All Day)'
                              : 'Opens at ${adminSlotState.weekdayOpeningTime} • Closes at ${adminSlotState.weekdayClosingTime}',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Select Court / Arena', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final courts = ref.watch(turfProfileProvider).courts;
                final courtNames = courts.map((c) => c.name).toList();
                if (courtNames.isEmpty) courtNames.add('No courts available');
                if (_selectedCourt == null || !courtNames.contains(_selectedCourt)) {
                  _selectedCourt = courtNames.first;
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCourt,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: courtNames.map((court) {
                    return DropdownMenuItem(value: court, child: Text(court, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCourt = val);
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Legend Status Cards
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(color: AppColors.success, label: 'Available'),
                _StatusBadge(color: AppColors.primary, label: 'Booked'),
                _StatusBadge(color: AppColors.warning, label: 'Blocked'),
                _StatusBadge(color: AppColors.primary, label: 'Offer Tag'),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Custom Offer Configurator',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure an offer type below, then long-press any available slot to apply it.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  
                  // Segmented Selector for Offer Type
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _offerType = 'percent'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _offerType == 'percent'
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.primary),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Percentage (%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _offerType == 'percent' ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _offerType = 'price'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _offerType == 'price'
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.primary),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Price Cut (₹)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _offerType == 'price' ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fields based on selected offer type
                  if (_offerType == 'percent') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              prefixIcon: Icon(Icons.percent_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _offerLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Tag Label',
                              prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Original Price (₹)',
                              prefixIcon: Icon(Icons.money_off_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountedPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Offer Price (₹)',
                              prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Live Preview Widget
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Live Preview:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '05:00 PM - 06:00 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildOfferContent(_buildConfiguredOfferString(), AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Selector Widget
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Active Date',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Selected date indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_weekdays[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${_months[_selectedDate.month - 1]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Scrollable 7 Dates Strip
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index));
                              final isSelected = DateUtils.isSameDay(date, _selectedDate);
                              final weekday = _weekdays[date.weekday - 1];
                              final dayStr = date.day.toString().padLeft(2, '0');

                              return GestureDetector(
                                onTap: () => setState(() => _selectedDate = date),
                                child: Container(
                                  width: 46,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weekday,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        dayStr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Divider line
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      
                      // Calendar Picker Button
                      IconButton(
                        icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 26),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Slots for ${_weekdays[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${_months[_selectedDate.month - 1]}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap to Block • Long Press to Tag Offer',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 12) / 2; // two slots per row with proper spacing
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: adminSlotState.getAvailableSlotsForDate(_selectedDate).map((slot) {
                    final dateKey = _getDateKey(_selectedDate);
                    final isBlocked = adminSlotState.getBlockedSlotsForDate(dateKey).contains(slot);
                    final isBooked = slot == '06:00 PM - 07:00 PM' || slot == '07:00 PM - 08:00 PM';
                    final offerTag = adminSlotState.getDiscountedSlotsForDate(dateKey)[slot];

                    Color bgColor = Colors.white;
                    Color textColor = AppColors.textPrimaryLight;
                    String statusLabel = 'Available';

                    if (isBooked) {
                      bgColor = AppColors.primary.withValues(alpha: 0.12);
                      textColor = AppColors.primary;
                      statusLabel = 'Booked';
                    } else if (isBlocked) {
                      bgColor = AppColors.warning.withValues(alpha: 0.15);
                      textColor = AppColors.warning;
                      statusLabel = 'Blocked';
                    } else if (offerTag != null) {
                      bgColor = AppColors.primary.withValues(alpha: 0.15);
                      textColor = AppColors.primary;
                      statusLabel = offerTag;
                    }

                    return SizedBox(
                      width: cardWidth,
                      child: GestureDetector(
                        onTap: isBooked
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Slot $slot is booked by customer.')),
                                );
                              }
                            : () {
                                ref.read(adminSlotProvider.notifier).toggleBlockSlot(slot, dateKey);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isBlocked ? 'Slot $slot unblocked' : 'Slot $slot blocked for maintenance',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        onLongPress: isBooked
                            ? null
                            : () => _showOfferActions(slot, offerTag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: offerTag != null
                                  ? AppColors.primary
                                  : (isBlocked ? AppColors.warning : AppColors.borderLight),
                              width: (isBlocked || offerTag != null) ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (offerTag != null)
                                _buildOfferContent(offerTag, textColor)
                              else
                                Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
