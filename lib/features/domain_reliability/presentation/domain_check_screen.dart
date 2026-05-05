import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import '../logic/domain_service.dart';
import '../data/domain_report.dart';

class DomainCheckScreen extends StatefulWidget {
  const DomainCheckScreen({super.key});

  @override
  State<DomainCheckScreen> createState() => _DomainCheckScreenState();
}

class _DomainCheckScreenState extends State<DomainCheckScreen> {
  final TextEditingController _urlController = TextEditingController();
  final DomainService _domainService = DomainService();

  bool _isLoading = false;
  bool _hasReported = false;
  DomainReport? _report;
  String? _error;

  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _report = null;
      _error = null;
      _hasReported = false;
    });

    try {
      FocusScope.of(context).unfocus();
      final report = await _domainService.analyzeDomain(url);
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Domain Reliability'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Check Link Safety',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                const Text(
                  'Enter a URL to see if it is safe, suspicious, or a scam using our AI analysis.',
                  style: TextStyle(color: Colors.white70),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                _buildInputSection()
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 32),
                if (_isLoading)
                  _buildLoading()
                else if (_error != null)
                  _buildError()
                else if (_report != null)
                  _buildResultCard(_report!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., https://example.com',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.link, color: Colors.white60),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _analyzeUrl(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _analyzeUrl,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: WhisprTheme.backgroundColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Analyze URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 48),
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 24),
          Text('Analyzing domain security...',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildResultCard(DomainReport report) {
    Color scoreColor = Colors.greenAccent;
    IconData icon = Icons.check_circle_outline;

    if (report.score < 50) {
      scoreColor = Colors.redAccent;
      icon = Icons.cancel_outlined;
    } else if (report.score < 80) {
      scoreColor = Colors.orangeAccent;
      icon = Icons.warning_amber_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: scoreColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        report.riskLevel,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${report.score}/100',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.explanation,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              if (_hasReported)
                const Center(
                  child: Text(
                    'Thank you for your feedback! This helps us improve our AI analysis.',
                    style: TextStyle(
                        color: Colors.greenAccent, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Was this analysis accurate?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _domainService.reportAnalysis(
                                  _urlController.text.trim(), true);
                              setState(() {
                                _hasReported = true;
                              });
                            },
                            icon: const Icon(Icons.thumb_up_alt_outlined,
                                size: 18),
                            label: const Text('Yes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _domainService.reportAnalysis(
                                  _urlController.text.trim(), false);
                              setState(() {
                                _hasReported = true;
                              });
                            },
                            icon: const Icon(Icons.thumb_down_alt_outlined,
                                size: 18),
                            label: const Text('No'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
