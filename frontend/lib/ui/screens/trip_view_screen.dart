import 'package:flutter/material.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import '../widgets/day_selector_strip.dart';
import '../widgets/timeline_item.dart';
import '../widgets/spontaneous_bucket.dart';
import '../widgets/collaborator_avatars.dart';
import 'check_in_screen.dart';
import 'spontaneous_add_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

const _mockDays = [
  DayItem(label: 'D0', dayNumber: 0, date: 'May 19'),
  DayItem(label: 'D1', dayNumber: 1, date: 'May 20'),
  DayItem(label: 'D2', dayNumber: 2, date: 'May 21', isToday: true),
  DayItem(label: 'D3', dayNumber: 3, date: 'May 22'),
  DayItem(label: 'D4', dayNumber: 4, date: 'May 23'),
];

class _TimelineEntry {
  const _TimelineEntry({
    required this.state,
    required this.time,
    required this.name,
    this.location,
    this.photoCount = 0,
    this.quote,
  });

  final TimelineItemState state;
  final String time;
  final String name;
  final String? location;
  final int photoCount;
  final String? quote;
}

const _dayTimelines = <int, List<_TimelineEntry>>{
  0: [
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '06:00',
      name: 'Depart Jakarta (CGK)',
      location: 'Soekarno-Hatta Airport',
      photoCount: 2,
      quote: 'The adventure begins!',
    ),
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '08:30',
      name: 'Arrive Bali (DPS)',
      location: 'Ngurah Rai Airport',
      photoCount: 5,
      quote: 'Smells like sunscreen and frangipani already.',
    ),
  ],
  1: [
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '10:00',
      name: 'Check in to villa',
      location: 'The Layar, Seminyak',
      photoCount: 8,
      quote: 'Pool is massive.',
    ),
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '12:30',
      name: 'Lunch at Sate Bali',
      location: 'Jl. Laksmana',
      photoCount: 4,
    ),
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '18:30',
      name: 'Sunset at Ku De Ta',
      location: 'Jl. Kayu Aya',
      photoCount: 11,
      quote: 'Best sunset I\'ve seen.',
    ),
  ],
  2: [
    _TimelineEntry(
      state: TimelineItemState.checkedIn,
      time: '08:00',
      name: 'Tegallalang Rice Terrace',
      location: 'Tegallalang, Ubud',
      photoCount: 14,
      quote: 'Absolutely breathtaking.',
    ),
    _TimelineEntry(
      state: TimelineItemState.current,
      time: '11:00',
      name: 'Ubud Monkey Forest',
      location: 'Mandala Wisata Wenara Wana',
    ),
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '14:00',
      name: 'Lunch at Locavore',
      location: 'Jl. Dewi Sita, Ubud',
    ),
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '17:00',
      name: 'Ubud Palace',
      location: 'Puri Saren Agung',
    ),
  ],
  3: [
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '07:00',
      name: 'Mount Batur sunrise hike',
      location: 'Kintamani',
    ),
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '13:00',
      name: 'Tirta Gangga Water Palace',
      location: 'Karangasem',
    ),
  ],
  4: [
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '09:00',
      name: 'Check out',
      location: 'The Layar, Seminyak',
    ),
    _TimelineEntry(
      state: TimelineItemState.upcoming,
      time: '14:00',
      name: 'Depart Bali (DPS)',
      location: 'Ngurah Rai Airport',
    ),
  ],
};

const _spontaneousByDay = <int, List<SpontaneousPreviewItem>>{
  1: [
    SpontaneousPreviewItem(
        name: 'Random beach walk', time: '16:30', hasPhoto: true),
    SpontaneousPreviewItem(
        name: 'Street corn cart', time: '19:00', hasPhoto: false),
  ],
  2: [],
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TripViewScreen extends StatefulWidget {
  const TripViewScreen({super.key});

  @override
  State<TripViewScreen> createState() => _TripViewScreenState();
}

class _TripViewScreenState extends State<TripViewScreen> {
  int _selectedDay = 2; // default today

  List<_TimelineEntry> get _currentEntries =>
      _dayTimelines[_selectedDay] ?? [];

  List<SpontaneousPreviewItem> get _spontaneousItems =>
      _spontaneousByDay[_selectedDay] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _TripSliverAppBar(),
        ],
        body: Column(
          children: [
            DaySelectorStrip(
              days: _mockDays,
              selectedIndex: _selectedDay,
              onDaySelected: (i) => setState(() => _selectedDay = i),
            ),
            const Divider(height: 1),
            Expanded(
              child: _currentEntries.isEmpty
                  ? const _EmptyDayState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          0, AppSpacing.md, 0, 100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < _currentEntries.length;
                                  i++)
                                TimelineItem(
                                  state: _currentEntries[i].state,
                                  time: _currentEntries[i].time,
                                  name: _currentEntries[i].name,
                                  location: _currentEntries[i].location,
                                  photoCount:
                                      _currentEntries[i].photoCount,
                                  quote: _currentEntries[i].quote,
                                  isLast: i == _currentEntries.length - 1,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CheckInScreen()),
                                  ),
                                  onCheckIn: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CheckInScreen()),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Spontaneous bucket
                        SpontaneousBucket(
                          itemCount: _spontaneousItems.length,
                          previewItems: _spontaneousItems,
                          onAdd: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const SpontaneousAddSheet(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripSliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primaryDark,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 80, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Bali with the crew',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'May 19–23, 2026  ·  Bali, Indonesia',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Collaborator avatars
              CollaboratorAvatars(
                avatarUrls: const ['A', 'B', 'C', 'D'],
                size: 32,
                borderColor: Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Invite icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 40, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text('Nothing planned yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Tap + to add a moment', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
