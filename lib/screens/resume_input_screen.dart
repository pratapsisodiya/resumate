import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:resumate/shared/theme/app_theme.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

class ResumeInputScreen extends ConsumerStatefulWidget {
  const ResumeInputScreen({super.key});

  @override
  ConsumerState<ResumeInputScreen> createState() => _ResumeInputScreenState();
}

class _ResumeInputScreenState extends ConsumerState<ResumeInputScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _textCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final state = ref.read(resumeProvider);
    if (state is ResumeLoaded) _prefill(state.resume);
  }

  void _prefill(Resume r) {
    _nameCtrl.text = r.personalInfo.fullName;
    _titleCtrl.text = r.personalInfo.title ?? '';
    _emailCtrl.text = r.personalInfo.email;
    _phoneCtrl.text = r.personalInfo.phone ?? '';
    _locationCtrl.text = r.personalInfo.location ?? '';
    _linkedInCtrl.text = r.personalInfo.linkedIn ?? '';
    _githubCtrl.text = r.personalInfo.github ?? '';
    _bioCtrl.text = r.personalInfo.bio ?? '';
    _textCtrl.text = r.rawText ?? '';
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _textCtrl, _nameCtrl, _titleCtrl, _emailCtrl, _phoneCtrl,
      _locationCtrl, _linkedInCtrl, _githubCtrl, _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _parseText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    await ref.read(resumeProvider.notifier).parseFromText(text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveManual() async {
    final info = PersonalInfo(
      fullName: _nameCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      linkedIn: _linkedInCtrl.text.trim().isEmpty ? null : _linkedInCtrl.text.trim(),
      github: _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );
    final existing = ref.read(resumeProvider);
    final resume = existing is ResumeLoaded
        ? existing.resume.copyWith(personalInfo: info)
        : Resume(
            id: const Uuid().v4(),
            personalInfo: info,
            lastUpdated: DateTime.now(),
          );
    await ref.read(resumeProvider.notifier).save(resume);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeProvider);
    final isLoading = state is ResumeLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'PDF Import'),
            Tab(text: 'Paste / AI'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Parsing with AI…'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _PdfTab(onTextExtracted: (t) {
                  _textCtrl.text = t;
                  _tabs.animateTo(1);
                }),
                _PasteTab(ctrl: _textCtrl, onParse: _parseText),
                _ManualTab(
                  nameCtrl: _nameCtrl,
                  titleCtrl: _titleCtrl,
                  emailCtrl: _emailCtrl,
                  phoneCtrl: _phoneCtrl,
                  locationCtrl: _locationCtrl,
                  linkedInCtrl: _linkedInCtrl,
                  githubCtrl: _githubCtrl,
                  bioCtrl: _bioCtrl,
                  onSave: _saveManual,
                ),
              ],
            ),
    );
  }
}

class _PasteTab extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onParse;

  const _PasteTab({required this.ctrl, required this.onParse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Paste your resume text here…\n\nThe AI will extract your experience, skills, education, and more.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Parse with AI'),
              onPressed: onParse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualTab extends StatelessWidget {
  final TextEditingController nameCtrl, titleCtrl, emailCtrl, phoneCtrl,
      locationCtrl, linkedInCtrl, githubCtrl, bioCtrl;
  final VoidCallback onSave;

  const _ManualTab({
    required this.nameCtrl,
    required this.titleCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.locationCtrl,
    required this.linkedInCtrl,
    required this.githubCtrl,
    required this.bioCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(nameCtrl, 'Full Name', required: true),
        _field(titleCtrl, 'Job Title'),
        _field(emailCtrl, 'Email', required: true, keyboard: TextInputType.emailAddress),
        _field(phoneCtrl, 'Phone', keyboard: TextInputType.phone),
        _field(locationCtrl, 'Location'),
        _field(linkedInCtrl, 'LinkedIn URL', keyboard: TextInputType.url),
        _field(githubCtrl, 'GitHub URL', keyboard: TextInputType.url),
        TextField(
          controller: bioCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio / Summary',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Resume'),
            onPressed: onSave,
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

// ── PDF import tab ────────────────────────────────────────────────────────────

class _PdfTab extends StatefulWidget {
  final void Function(String text) onTextExtracted;
  const _PdfTab({required this.onTextExtracted});

  @override
  State<_PdfTab> createState() => _PdfTabState();
}

class _PdfTabState extends State<_PdfTab> {
  String? _fileName;
  bool _extracting = false;
  String? _error;

  Future<void> _pickPdf() async {
    setState(() { _error = null; _extracting = false; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final name  = result.files.single.name;
    setState(() { _fileName = name; _extracting = true; });

    try {
      final text = _extractPdfText(bytes);
      if (mounted) widget.onTextExtracted(text);
    } catch (e) {
      setState(() { _error = 'Could not read PDF: $e'; _extracting = false; });
    }
  }

  String _extractPdfText(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final text = extractor.extractText();
    doc.dispose();
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Drop zone card
          GestureDetector(
            onTap: _extracting ? null : _pickPdf,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: _fileName != null
                    ? AppTheme.primary.withValues(alpha: 0.04)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _fileName != null
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : const Color(0xFFE5E7EB),
                  width: _fileName != null ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  if (_extracting)
                    ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Extracting text…'),
                    ]
                  else if (_fileName != null)
                    ...[
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(_fileName!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Text extracted — switching to AI tab…',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ]
                  else
                    ...[
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.upload_file_rounded,
                            color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Tap to upload PDF',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('Your resume will be extracted and parsed by AI',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOut),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Choose PDF'),
              onPressed: _extracting ? null : _pickPdf,
            ),
          ),
        ],
      ),
    );
  }
}
