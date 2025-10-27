import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

class EbookSettingsDialog extends StatefulWidget {
  final EbookSettings currentSettings;
  final Function(EbookSettings) onSettingsChanged;

  const EbookSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<EbookSettingsDialog> createState() => _EbookSettingsDialogState();
}

class _EbookSettingsDialogState extends State<EbookSettingsDialog> {
  late EbookSettings _settings;
  final List<String> _fontFamilies = [
    'Roboto',
    'Times New Roman',
    'Arial',
    'Georgia',
    'Verdana',
    'Helvetica',
    'Courier New',
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt đọc'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Font Size
            _buildFontSizeSlider(),
            const SizedBox(height: 20),
            
            // Font Family
            _buildFontFamilySelector(),
            const SizedBox(height: 20),
            
            // Line Height
            _buildLineHeightSlider(),
            const SizedBox(height: 20),
            
            // Theme
            _buildThemeSelector(),
            const SizedBox(height: 20),
            
            // ✅ Preview
            _buildPreview(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingsChanged(_settings);
            Navigator.pop(context);
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kích thước chữ: ${_settings.fontSize.round()}'),
        Slider(
          value: _settings.fontSize,
          min: 12.0,
          max: 24.0,
          divisions: 12,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(fontSize: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font chữ:'),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _settings.fontFamily,
          isExpanded: true,
          items: _fontFamilies.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings.copyWith(fontFamily: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Khoảng cách dòng: ${_settings.lineHeight.toStringAsFixed(1)}'),
        Slider(
          value: _settings.lineHeight,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(lineHeight: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chủ đề:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Sáng'),
                value: 'light',
                groupValue: _settings.theme,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(theme: value!);
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Tối'),
                value: 'dark',
                groupValue: _settings.theme,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(theme: value!);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ Thêm preview để xem trước
  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _settings.theme == 'dark' ? Colors.grey[900] : Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xem trước',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _settings.theme == 'dark' ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đây là đoạn văn bản mẫu để bạn có thể xem trước các cài đặt font chữ, kích thước và chủ đề.',
            style: TextStyle(
              fontSize: _settings.fontSize,
              fontFamily: _settings.fontFamily,
              height: _settings.lineHeight,
              color: _settings.theme == 'dark' ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}