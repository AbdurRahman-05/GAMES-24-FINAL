import 'package:flutter/material.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedSport;
  final String selectedArea;
  final ValueChanged<Map<String, dynamic>> onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedSport,
    required this.selectedArea,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _sport;
  late String _area;
  double _maxPrice = 2000;

  @override
  void initState() {
    super.initState();
    _sport = widget.selectedSport;
    _area = widget.selectedArea;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Venues', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sport Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SportsData.allSports.map((s) {
                      final isSelected = _sport == s.id;
                      return ChoiceChip(
                        label: Text(s.name),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() => _sport = selected ? s.id : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Madurai Area', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _area,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: SportsData.maduraiAreas.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _area = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Price per Hour', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('₹${_maxPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 300,
                    max: 3000,
                    divisions: 27,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _maxPrice = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Apply Filters',
            onPressed: () {
              widget.onApply({
                'sport': _sport,
                'area': _area,
                'maxPrice': _maxPrice,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
