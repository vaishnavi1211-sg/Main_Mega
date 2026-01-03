import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockStatusGrid extends StatelessWidget {
  final Map<String, double> stockData;
  final Color themePrimary;
  final Color themeSecondary;

  const StockStatusGrid({
    super.key,
    required this.stockData,
    required this.themePrimary,
    required this.themeSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Raw Material Stock Status",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...stockData.entries.map((entry) {
          final isLowStock = entry.value < 100.0;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLowStock
                    ? themePrimary.withOpacity(0.3)
                    : themeSecondary.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${entry.value.toStringAsFixed(1)} MT",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isLowStock ? themePrimary : themeSecondary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isLowStock ? Icons.warning_amber : Icons.check_circle,
                  size: 36,
                  color: isLowStock ? themePrimary : themeSecondary,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
