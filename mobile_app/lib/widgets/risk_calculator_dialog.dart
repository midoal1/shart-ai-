import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';

class RiskCalculatorDialog extends StatefulWidget {
  final TradeSetupModel setup;

  const RiskCalculatorDialog({super.key, required this.setup});

  @override
  State<RiskCalculatorDialog> createState() => _RiskCalculatorDialogState();
}

class _RiskCalculatorDialogState extends State<RiskCalculatorDialog> {
  final _balanceController = TextEditingController(text: '1000');
  double _riskPercentage = 1.0; // 1% default

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(_balanceController.text) ?? 1000.0;
    final maxRiskDollar = balance * (_riskPercentage / 100.0);
    
    // Stop loss distance
    final stopLossDist = (widget.setup.entryPrice - widget.setup.stopLoss).abs();
    final tp1Dist = (widget.setup.takeProfit1 - widget.setup.entryPrice).abs();
    final tp2Dist = (widget.setup.takeProfit2 - widget.setup.entryPrice).abs();

    // Position size calculation
    final positionUnits = stopLossDist > 0 ? (maxRiskDollar / stopLossDist) : 0.0;
    final profitTp1 = positionUnits * tp1Dist;
    final profitTp2 = positionUnits * tp2Dist;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: AppTheme.buyGreen),
                      SizedBox(width: 8),
                      Text(
                        'حاسبة إدارة رأس المال (Risk Calc)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Balance Input
              const Text(
                'رأس مال المحفظة (\$):',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Risk Percentage selector
              const Text(
                'نسبة المخاطرة المقبولة للصفقة:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1.0, 2.0, 3.0, 5.0].map((r) {
                  final isSelected = _riskPercentage == r;
                  return ChoiceChip(
                    label: Text(
                      '$r%',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.buyGreen,
                    backgroundColor: AppTheme.surfaceElevated,
                    onSelected: (val) {
                      if (val) setState(() => _riskPercentage = r);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Calculated Results Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildResultRow(
                      'أقصى خسارة مسموح بها (Max Loss):',
                      '\$${maxRiskDollar.toStringAsFixed(2)}',
                      AppTheme.sellRed,
                    ),
                    const SizedBox(height: 8),
                    _buildResultRow(
                      'حجم العقد / الكمية المقترحة:',
                      '${positionUnits.toStringAsFixed(3)} وحدة',
                      AppTheme.primaryBlue,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildResultRow(
                      'الربح المتوقع عند الهدف الأول (TP1):',
                      '+\$${profitTp1.toStringAsFixed(2)}',
                      AppTheme.buyGreen,
                    ),
                    const SizedBox(height: 8),
                    _buildResultRow(
                      'الربح المتوقع عند الهدف الثاني (TP2):',
                      '+\$${profitTp2.toStringAsFixed(2)}',
                      AppTheme.buyGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '💡 نصيحة: الالتزام الصارم بوقف الخسارة ونسبة المخاطرة هو سر استمرارية المتداول الناجح.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
