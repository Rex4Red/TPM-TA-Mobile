import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import 'main_screen.dart';

/// Layar pemilihan genre yang muncul setelah user pertama kali register.
/// User harus memilih minimal 3 genre sebelum bisa lanjut ke Home.
class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen>
    with SingleTickerProviderStateMixin {
  final RecommendationService _recService = RecommendationService();
  final Set<String> _selectedGenres = {};
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animController;

  static const int _minGenres = 3;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    await _recService.loadModel();
    setState(() => _isLoading = false);
    _animController.forward();
  }

  Future<void> _onContinue() async {
    if (_selectedGenres.length < _minGenres || _isSaving) return;

    setState(() => _isSaving = true);

    await _recService.saveUserGenres(_selectedGenres.toList());

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenreSelectionColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: GenreSelectionColors.accent),
                    SizedBox(height: 16),
                    Text("Memuat genre...",
                        style: TextStyle(color: GenreSelectionColors.subtitle)),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _animController,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ===== HEADER =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 48, color: GenreSelectionColors.accent),
                          const SizedBox(height: 12),
                          const Text(
                            "Pilih Genre Favoritmu",
                            style: TextStyle(
                              color: GenreSelectionColors.title,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pilih minimal $_minGenres genre agar kami bisa merekomendasikan manga terbaik untukmu",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GenreSelectionColors.subtitle,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedGenres.length >= _minGenres
                                  ? GenreSelectionColors.counterReady
                                  : GenreSelectionColors.counterNotReady,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_selectedGenres.length} genre dipilih",
                              style: TextStyle(
                                color: _selectedGenres.length >= _minGenres
                                    ? GenreSelectionColors.counterTextReady
                                    : GenreSelectionColors.counterTextNotReady,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== GENRE CHIPS GRID =====
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: _recService.availableGenres.map((genre) {
                              final isSelected = _selectedGenres.contains(genre);
                              return _GenreChip(
                                label: genre,
                                icon: _getGenreIcon(genre),
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedGenres.remove(genre);
                                    } else {
                                      _selectedGenres.add(genre);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // ===== TOMBOL LANJUT =====
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _selectedGenres.length >= _minGenres
                                ? const LinearGradient(colors: [
                                    GenreSelectionColors.btnGradientStart,
                                    GenreSelectionColors.btnGradientEnd,
                                  ])
                                : null,
                            color: _selectedGenres.length >= _minGenres
                                ? null
                                : GenreSelectionColors.btnDisabled,
                          ),
                          child: ElevatedButton(
                            onPressed: _selectedGenres.length >= _minGenres
                                ? _onContinue
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _selectedGenres.length >= _minGenres
                                        ? "LANJUT →"
                                        : "Pilih ${_minGenres - _selectedGenres.length} genre lagi",
                                    style: TextStyle(
                                      color: _selectedGenres.length >= _minGenres
                                          ? GenreSelectionColors.btnTextActive
                                          : GenreSelectionColors.btnTextDisabled,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Icon untuk setiap genre (supaya lebih visual)
  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return Icons.flash_on;
      case 'adventure':
        return Icons.explore;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'drama':
        return Icons.theater_comedy;
      case 'fantasy':
        return Icons.auto_fix_high;
      case 'horror':
        return Icons.warning_amber;
      case 'mystery':
        return Icons.search;
      case 'romance':
        return Icons.favorite;
      case 'sci-fi':
        return Icons.rocket_launch;
      case 'sports':
        return Icons.sports_soccer;
      case 'thriller':
        return Icons.psychology;
      case 'slice of life':
        return Icons.coffee;
      case 'supernatural':
        return Icons.nights_stay;
      case 'school life':
        return Icons.school;
      case 'martial arts':
        return Icons.sports_martial_arts;
      case 'historical':
        return Icons.account_balance;
      case 'isekai':
        return Icons.public;
      case 'shounen':
        return Icons.local_fire_department;
      case 'seinen':
        return Icons.person;
      case 'shoujo':
        return Icons.spa;
      case 'ecchi':
        return Icons.whatshot;
      case 'harem':
        return Icons.group;
      case 'mecha':
        return Icons.precision_manufacturing;
      case 'music':
        return Icons.music_note;
      case 'psychological':
        return Icons.psychology_alt;
      case 'magic':
        return Icons.auto_awesome;
      case 'cooking':
        return Icons.restaurant;
      case 'medical':
        return Icons.local_hospital;
      case 'game':
        return Icons.sports_esports;
      default:
        return Icons.label;
    }
  }
}

// ==========================================
// GENRE CHIP WIDGET
// ==========================================
class _GenreChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? GenreSelectionColors.chipSelected
              : GenreSelectionColors.chipUnselected,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? GenreSelectionColors.chipBorderSelected
                : GenreSelectionColors.chipBorderUnselected,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GenreSelectionColors.chipShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? GenreSelectionColors.chipIconSelected
                  : GenreSelectionColors.chipIconUnselected,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? GenreSelectionColors.chipTextSelected
                    : GenreSelectionColors.chipTextUnselected,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle,
                  size: 16, color: GenreSelectionColors.chipCheckIcon),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COLOR SETTINGS (Centralized)
// ==========================================
class GenreSelectionColors {
  // Background & Text
  static const background = Color(0xFF0D0D0D);
  static const title = Colors.white;
  static const subtitle = Colors.white60;
  static const accent = Color(0xFF7C4DFF);

  // Counter badge
  static const counterReady = Color(0xFF1B5E20);
  static const counterNotReady = Color(0xFF333333);
  static const counterTextReady = Color(0xFF69F0AE);
  static const counterTextNotReady = Colors.white54;

  // Genre chips
  static const chipSelected = Color(0xFF7C4DFF);
  static const chipUnselected = Color(0xFF1A1A1A);
  static const chipBorderSelected = Color(0xFFB388FF);
  static const chipBorderUnselected = Color(0xFF333333);
  static final chipShadow = const Color(0xFF7C4DFF).withAlpha(80);
  static const chipIconSelected = Colors.white;
  static const chipIconUnselected = Colors.white54;
  static const chipTextSelected = Colors.white;
  static const chipTextUnselected = Colors.white70;
  static const chipCheckIcon = Color(0xFF69F0AE);

  // Button
  static const btnGradientStart = Color(0xFF7C4DFF);
  static const btnGradientEnd = Color(0xFF448AFF);
  static const btnDisabled = Color(0xFF222222);
  static const btnTextActive = Colors.white;
  static const btnTextDisabled = Colors.white38;
}
