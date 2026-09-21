import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../core/services/app_state_service.dart';
import '../../shared/widgets/neon_button.dart';
import 'trainer_detail_screen.dart';
import 'trainer_form_screen.dart';

class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({super.key});

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  final TrainerRepository _repository = TrainerRepository();
  List<TrainerModel> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadTrainers(showSpinner: false);
    }
  }

  Future<void> _loadTrainers({bool showSpinner = true}) async {
    if (showSpinner || _trainers.isEmpty) {
      setState(() => _isLoading = true);
    }
    final trainers = await _repository.getAllTrainers(includeInactive: true);
    if (mounted) {
      setState(() {
        _trainers = trainers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'TRAINERS & STAFF',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          : _trainers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFD4FF00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: _loadTrainers,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _trainers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trainer = _trainers[index];
                      return _buildTrainerCard(trainer);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
          );
          if (res == true) _loadTrainers();
        },
        backgroundColor: const Color(0xFFD4FF00),
        icon: const Icon(Icons.add, color: Color(0xFF121212)),
        label: const Text(
          'Add Trainer',
          style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.fitness_center, size: 48, color: Color(0xFFD4FF00)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No trainers registered yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add personal trainers and staff to track salaries, assign members, and record disbursements.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: 'Add First Trainer',
              icon: Icons.person_add_alt_1,
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
                );
                if (res == true) _loadTrainers();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: trainer.id)),
          );
          if (res == true) _loadTrainers();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF121212),
                backgroundImage: (trainer.photoPath != null && trainer.photoPath!.isNotEmpty && File(trainer.photoPath!).existsSync())
                    ? FileImage(File(trainer.photoPath!))
                    : null,
                child: (trainer.photoPath == null || trainer.photoPath!.isEmpty || !File(trainer.photoPath!).existsSync())
                    ? Text(
                        trainer.name.trim().isNotEmpty
                            ? trainer.name.trim().split(' ').map((e) => e[0].toUpperCase()).take(2).join()
                            : 'T',
                        style: const TextStyle(
                          color: Color(0xFFD4FF00),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trainer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!trainer.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainer.phone,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (trainer.specialization != null && trainer.specialization!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4FF00).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              trainer.specialization!,
                              style: const TextStyle(color: Color(0xFFD4FF00), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (trainer.monthlySalary != null)
                          Text(
                            '₹${trainer.monthlySalary!.toStringAsFixed(0)}/mo',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

