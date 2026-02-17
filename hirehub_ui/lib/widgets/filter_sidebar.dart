import 'package:flutter/material.dart';

class FilterSidebar extends StatefulWidget {
  const FilterSidebar({super.key});

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  final Map<String, bool> _categories = {
    'IT & Software': false,
    'Healthcare': false,
    'Construction': false,
    'Hospitality': false,
    'Engineering': false,
    'Sales & Marketing': false,
  };

  final Map<String, bool> _locations = {
    'UAE': false,
    'Canada': false,
  };

  final Map<String, bool> _jobTypes = {
    'Full-time': false,
    'Part-time': false,
    'Contract': false,
    'Temporary': false,
    'Remote': false,
  };

  RangeValues _salaryRange = const RangeValues(30000, 100000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            'Job Category',
            _categories.keys.map((key) => _buildCheckbox(key, _categories[key]!, (val) {
              setState(() => _categories[key] = val!);
            })).toList(),
          ),
          const Divider(height: 40),
          _buildFilterSection(
            'Job Location',
            [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Location',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ..._locations.keys.map((key) => _buildCheckbox(key, _locations[key]!, (val) {
                setState(() => _locations[key] = val!);
              })),
            ],
          ),
          const Divider(height: 40),
          _buildFilterSection(
            'Expected Salary',
            [
              RangeSlider(
                values: _salaryRange,
                min: 0,
                max: 150000,
                divisions: 15,
                labels: RangeLabels(
                  '\$${_salaryRange.start.round()}',
                  '\$${_salaryRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _salaryRange = values);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_salaryRange.start.round().toString()}'),
                    Text('\$${_salaryRange.end.round().toString()}+'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildFilterSection(
            'Job Type',
            _jobTypes.keys.map((key) => _buildCheckbox(key, _jobTypes[key]!, (val) {
              setState(() => _jobTypes[key] = val!);
            })).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
