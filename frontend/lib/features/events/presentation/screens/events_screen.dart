import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/entities/event_entity.dart';
import '../../providers/event_provider.dart';
import '../widgets/event_deck_controls.dart';
import '../widgets/event_filter_bar.dart';
import '../widgets/event_swipe_deck.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final GlobalKey<EventSwipeDeckState> _deckKey =
      GlobalKey<EventSwipeDeckState>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  int _currentIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';

  static const List<String> _filters = [
    'All',
    'Upcoming',
    'Ongoing',
    'Ended',
    'Archived'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentIndex = 0; // reconcile index safely
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      _currentIndex = 0;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _currentIndex = 0;
      }
    });
  }

  List<EventEntity> _getFilteredEvents(List<EventEntity> allEvents) {
    return allEvents.where((event) {
      // 1. Timeline Category Filter
      final matchesCategory = event.matchesFilter(_selectedFilter);
      if (!matchesCategory) return false;

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final title = event.title.toLowerCase();
        final desc = (event.description ?? '').toLowerCase();
        final venue = (event.venue ?? '').toLowerCase();
        final type = event.type.toLowerCase();
        final matchesSearch = title.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            venue.contains(_searchQuery) ||
            type.contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      return true;
    }).toList();
  }

  Map<String, int> _buildFilterCounts(List<EventEntity> allEvents) {
    final counts = <String, int>{};
    for (final f in _filters) {
      final key = f.toLowerCase();
      if (key == 'all') {
        counts[key] = allEvents.length;
      } else {
        counts[key] = allEvents.where((e) => e.matchesFilter(f)).length;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    // Permissions check
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final permissions = ref.watch(myPermissionsProvider).value ?? [];
    final canAdd = isSuperAdmin ||
        permissions.contains('event:add') ||
        permissions.contains('all');
    final canEdit = isSuperAdmin ||
        permissions.contains('event:edit') ||
        permissions.contains('all');

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'Events',
          actions: [
            // Search Toggle Button
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: _isSearching
                    ? accent
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                size: 22,
              ),
              tooltip: _isSearching ? 'Close Search' : 'Search Events',
              onPressed: _toggleSearch,
            ),
            // Add Event Button (for authorized users)
            if (canAdd)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Create New Event',
                  onPressed: () => context.push(RouteConstants.createEvent),
                ),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Search Input Bar (when expanded)
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkElevatedSurface
                          : AppColors.lightSecondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by title, venue, or type...',
                        hintStyle: AppTextStyles.bodySm.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        prefixIcon:
                            Icon(Icons.search_rounded, size: 20, color: accent),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

              // Filter Category Chips
              eventsAsync.maybeWhen(
                data: (events) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: EventFilterBar(
                    filters: _filters,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: _onFilterSelected,
                    filterCounts: _buildFilterCounts(events),
                  ),
                ),
                orElse: () => const SizedBox(height: 48),
              ),

              // Main Deck Viewport
              Expanded(
                child: eventsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2.5,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: EmptyStateWidget(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to Load Events',
                        message: error.toString(),
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(eventsProvider),
                      ),
                    ),
                  ),
                  data: (events) {
                    final filteredEvents = _getFilteredEvents(events);

                    if (filteredEvents.isEmpty) {
                      return RefreshIndicator(
                        color: accent,
                        onRefresh: () async {
                          ref.invalidate(eventsProvider);
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: EmptyStateWidget(
                                icon: Icons.event_busy_rounded,
                                title: _searchQuery.isNotEmpty
                                    ? 'No Matching Events'
                                    : 'No ${_selectedFilter == 'All' ? '' : _selectedFilter} Events',
                                message: _searchQuery.isNotEmpty
                                    ? 'No events match "$_searchQuery". Try searching with different keywords.'
                                    : 'There are currently no events categorized under $_selectedFilter.',
                                actionLabel: (_selectedFilter != 'All' ||
                                        _searchQuery.isNotEmpty)
                                    ? 'Reset Filters'
                                    : null,
                                onAction: () {
                                  setState(() {
                                    _selectedFilter = 'All';
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _isSearching = false;
                                    _currentIndex = 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Reconcile index if filtered list shrunk
                    if (_currentIndex >= filteredEvents.length) {
                      _currentIndex = filteredEvents.length - 1;
                    }
                    if (_currentIndex < 0) {
                      _currentIndex = 0;
                    }

                    return Column(
                      children: [
                        // Responsive Deck Canvas
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final availableHeight = constraints.maxHeight;

                              // Responsive card dimensions with safety padding
                              final cardWidth =
                                  (availableWidth - 36).clamp(280.0, 480.0);
                              final cardHeight =
                                  (availableHeight - 32).clamp(380.0, 680.0);

                              return Center(
                                child: EventSwipeDeck(
                                  key: _deckKey,
                                  events: filteredEvents,
                                  currentIndex: _currentIndex,
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  onIndexChanged: (newIdx) {
                                    setState(() {
                                      _currentIndex = newIdx;
                                    });
                                  },
                                  onCardTap: (event) {
                                    context.push(
                                        '${RouteConstants.events}/${event.id}');
                                  },
                                  onScanAttendance: (event) {
                                    context.push(
                                        '${RouteConstants.attendance}/qr-scan?eventId=${event.id}');
                                  },
                                  onEdit: canEdit
                                      ? (event) {
                                          context.push(
                                              '${RouteConstants.events}/${event.id}/edit',
                                              extra: event);
                                        }
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),

                        // Deck Navigation Controls & Accessibility Previous/Next
                        EventDeckControls(
                          currentIndex: _currentIndex,
                          totalCount: filteredEvents.length,
                          onPrevious: () => _deckKey.currentState?.swipeLeft(),
                          onNext: () => _deckKey.currentState?.swipeRight(),
                        ),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
