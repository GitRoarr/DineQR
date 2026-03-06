import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({super.key});

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> {
  MobileScannerController? _cameraController;
  bool _isScanned = false;
  bool _flashOn = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanned || _isVerifying) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      final tableNumber = _extractTableNumber(value);
      if (tableNumber == null) continue;

      setState(() => _isVerifying = true);

      final api = ref.read(apiServiceProvider);
      final table = await api.getTableByNumber(tableNumber);

      if (!mounted) return;

      setState(() => _isVerifying = false);

      if (table != null) {
        setState(() => _isScanned = true);
        ref.read(currentTableIdProvider.notifier).state = table.id;
        ref.read(currentTableProvider.notifier).state = table.number;

        // Show success animation
        _showSuccessDialog(table.number);
        break;
      } else {
        _showErrorSnackBar('Table not found or inactive.');
      }
    }
  }

  int? _extractTableNumber(String value) {
    // Pattern 1: custom token, e.g. "DINEQR_TABLE_5"
    if (value.startsWith('DINEQR_TABLE_')) {
      return int.tryParse(value.replaceFirst('DINEQR_TABLE_', ''));
    }

    // Pattern 2: URL containing /table/<id>, e.g. "https://host/table/5"
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[segments.length - 2] == 'table') {
        return int.tryParse(segments.last);
      }
    }

    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessDialog(int tableId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'Table $tableId',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              const Text(
                'QR Code scanned successfully!',
                style: TextStyle(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.context.go('/menu?table=$tableId');
                  },
                  child: const Text('View Menu'),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Camera
          if (_cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: _onDetect,
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.background.withOpacity(0.7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // UI Elements
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Staff login button
                      _buildCircleButton(
                        Icons.person_outline,
                        () => context.go('/login'),
                      ),
                      const Text(
                        'Scan Table QR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Flash toggle
                      _buildCircleButton(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        () {
                          _cameraController?.toggleTorch();
                          setState(() => _flashOn = !_flashOn);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Scan frame
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.6),
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Corner decorations
                        ..._buildCorners(),
                        // Scanning line animation
                        Center(
                          child: Container(
                            width: 200,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.gold.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          )
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .slideY(
                                begin: -2.5,
                                end: 2.5,
                                duration: 2000.ms,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom instructions
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, color: AppColors.gold, size: 28),
                            const SizedBox(width: 12),
                            Flexible(
                              child: const Text(
                                'Point camera at table QR code',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      Positioned(top: 0, left: 0, child: _corner(true, true)),
      Positioned(top: 0, right: 0, child: _corner(true, false)),
      Positioned(bottom: 0, left: 0, child: _corner(false, true)),
      Positioned(bottom: 0, right: 0, child: _corner(false, false)),
    ];
  }

  Widget _corner(bool isTop, bool isLeft) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(
          isTop: isTop,
          isLeft: isLeft,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
