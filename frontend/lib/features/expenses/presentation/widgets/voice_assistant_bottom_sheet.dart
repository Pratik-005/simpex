import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../categories/domain/models/category.dart';
import '../../data/mock_expense_repository.dart';
import 'add_expense_bottom_sheet.dart';

class VoiceAssistantBottomSheet extends StatefulWidget {
  const VoiceAssistantBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAssistantBottomSheet(),
    );
  }

  @override
  State<VoiceAssistantBottomSheet> createState() =>
      _VoiceAssistantBottomSheetState();
}

class _VoiceAssistantBottomSheetState extends State<VoiceAssistantBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _listeningTimer;

  bool _isListening = true;
  bool _isParsed = false;
  String _liveTranscript = 'Listening... Speak or select a prompt below';

  // Parsed draft state
  String _parsedMerchant = 'Blue Tokai Roasters';
  double _parsedAmount = 380.0;
  Category _parsedCategory = Category.defaults.first; // Food & Dining
  String _parsedPaymentMethod = 'UPI';

  final List<Map<String, dynamic>> _samplePrompts = [
    {
      'prompt': 'Record ₹380 for Blue Tokai Coffee',
      'merchant': 'Blue Tokai Roasters',
      'amount': 380.0,
      'categoryId': 'food',
      'payment': 'UPI',
    },
    {
      'prompt': 'Put ₹1,450 petrol at Shell Station',
      'merchant': 'Shell Fuel Station',
      'amount': 1450.0,
      'categoryId': 'transport',
      'payment': 'Debit Card',
    },
    {
      'prompt': 'Spent ₹2,400 on Groceries at Nature Basket',
      'merchant': "Nature's Basket",
      'amount': 2400.0,
      'categoryId': 'groceries',
      'payment': 'Credit Card',
    },
    {
      'prompt': 'Paid ₹550 for Uber ride to airport',
      'merchant': 'Uber Premier',
      'amount': 550.0,
      'categoryId': 'transport',
      'payment': 'Wallet',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _listeningTimer?.cancel();
    super.dispose();
  }

  void _applyPrompt(Map<String, dynamic> sample) {
    setState(() {
      _isListening = false;
      _isParsed = true;
      _liveTranscript = '"${sample['prompt']}"';
      _parsedMerchant = sample['merchant'] as String;
      _parsedAmount = sample['amount'] as double;
      _parsedPaymentMethod = sample['payment'] as String;

      final catId = sample['categoryId'] as String;
      _parsedCategory = Category.defaults.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category.defaults.first,
      );
    });
  }

  void _confirmAndSave() {
    final amountPaise = (_parsedAmount * 100).toInt();

    MockExpenseRepository.instance.addExpense(
      merchant: _parsedMerchant,
      amountPaise: amountPaise,
      categoryId: _parsedCategory.id,
      categoryName: _parsedCategory.name,
      paymentMethod: _parsedPaymentMethod,
      date: DateTime.now(),
      notes: 'Logged via Voice AI SLM Engine',
      isVoiceRecorded: true,
      voiceTranscript: _liveTranscript.replaceAll('"', ''),
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recorded $_parsedMerchant (-${CurrencyFormatter.formatPaise(amountPaise)})',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: SLM Engine Status & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Voice AI • SLM On-Device Active',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.outline,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Center Interactive Mic & Audio Frequency Visualizer
          GestureDetector(
            onTap: () {
              setState(() {
                _isListening = true;
                _isParsed = false;
                _liveTranscript = 'Listening... Speak now';
              });
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF34D399),
                    AppColors.primary,
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.mic, size: 36, color: Color(0xFF003824)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Animated Audio Waveform Equalizer
          if (_isListening)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final v = _animController.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildWaveBar(10 + (v * 16)),
                    const SizedBox(width: 4),
                    _buildWaveBar(16 + ((1 - v) * 22)),
                    const SizedBox(width: 4),
                    _buildWaveBar(24 + (v * 26)),
                    const SizedBox(width: 4),
                    _buildWaveBar(30 + ((1 - v) * 20)),
                    const SizedBox(width: 4),
                    _buildWaveBar(20 + (v * 18)),
                    const SizedBox(width: 4),
                    _buildWaveBar(12 + ((1 - v) * 14)),
                  ],
                );
              },
            )
          else
            const SizedBox(height: 32),

          const SizedBox(height: 14),

          // Live Transcript Pill Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.record_voice_over,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _liveTranscript,
                    style: AppTypography.bodyMd.copyWith(
                      color: _isParsed
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: _isParsed ? FontWeight.w600 : FontWeight.w400,
                      fontStyle: _isParsed
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // If parsed, display the synthesized Draft Expense Card
          if (_isParsed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI SYNTHESIZED TRANSACTION',
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '99% Acoustic Match',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _parsedMerchant,
                            style: AppTypography.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_parsedCategory.name} • $_parsedPaymentMethod',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '-₹${_parsedAmount.toStringAsFixed(0)}',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Confirm & Save Expense',
              icon: Icons.check,
              onPressed: _confirmAndSave,
            ),
          ] else ...[
            // Quick-Tap Speech Simulation Prompts
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TAP A SAMPLE PROMPT TO TEST:',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _samplePrompts.map((item) {
                return InkWell(
                  onTap: () => _applyPrompt(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['prompt'] as String,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Switch to manual input
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AddExpenseBottomSheet.show(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.keyboard_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Or Enter Expense Manually',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height.clamp(6.0, 48.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF2DD4BF), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
