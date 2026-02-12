import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/core/theme.dart';
import 'logic/audit_bloc.dart';
import 'logic/audit_bloc_states.dart';
import '../data/audit_model.dart';

class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuditBloc()..add(StartAudit()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Security Audit'),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: WhisprTheme.backgroundGradient,
              ),
            ),
            Positioned.fill(
              child: BlocBuilder<AuditBloc, AuditState>(
                builder: (context, state) {
                  if (state is AuditLoading) {
                    return _buildLoading(state.message);
                  } else if (state is AuditCompleted) {
                    return _buildAuditResults(context, state);
                  } else if (state is AuditError) {
                    return _buildError(context, state.message);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<AuditBloc>().add(StartAudit()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditResults(BuildContext context, AuditCompleted state) {
    final report = state.report;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: kToolbarHeight + 40),
          _buildScoreCard(context, report.overallScore, state.isVaultLocked),
          const SizedBox(height: 32),

          if (state.isVaultLocked)
            _buildLockedWarning(context)
          else ...[
            Text(
              'AI Coach Analysis',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            _buildAiCard(
              context,
              report.aiInterpretation ?? "Analysis in progress...",
            ),
            const SizedBox(height: 32),

            Text(
              'Detailed Findings',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            ...report.findings.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFindingCard(context, f),
              ),
            ),
            if (report.findings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No security risks detected. Great job!',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, int score, bool isLocked) {
    Color scoreColor = Colors.greenAccent;
    if (score < 50) {
      scoreColor = Colors.redAccent;
    } else if (score < 80) {
      scoreColor = Colors.orangeAccent;
    }

    return _buildGlassCard(
      context,
      height: 180,
      borderRadius: BorderRadius.circular(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLocked) ...[
              const Icon(Icons.lock_outline, color: Colors.white24, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Unlock Vault for Full Audit',
                style: TextStyle(color: Colors.white60),
              ),
            ] else ...[
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const Text(
                'Security Score',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _buildGlassCard(
    BuildContext context, {
    required Widget child,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          width: width ?? MediaQuery.sizeOf(context).width - 48,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: effectiveBorderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLockedWarning(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.white60),
          const SizedBox(height: 16),
          const Text(
            'Privacy First',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'We don\'t store your plaintext passwords. To perform a deep security audit, we need to decrypt them locally in your device\'s memory. Please unlock your vault to proceed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: WhisprTheme.backgroundColor,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAiCard(BuildContext context, String text) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Security Coach',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildFindingCard(BuildContext context, AuditFinding finding) {
    Color riskColor = Colors.green;
    IconData icon = Icons.check_circle_outline;

    switch (finding.riskLevel) {
      case RiskLevel.critical:
        riskColor = Colors.red;
        icon = Icons.gpp_maybe;
        break;
      case RiskLevel.high:
        riskColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case RiskLevel.medium:
        riskColor = Colors.yellow;
        icon = Icons.info_outline;
        break;
      case RiskLevel.low:
        riskColor = Colors.blue;
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: riskColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (finding.accountTitle != null)
                  Text(
                    finding.accountTitle!,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Text(
                  finding.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
