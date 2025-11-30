import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';
import 'package:google_fonts/google_fonts.dart';

class EbookSettingsDialog extends StatefulWidget {
  final EbookSettings currentSettings;
  final Function(EbookSettings) onSettingsChanged;
  final Function(EbookSettings)?
  onSettingsChangedRealTime; // Callback real-time

  const EbookSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
    this.onSettingsChangedRealTime,
  });

  @override
  State<EbookSettingsDialog> createState() => _EbookSettingsDialogState();
}

class _EbookSettingsDialogState extends State<EbookSettingsDialog> {
  late EbookSettings _settings;
  // final List<String> _fontFamilies = [
  //   'Roboto',
  //   'Lora',
  //   'Merriweather',
  //   'Nunito',
  //   'Open Sans',
  //   'Source Serif Pro',
  //   'Lexend Deca',
  //   'Noto Serif',
  // ];
  static const List<_HighlightColorOption> _highlightColors = [
    _HighlightColorOption(
      label: 'Vàng',
      hex: '#FFF59D',
      color: Color(0xFFFFF59D),
    ),
    _HighlightColorOption(
      label: 'Xanh lá',
      hex: '#C5E1A5',
      color: Color(0xFFC5E1A5),
    ),
    _HighlightColorOption(
      label: 'Xanh dương',
      hex: '#AEDFF7',
      color: Color(0xFFAEDFF7),
    ),
    _HighlightColorOption(
      label: 'Hồng',
      hex: '#F8BBD0',
      color: Color(0xFFF8BBD0),
    ),
  ];
  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    if (_settings.restReminderMinutes < 1 ||
        _settings.restReminderMinutes > 30) {
      _settings = _settings.copyWith(restReminderMinutes: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandleBar(),
            _buildTabNavigation(context),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildThemeTab(context),
                    _buildTypographyTab(context),
                    _buildRestTab(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method để cập nhật settings real-time
  void _updateSettingsRealTime(EbookSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    // Gọi callback real-time nếu có
    widget.onSettingsChangedRealTime?.call(newSettings);
    // Tự động lưu settings khi thay đổi
    widget.onSettingsChanged(newSettings);
  }

  Widget _buildFontSizeSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_size_rounded,
              color: Colors.black,
              size: 20,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_settings.fontSize.round()} pt',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.black,
            thumbColor: Colors.black,
            inactiveTrackColor: Colors.black.withOpacity(0.2),
          ),
          child: Slider(
            value: _settings.fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (value) {
              _updateSettingsRealTime(_settings.copyWith(fontSize: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.text_format_rounded, color: Colors.black, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        // Wrap(
        //   spacing: 10,
        //   runSpacing: 10,
        //   children: _fontFamilies.map((font) {
        //     final bool isSelected = _settings.fontFamily == font;
        //     final Color background = isSelected
        //         ? Colors.black.withOpacity(0.15)
        //         : Colors.grey.withOpacity(0.1);
        //     final Color foreground = isSelected ? Colors.black : Colors.black87;
        //     return ChoiceChip(
        //       label: Text(
        //         font,
        //         style: _fontPreviewStyle(font).copyWith(
        //           fontSize: 13,
        //           color: foreground,
        //           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        //         ),
        //       ),
        //       selected: isSelected,
        //       backgroundColor: background,
        //       selectedColor: background,
        //       elevation: isSelected ? 2 : 0,
        //       pressElevation: 0,
        //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //       onSelected: (selected) {
        //         if (selected) {
        //           _updateSettingsRealTime(_settings.copyWith(fontFamily: font));
        //         }
        //       },
        //     );
        //   }).toList(),
        // ),
      ],
    );
  }

  Widget _buildLineHeightSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_line_spacing_rounded,
              color: Colors.black,
              size: 20,
            ),
            const Spacer(),
            Text(
              _settings.lineHeight.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.black,
            thumbColor: Colors.black,
            inactiveTrackColor: Colors.black.withOpacity(0.2),
          ),
          child: Slider(
            value: _settings.lineHeight,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            onChanged: (value) {
              _updateSettingsRealTime(_settings.copyWith(lineHeight: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightColorSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.highlight_rounded, color: Colors.black, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _highlightColors.map((colorOption) {
            final bool isSelected = _settings.highlightColor == colorOption.hex;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _updateSettingsRealTime(
                  _settings.copyWith(highlightColor: colorOption.hex),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorOption.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.black
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.black87, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final items = [
      (key: 'light', icon: Icons.wb_sunny_rounded),
      (key: 'dark', icon: Icons.nightlight_round),
      (key: 'sepia', icon: Icons.auto_awesome_rounded),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        final bool isSelected = _settings.theme == item.key;
        return _buildThemeOption(
          context: context,
          icon: item.icon,
          isSelected: isSelected,
          onTap: () {
            _updateSettingsRealTime(_settings.copyWith(theme: item.key));
          },
        );
      }).toList(),
    );
  }

  Widget _buildEyeComfortSection(BuildContext context) {
    final bool showRestReminder =
        _settings.eyeComfortEnabled && _settings.restReminderEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleTile(
          context: context,
          icon: Icons.spa_rounded,
          title: 'Chế độ bảo vệ mắt',
          value: _settings.eyeComfortEnabled,
          enabled: _settings.theme == 'light',
          onChanged: (value) {
            _updateSettingsRealTime(
              _settings.copyWith(eyeComfortEnabled: value),
            );
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: _settings.eyeComfortEnabled ? null : 0,
          padding: _settings.eyeComfortEnabled
              ? const EdgeInsets.only(top: 16)
              : EdgeInsets.zero,
          child: _settings.eyeComfortEnabled && _settings.theme == 'light'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabeledSlider(
                      context: context,
                      value: _settings.warmth,
                      min: 0,
                      max: 0.8,
                      divisions: 16,
                      label: '${(_settings.warmth * 100).round()}%',
                      icon: Icons.wb_twilight_rounded,
                      onChanged: (value) {
                        _updateSettingsRealTime(
                          _settings.copyWith(warmth: value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabeledSlider(
                      context: context,
                      value: _settings.brightness,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      label: '${(_settings.brightness * 100).round()}%',
                      icon: Icons.brightness_6_rounded,
                      onChanged: (value) {
                        _updateSettingsRealTime(
                          _settings.copyWith(brightness: value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildToggleTile(
                      context: context,
                      icon: Icons.timer_rounded,
                      title: 'Nhắc nghỉ định kỳ',
                      value: _settings.restReminderEnabled,
                      onChanged: (value) {
                        _updateSettingsRealTime(
                          _settings.copyWith(restReminderEnabled: value),
                        );
                      },
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildLabeledSlider(
                            context: context,
                            value: _settings.restReminderMinutes.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: _formatMinutesLabel(
                              _settings.restReminderMinutes,
                            ),
                            valueFormatter: (value) =>
                                _formatMinutesLabel(value.round()),
                            icon: Icons.access_time_rounded,
                            onChanged: (value) {
                              _updateSettingsRealTime(
                                _settings.copyWith(
                                  restReminderMinutes: value.round(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      crossFadeState: showRestReminder
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final bool isDarkPreview = _settings.theme == 'dark';
    final bool isSepiaPreview = _settings.theme == 'sepia';

    final Color backgroundColor = isDarkPreview
        ? Colors.black.withOpacity(0.78)
        : isSepiaPreview
        ? const Color(0xFFF7EEDB)
        : Colors.grey.withOpacity(0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
    );
  }

  TextStyle _fontPreviewStyle(String font) {
    try {
      return GoogleFonts.getFont(font);
    } catch (_) {
      return TextStyle(fontFamily: font);
    }
  }

  String _formatMinutesLabel(int minutes) {
    if (minutes <= 1) {
      return '1 phút';
    }
    return '$minutes phút';
  }

  Widget _buildHandleBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTabNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: const TabBar(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.black, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: 'Giao diện'),
          Tab(text: 'Kiểu chữ'),
          Tab(text: 'Nhắc nghỉ'),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    String subtitle = '',
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? Colors.black.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildToggleTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool? enabled,
  }) {
    final isEnabled = enabled ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(0.1),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Colors.black,
            onChanged: isEnabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    int? divisions,
    String? label,
    String Function(double)? valueFormatter,
    required ValueChanged<double> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 8),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueFormatter != null
                    ? valueFormatter(value)
                    : label ?? value.toStringAsFixed(value % 1 == 0 ? 0 : 2),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: Colors.black,
            activeTrackColor: Colors.black,
            inactiveTrackColor: Colors.black.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildSectionCard(
            context: context,
            title: 'Chế độ',
            subtitle: '',
            children: [
              _buildThemeSelector(context),
              const SizedBox(height: 12),
              _buildPreview(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildFontSizeSlider(context),
          const SizedBox(height: 14),
          _buildFontFamilySelector(context),
          const SizedBox(height: 14),
          _buildLineHeightSlider(context),
          const SizedBox(height: 14),
          _buildHighlightColorSelector(context),
        ],
      ),
    );
  }

  Widget _buildRestTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildSectionCard(
            context: context,
            title: 'Bảo vệ mắt & nhắc nghỉ',
            subtitle: '',
            children: [_buildEyeComfortSection(context)],
          ),
        ],
      ),
    );
  }
}

class _HighlightColorOption {
  const _HighlightColorOption({
    required this.label,
    required this.hex,
    required this.color,
  });

  final String label;
  final String hex;
  final Color color;
}
