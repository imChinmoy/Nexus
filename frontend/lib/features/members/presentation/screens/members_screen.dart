import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/members_provider.dart';
import '../widgets/draggable_org_network_fab.dart';
import 'member_details_screen.dart';

enum MembersViewMode {
  graph,
  tiers,
}

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  MembersViewMode _viewMode = MembersViewMode.graph;
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _pulseController;
  late final AnimationController _reloadSpinController;
  Timer? _autoRefreshTimer;
  bool _isReloading = false;

  String _searchQuery = '';
  String _selectedDomain = 'All';
  String? _selectedMemberId;

  final List<String> _domains = [
    'All',
    'Technical & Architecture',
    'Web & Mobile Dev',
    'UI/UX & Brand Design',
    'Events & Logistics',
    'PR & Outreach',
    'General Member',
  ];

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'All':
        return Icons.hub_rounded;
      case 'Technical & Architecture':
        return Icons.terminal_rounded;
      case 'Web & Mobile Dev':
        return Icons.phone_android_rounded;
      case 'UI/UX & Brand Design':
        return Icons.palette_rounded;
      case 'Events & Logistics':
        return Icons.event_available_rounded;
      case 'PR & Outreach':
        return Icons.campaign_rounded;
      case 'General Member':
        return Icons.person_outline_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _reloadSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Auto-refresh: Periodically sync member network graph in background every 25 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) {
        _reloadMembers(isSilent: true);
      }
    });

    // Center the graph on root nodes after initial layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerGraphOnRoot();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadMembers(isSilent: true);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _reloadSpinController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _reloadMembers({bool isSilent = false}) async {
    if (_isReloading) return;
    if (!isSilent) {
      HapticFeedback.lightImpact();
      setState(() => _isReloading = true);
      _reloadSpinController.repeat();
    }
    try {
      ref.invalidate(membersProvider);
      await ref.read(membersProvider.future);
    } catch (_) {
      // Gracefully retained by provider fallback
    } finally {
      if (mounted) {
        if (!isSilent) {
          _reloadSpinController.stop();
          _reloadSpinController.reset();
          setState(() => _isReloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Organization graph synced',
                    style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E202E),
            ),
          );
        }
      }
    }
  }

  void _centerGraphOnRoot([Size? canvasSize]) {
    final size = canvasSize ?? const Size(1200, 1100);
    final matrix = Matrix4.identity();
    const scale = 0.85;
    // Calculate translation to place root nodes near top center with clear headroom
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = (screenWidth / 2) - (size.width / 2) * scale;
    const targetY = 40.0;

    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(0, 3, targetX);
    matrix.setEntry(1, 3, targetY);

    _transformationController.value = matrix;
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(1.22, 1.22, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(0.82, 0.82, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _resetView(Size canvasSize) {
    HapticFeedback.lightImpact();
    _centerGraphOnRoot(canvasSize);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canAddMember = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.superAdmin;
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(membersProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'Organization Graph',
          overline: 'NEXUS • ORG GRAPH',
          counterText: membersAsync.whenOrNull(
                data: (members) => '${members.length} members',
              ) ??
              'Network',
          actions: [
            // Manual / Interactive Reloader with smooth rotation animation
            BrlHeaderIconButton(
              tooltip: 'Reload Org Graph',
              isActive: _isReloading,
              child: RotationTransition(
                turns: _reloadSpinController,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: _isReloading ? accent : null,
                ),
              ),
              onTap: () => _reloadMembers(isSilent: false),
            ),
            // View Mode Toggle (Graph vs Tiers)
            BrlHeaderIconButton(
              tooltip: _viewMode == MembersViewMode.graph
                  ? 'Switch to Tier Cards'
                  : 'Switch to Hierarchy Graph',
              icon: _viewMode == MembersViewMode.graph
                  ? Icons.view_agenda_outlined
                  : Icons.account_tree_outlined,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _viewMode = _viewMode == MembersViewMode.graph
                      ? MembersViewMode.tiers
                      : MembersViewMode.graph;
                });
              },
            ),
            if (canAddMember)
              BrlHeaderIconButton(
                tooltip: 'Add Member',
                icon: Icons.person_add_outlined,
                onTap: () => _showAddMemberDialog(context),
              ),
          ],
        ),
        body: Stack(
          children: [
            // 0. Transparent Cybernetic Background Image (assets/images/bg.png)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.22 : 0.09,
                child: Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Subtle Ambient Radial Gradient for Cyber Depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.25),
                    radius: 1.15,
                    colors: [
                      accent.withValues(alpha: isDark ? 0.08 : 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 1. Primary Members View Content
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.hub_outlined,
                    title: 'No Society Members Yet',
                    message:
                        'No users found in database. Invite coordinators or sync with organization directory.',
                  );
                }

                final filteredMembers = _filterMembers(members);

                return Stack(
                  children: [
                    // Primary View: Graph Canvas or Tier Breakdown
                    if (_viewMode == MembersViewMode.graph)
                      _buildGraphView(context, members, filteredMembers, isDark)
                    else
                      _buildTiersView(
                          context, members, filteredMembers, isDark),

                    // 2. Floating HUD Tools (Bottom Right)
                    if (_viewMode == MembersViewMode.graph)
                      Positioned(
                        bottom: 24,
                        right: 16,
                        child: _buildFloatingHUD(isDark),
                      ),

                    // 3. Draggable Org Network FAB with Morphing Expand Animation
                    Positioned.fill(
                      child: DraggableOrgNetworkFab(
                        memberCount: members.length,
                        searchQuery: _searchQuery,
                        onSearchChanged: (val) =>
                            setState(() => _searchQuery = val),
                        selectedDomain: _selectedDomain,
                        onDomainChanged: (val) =>
                            setState(() => _selectedDomain = val),
                        domains: _domains,
                        getDomainIcon: _getDomainIcon,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                    const SizedBox(height: 16),
                    Text(
                      'Building Hierarchy Graph...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 44, color: AppColors.errorOf(context)),
                      const SizedBox(height: 12),
                      Text('Unable to load society network',
                          style: AppTextStyles.headlineSm),
                      const SizedBox(height: 6),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                      const SizedBox(height: 16),
                      BrlButton(
                        label: 'RELOAD NETWORK',
                        onPressed: () => ref.invalidate(membersProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERING LOGIC
  // ---------------------------------------------------------------------------
  List<UserEntity> _filterMembers(List<UserEntity> members) {
    return members.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.domain ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.role.displayName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesDomain = _selectedDomain == 'All' ||
          (m.domain ?? '')
              .toLowerCase()
              .contains(_selectedDomain.toLowerCase());

      return matchesSearch && matchesDomain;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 2. FLOATING HUD TOOLS (ZOOM, RECENTER, LEGEND)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingHUD(bool isDark) {
    final surfaceColor =
        isDark ? const Color(0xDE1C1C24) : const Color(0xF2FFFFFF);
    final borderColor =
        isDark ? const Color(0x2EFFFFFF) : const Color(0x1F000000);
    final iconColor = isDark ? Colors.white70 : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: RotationTransition(
              turns: _reloadSpinController,
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: _isReloading ? AppColors.accentOf(context) : iconColor,
              ),
            ),
            tooltip: 'Reload Org Data',
            onPressed: () => _reloadMembers(isSilent: false),
          ),
          IconButton(
            icon: Icon(Icons.add_rounded, size: 20, color: iconColor),
            tooltip: 'Zoom In',
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: Icon(Icons.remove_rounded, size: 20, color: iconColor),
            tooltip: 'Zoom Out',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: Icon(Icons.center_focus_strong_rounded,
                size: 19, color: AppColors.accentOf(context)),
            tooltip: 'Center Leadership',
            onPressed: () => _resetView(const Size(1200, 1100)),
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, size: 18, color: iconColor),
            tooltip: 'Hierarchy Legend',
            onPressed: _showLegendDialog,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. INTERACTIVE GRAPH CANVAS VIEW
  // ---------------------------------------------------------------------------
  Widget _buildGraphView(
    BuildContext context,
    List<UserEntity> allMembers,
    List<UserEntity> filteredMembers,
    bool isDark,
  ) {
    // Generate graph layout nodes & connections
    final layout = _buildGraphLayout(allMembers);

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.35,
          maxScale: 2.4,
          child: SizedBox(
            width: layout.canvasSize.width,
            height: layout.canvasSize.height,
            child: Stack(
              children: [
                // Animated Glowing Connection Connectors
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: layout.canvasSize,
                      painter: _HierarchyConnectorsPainter(
                        nodes: layout.nodes,
                        pulseValue: _pulseController.value,
                        selectedMemberId: _selectedMemberId,
                        isDark: isDark,
                      ),
                    );
                  },
                ),

                // Nodes with Avatars, Badges, & Role Glows (Centered precisely at node.position)
                for (final node in layout.nodes)
                  _buildMemberNodeWidget(
                    context,
                    node,
                    isFiltered:
                        filteredMembers.any((m) => m.id == node.member.id),
                    isSelected: _selectedMemberId == node.member.id,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberNodeWidget(
    BuildContext context,
    _HierarchyNode node, {
    required bool isFiltered,
    required bool isSelected,
    required bool isDark,
  }) {
    final member = node.member;
    final initials = member.name.trim().isNotEmpty
        ? member.name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'M';

    final diameter = node.radius * 2;
    final haloColor = node.tierColor;
    final isSpotlight =
        isFiltered && (_searchQuery.isNotEmpty || _selectedDomain != 'All');
    final opacity = isFiltered ? 1.0 : 0.32;
    const nodeWidth = 140.0;

    return Positioned(
      left: node.position.dx - (nodeWidth / 2),
      top: node.position.dy - node.radius,
      width: nodeWidth,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: opacity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedMemberId = member.id;
            });
            _showMemberInspectionSheet(context, member, node);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Node Avatar with Radiant Halo Ring (Centered at node.position)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF14141B) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (isSpotlight
                            ? Colors.amberAccent
                            : haloColor.withValues(alpha: isDark ? 0.9 : 0.7)),
                    width: isSelected ? 3.0 : (node.tier <= 1 ? 2.5 : 1.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: haloColor.withValues(
                          alpha: isSelected ? 0.6 : (isDark ? 0.35 : 0.18)),
                      blurRadius: isSelected ? 22 : (node.tier <= 1 ? 16 : 10),
                      spreadRadius: isSelected ? 3 : 1,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Member photo or high-fidelity initials
                    ClipOval(
                      child: SizedBox(
                        width: diameter - 6,
                        height: diameter - 6,
                        child: member.avatar != null &&
                                member.avatar!.isNotEmpty
                            ? Image.network(
                                member.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildInitialsAvatar(initials, haloColor),
                              )
                            : _buildInitialsAvatar(initials, haloColor),
                      ),
                    ),

                    // Top Tier Crown / Shield Badge for Leadership
                    if (node.tier == 0)
                      Positioned(
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded,
                              size: 10, color: Colors.white),
                        ),
                      )
                    else if (node.tier == 1)
                      Positioned(
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded,
                              size: 9, color: Colors.white),
                        ),
                      ),

                    // Active Online Beacon
                    if (member.isActive)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // Name label card under avatar (Centered horizontally)
              Container(
                constraints: const BoxConstraints(maxWidth: 130),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark
                      ? const Color(0xE616161E)
                      : const Color(0xF2FFFFFF)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? haloColor
                        : (isDark
                            ? const Color(0x2EFFFFFF)
                            : const Color(0x1F000000)),
                    width: isSelected ? 1.0 : 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: node.tier <= 1 ? 11.0 : 10.0,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                              color: haloColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.role.shortCode,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: haloColor,
                          ),
                        ),
                        if (member.domain != null &&
                            member.domain!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '• ${member.domain!.split(' ').first}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.15),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: accent,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TIERS BREAKDOWN VIEW (ALTERNATIVE TAB VIEW)
  // ---------------------------------------------------------------------------
  Widget _buildTiersView(
    BuildContext context,
    List<UserEntity> allMembers,
    List<UserEntity> filteredMembers,
    bool isDark,
  ) {
    final tiers = <int, List<UserEntity>>{
      5: allMembers.where((m) => m.role == UserRole.superAdmin).toList(),
      4: allMembers.where((m) => m.role == UserRole.admin).toList(),
      3: allMembers.where((m) => m.role == UserRole.coordinator).toList(),
      2: allMembers.where((m) => m.role == UserRole.volunteer).toList(),
      1: allMembers.where((m) => m.role == UserRole.viewer).toList(),
    };

    return RefreshIndicator(
      color: AppColors.accentOf(context),
      onRefresh: () async {
        ref.invalidate(membersProvider);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 76, 16, 100),
        children: [
          _buildTierGroupCard(
            context,
            title: 'Executive Council',
            levelLabel: 'LEVEL 5 & 4',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFFF59E0B),
            members: [...tiers[5]!, ...tiers[4]!],
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTierGroupCard(
            context,
            title: 'Domain Coordinators',
            levelLabel: 'LEVEL 3',
            icon: Icons.hub_rounded,
            color: const Color(0xFF06B6D4),
            members: tiers[3]!,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTierGroupCard(
            context,
            title: 'Operations Crew & Volunteers',
            levelLabel: 'LEVEL 2',
            icon: Icons.groups_rounded,
            color: const Color(0xFF38BDF8),
            members: tiers[2]!,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          if (tiers[1]!.isNotEmpty)
            _buildTierGroupCard(
              context,
              title: 'Society Members & Observers',
              levelLabel: 'LEVEL 1',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF64748B),
              members: tiers[1]!,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildTierGroupCard(
    BuildContext context, {
    required String title,
    required String levelLabel,
    required IconData icon,
    required Color color,
    required List<UserEntity> members,
    required bool isDark,
  }) {
    return BrlGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  levelLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member List
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No members in this tier',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => Divider(
                height: 12,
                color:
                    isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000),
              ),
              itemBuilder: (context, i) {
                final m = members[i];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberDetailsScreen(member: m),
                        ),
                      );
                    },
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withValues(alpha: 0.35), width: 1),
                      ),
                      child: ClipOval(
                        child: m.avatar != null && m.avatar!.isNotEmpty
                            ? Image.network(m.avatar!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  m.name.isNotEmpty
                                      ? m.name[0].toUpperCase()
                                      : 'M',
                                  style: AppTextStyles.labelMedium.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${m.role.displayName} • ${m.domain ?? m.year ?? 'Society Crew'}',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. MEMBER DETAIL INSPECTION SHEET
  // ---------------------------------------------------------------------------
  void _showMemberInspectionSheet(
      BuildContext context, UserEntity member, _HierarchyNode node) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16161D) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white60 : AppColors.lightTextSecondary;
    final accent = AppColors.accentOf(context);
    final tierColor = node.tierColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Member Identity Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: tierColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: member.avatar != null &&
                                member.avatar!.isNotEmpty
                            ? Image.network(member.avatar!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : 'M',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    fontSize: 22,
                                    color: tierColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.name,
                                  style: AppTextStyles.titleLg.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (member.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34C759)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: const Color(0xFF34C759),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 12, color: textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LEVEL ${member.role.hierarchyLevel} • ${member.role.tierTitle.toUpperCase()}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: tierColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Domain & Year details
                Row(
                  children: [
                    if (member.domain != null && member.domain!.isNotEmpty)
                      Expanded(
                        child: _buildDetailPill(
                          title: 'DOMAIN',
                          value: member.domain!,
                          isDark: isDark,
                        ),
                      ),
                    if (member.year != null && member.year!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailPill(
                          title: 'BATCH / YEAR',
                          value: member.year!,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),

                // Bio
                if (member.bio != null && member.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E26)
                          : const Color(0xFFF4F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.bio!,
                      style: AppTextStyles.editorialQuote.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (member.github != null && member.github!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(member.github!),
                          icon: const Icon(Icons.code_rounded, size: 16),
                          label: const Text('GitHub'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (member.github != null && member.github!.isNotEmpty)
                      const SizedBox(width: 8),
                    if (member.linkedin != null && member.linkedin!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(member.linkedin!),
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('LinkedIn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A66C2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemberDetailsScreen(member: member),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_rounded, size: 16),
                    label: const Text('View Full Member Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPill(
      {required String title, required String value, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLegendDialog() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF11131C).withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle Bar
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Branding Row
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'NEXUS • GOVERNANCE & ACCESS TIERS',
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        // Sleek Circular Glass Close Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title & Description (Role Hierarchy Legend)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Role Hierarchy Legend',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 21,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Operational hierarchy governing graph node elevation, cryptographic privileges, and administration scopes across BRL Nexus.',
                        style: AppTextStyles.editorialSubtitle.copyWith(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Scrollable Structured Tier Cards
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildProfessionalLegendCard(
                              context: ctx,
                              levelCode: 'L-5',
                              badgeLabel: 'EXECUTIVE',
                              title: 'Level 5: Super Admin',
                              subtitle: 'President, Founder & Chief Architect',
                              permissions:
                                  'Full System Control • Key Rotation • Node Elevation',
                              tierColor: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildProfessionalLegendCard(
                              context: ctx,
                              levelCode: 'L-4',
                              badgeLabel: 'LEADERSHIP',
                              title: 'Level 4: Admin',
                              subtitle: 'Technical Lead & Operations Lead',
                              permissions:
                                  'Event Management • User Approvals • Attendance Control',
                              tierColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildProfessionalLegendCard(
                              context: ctx,
                              levelCode: 'L-3',
                              badgeLabel: 'COORDINATION',
                              title: 'Level 3: Coordinator',
                              subtitle:
                                  'Domain Leads (Dev, Design, Events, PR)',
                              permissions:
                                  'Domain Logistics • Session Registries • Student Check-In',
                              tierColor: const Color(0xFF06B6D4),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildProfessionalLegendCard(
                              context: ctx,
                              levelCode: 'L-2',
                              badgeLabel: 'OPERATIONS',
                              title: 'Level 2: Volunteer',
                              subtitle: 'Core Operational Crew & Associates',
                              permissions:
                                  'QR Scanner Verification • On-Ground Event Execution',
                              tierColor: const Color(0xFF38BDF8),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildProfessionalLegendCard(
                              context: ctx,
                              levelCode: 'L-1',
                              badgeLabel: 'OBSERVER',
                              title: 'Level 1: Viewer',
                              subtitle: 'General Society Members & Freshers',
                              permissions:
                                  'Read-Only Network Graph • Event Catalog & Schedule',
                              tierColor: const Color(0xFF94A3B8),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),

                            // Cryptographic Security Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 16, color: accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Permission scopes are cryptographically signed and validated via Bearer JWT tokens on every network payload.',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dismiss Action Button
                    SizedBox(
                      width: double.infinity,
                      child: BrlButton(
                        label: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalLegendCard({
    required BuildContext context,
    required String levelCode,
    required String badgeLabel,
    required String title,
    required String subtitle,
    required String permissions,
    required Color tierColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF181B26).withValues(alpha: 0.75)
            : const Color(0xFFF8FAFC).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withValues(alpha: isDark ? 0.28 : 0.20),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Badge (L-5, L-4...)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tierColor.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                levelCode,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tierColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 13.5,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            tierColor.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.30),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 11,
                      color: tierColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        permissions,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final domainController = TextEditingController();
    UserRole selectedRole = UserRole.volunteer;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF181822),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Invite Society Member',
                  style: AppTextStyles.titleLg.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrlTextField(
                        label: 'Full Name',
                        controller: nameController,
                        hintText: 'e.g. Aryan Mehra'),
                    const SizedBox(height: 12),
                    BrlTextField(
                        label: 'Email',
                        controller: emailController,
                        hintText: 'aryan@akgec.ac.in'),
                    const SizedBox(height: 12),
                    BrlTextField(
                        label: 'Domain',
                        controller: domainController,
                        hintText: 'e.g. Flutter, UI/UX, Cloud'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      dropdownColor: const Color(0xFF22222E),
                      decoration: InputDecoration(
                        labelText: 'Role Hierarchy',
                        labelStyle: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white70),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.displayName} (Level ${r.hierarchyLevel})',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final dio = ref.read(dioClientProvider);
                      await dio.post('/members', data: {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'domain': domainController.text.trim(),
                        'role': selectedRole.backendValue,
                      });
                      ref.invalidate(membersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Member added to hierarchy successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add member: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2997FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Member'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. GRAPH LAYOUT COMPUTATION (SYMMETRIC HIERARCHY WITH GUARANTEED CONNECTIVITY)
  // ---------------------------------------------------------------------------
  _HierarchyLayout _buildGraphLayout(List<UserEntity> members) {
    final nodes = <_HierarchyNode>[];

    // Partition members into tiers
    final tier0 = members.where((m) => m.role == UserRole.superAdmin).toList();
    final tier1 = members.where((m) => m.role == UserRole.admin).toList();
    final tier2 = members.where((m) => m.role == UserRole.coordinator).toList();
    final tier3 = members.where((m) => m.role == UserRole.volunteer).toList();
    final tier4 = members.where((m) => m.role == UserRole.viewer).toList();

    // If no super_admin exists, promote admins to tier 0
    final rootTier = tier0.isNotEmpty ? tier0 : tier1;
    final leadTier = tier0.isNotEmpty ? tier1 : <UserEntity>[];

    final tiersList = [
      rootTier,
      leadTier,
      tier2,
      tier3,
      tier4,
    ].where((t) => t.isNotEmpty).toList();

    // Spacing constants - ample headroom below floating header
    const double verticalSpacing = 190.0;
    const double topMargin = 205.0;
    const double bottomMargin = 160.0;

    final horizontalSpacings = [165.0, 150.0, 135.0, 120.0, 110.0];
    final tierRadii = [32.0, 28.0, 25.0, 22.0, 19.0];
    final tierColors = [
      const Color(0xFFF59E0B), // Super Admin: Amber Gold
      const Color(0xFF8B5CF6), // Admin: Violet Purple
      const Color(0xFF06B6D4), // Coordinator: Neon Cyan
      const Color(0xFF38BDF8), // Volunteer: Electric Sky Blue
      const Color(0xFF64748B), // Viewer: Slate Steel
    ];

    // Compute max width needed
    double maxTierWidth = 600.0;
    for (int t = 0; t < tiersList.length; t++) {
      final count = tiersList[t].length;
      final spacing =
          horizontalSpacings[math.min(t, horizontalSpacings.length - 1)];
      final w = count * spacing;
      if (w > maxTierWidth) maxTierWidth = w;
    }

    final canvasWidth = maxTierWidth + 400.0;
    final canvasHeight =
        topMargin + (tiersList.length * verticalSpacing) + bottomMargin;

    // Track tier nodes to establish connections
    final tierNodesMap = <int, List<_HierarchyNode>>{};

    for (int t = 0; t < tiersList.length; t++) {
      final currentTier = tiersList[t];
      final spacing =
          horizontalSpacings[math.min(t, horizontalSpacings.length - 1)];
      final radius = tierRadii[math.min(t, tierRadii.length - 1)];
      final color = tierColors[math.min(t, tierColors.length - 1)];

      final tierWidth = (currentTier.length - 1) * spacing;
      final startX = (canvasWidth - tierWidth) / 2;
      final y = topMargin + (t * verticalSpacing);

      tierNodesMap[t] = [];

      for (int i = 0; i < currentTier.length; i++) {
        final member = currentTier[i];
        final x = startX + (i * spacing);
        final position = Offset(x, y);

        final parentIds = <String>[];
        final childIds = <String>[];
        final peerIds = <String>[];

        // Horizontal peer council link for co-leaders in tier 0
        if (t == 0 && currentTier.length > 1) {
          for (int j = 0; j < currentTier.length; j++) {
            if (i != j) {
              peerIds.add(currentTier[j].id);
            }
          }
        }

        // Establish connections to parent tier
        if (t > 0 &&
            tierNodesMap.containsKey(t - 1) &&
            tierNodesMap[t - 1]!.isNotEmpty) {
          final parentTierNodes = tierNodesMap[t - 1]!;

          // First try to match by domain
          _HierarchyNode? matchedParent;
          if (member.domain != null && member.domain!.isNotEmpty) {
            matchedParent = parentTierNodes.where((p) {
              return p.member.domain != null &&
                  p.member.domain!
                      .toLowerCase()
                      .contains(member.domain!.toLowerCase().split(' ').first);
            }).firstOrNull;
          }

          if (matchedParent != null) {
            parentIds.add(matchedParent.member.id);
            matchedParent.childIds.add(member.id);
          } else {
            // When parent tier has multiple nodes and child tier has a single node (e.g. 1 Admin under 2 Super Admins):
            // The single child connects to ALL leaders above it, forming a converging pyramid!
            if (currentTier.length == 1) {
              for (final p in parentTierNodes) {
                parentIds.add(p.member.id);
                p.childIds.add(member.id);
              }
            } else {
              // Otherwise connect based on relative position / index
              final p = parentTierNodes[i % parentTierNodes.length];
              parentIds.add(p.member.id);
              p.childIds.add(member.id);
            }
          }
        }

        final node = _HierarchyNode(
          member: member,
          tier: t,
          position: position,
          radius: radius,
          tierColor: color,
          parentIds: parentIds,
          childIds: childIds,
          peerIds: peerIds,
        );

        tierNodesMap[t]!.add(node);
        nodes.add(node);
      }
    }

    // Post-pass: Guarantee that every parent node in tier t connects to at least one child in tier t+1
    for (int t = 0; t < tiersList.length - 1; t++) {
      final parents = tierNodesMap[t] ?? [];
      final children = tierNodesMap[t + 1] ?? [];
      if (parents.isEmpty || children.isEmpty) continue;

      for (final p in parents) {
        if (p.childIds.isEmpty) {
          // Find closest child by horizontal distance
          _HierarchyNode closestChild = children.first;
          double minDistance = (closestChild.position.dx - p.position.dx).abs();
          for (final c in children) {
            final dist = (c.position.dx - p.position.dx).abs();
            if (dist < minDistance) {
              minDistance = dist;
              closestChild = c;
            }
          }
          p.childIds.add(closestChild.member.id);
          if (!closestChild.parentIds.contains(p.member.id)) {
            closestChild.parentIds.add(p.member.id);
          }
        }
      }
    }

    return _HierarchyLayout(
      nodes: nodes,
      canvasSize: Size(canvasWidth, canvasHeight),
    );
  }
}

// -----------------------------------------------------------------------------
// GRAPH DATA MODELS
// -----------------------------------------------------------------------------
class _HierarchyNode {
  final UserEntity member;
  final int tier;
  final Offset position;
  final double radius;
  final Color tierColor;
  final List<String> parentIds;
  final List<String> childIds;
  final List<String> peerIds;

  _HierarchyNode({
    required this.member,
    required this.tier,
    required this.position,
    required this.radius,
    required this.tierColor,
    required this.parentIds,
    required this.childIds,
    this.peerIds = const [],
  });
}

class _HierarchyLayout {
  final List<_HierarchyNode> nodes;
  final Size canvasSize;

  const _HierarchyLayout({required this.nodes, required this.canvasSize});
}

// -----------------------------------------------------------------------------
// CUSTOM PAINTER: CYBER GLOWING BEZIER CONNECTOR BRANCHES
// -----------------------------------------------------------------------------
class _HierarchyConnectorsPainter extends CustomPainter {
  final List<_HierarchyNode> nodes;
  final double pulseValue;
  final String? selectedMemberId;
  final bool isDark;

  _HierarchyConnectorsPainter({
    required this.nodes,
    required this.pulseValue,
    required this.selectedMemberId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle Radial / Dot Matrix Background Grid
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0x0CFFFFFF) : const Color(0x08000000))
      ..strokeWidth = 1.0;

    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        canvas.drawCircle(Offset(x, y), 0.75, gridPaint);
      }
    }

    final nodeMap = {for (final n in nodes) n.member.id: n};

    // 2. Horizontal Peer / Council Connectors (Co-Leaders in Executive Tier)
    for (final node in nodes) {
      for (final peerId in node.peerIds) {
        if (node.member.id.compareTo(peerId) < 0) {
          final peer = nodeMap[peerId];
          if (peer != null) {
            final start = Offset(node.position.dx, node.position.dy);
            final end = Offset(peer.position.dx, peer.position.dy);

            final councilGradient = LinearGradient(
              colors: [
                node.tierColor.withValues(alpha: isDark ? 0.6 : 0.4),
                peer.tierColor.withValues(alpha: isDark ? 0.6 : 0.4),
              ],
            );
            final shader =
                councilGradient.createShader(Rect.fromPoints(start, end));

            final councilGlow = Paint()
              ..shader = shader
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
            canvas.drawLine(start, end, councilGlow);

            final councilStroke = Paint()
              ..shader = shader
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6;
            canvas.drawLine(start, end, councilStroke);

            // Animated light particle along council bridge
            final bridgeT = (pulseValue * 1.5) % 1.0;
            final particlePos = Offset.lerp(start, end, bridgeT);
            if (particlePos != null) {
              final pGlow = Paint()
                ..color = node.tierColor.withValues(alpha: 0.9)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
              canvas.drawCircle(particlePos, 2.8, pGlow);

              final pCore = Paint()..color = Colors.white;
              canvas.drawCircle(particlePos, 1.4, pCore);
            }
          }
        }
      }
    }

    // 3. Draw Branch Curves Connecting Parents to Children (Connected to Head in the Middle)
    for (final node in nodes) {
      for (final parentId in node.parentIds) {
        final parent = nodeMap[parentId];
        if (parent == null) continue;

        final isPathSelected = selectedMemberId == node.member.id ||
            selectedMemberId == parent.member.id ||
            (selectedMemberId != null &&
                (node.childIds.contains(selectedMemberId) ||
                    parent.parentIds.contains(selectedMemberId)));

        // Edges connect directly to the center (middle) of the head of each node!
        final start = Offset(parent.position.dx, parent.position.dy);
        final end = Offset(node.position.dx, node.position.dy);

        final midY = (start.dy + end.dy) / 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx,
            midY,
            end.dx,
            midY,
            end.dx,
            end.dy,
          );

        // Branch gradient from parent color to child color
        final branchGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            parent.tierColor.withValues(
                alpha: isPathSelected ? 0.95 : (isDark ? 0.6 : 0.45)),
            node.tierColor.withValues(
                alpha: isPathSelected ? 0.95 : (isDark ? 0.6 : 0.45)),
          ],
        );

        final shader = branchGradient.createShader(Rect.fromPoints(start, end));

        // Outer glow on connector
        if (isPathSelected || isDark) {
          final glowPaint = Paint()
            ..shader = shader
            ..style = PaintingStyle.stroke
            ..strokeWidth = isPathSelected ? 6.0 : 3.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawPath(path, glowPaint);
        }

        // Crisp inner connector stroke
        final strokePaint = Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = isPathSelected ? 2.6 : 1.4;
        canvas.drawPath(path, strokePaint);

        // Animated Light Flow Particles Traveling Down the Branch
        final metrics = path.computeMetrics().toList();
        for (final metric in metrics) {
          final length = metric.length;
          final particleT = (pulseValue + (node.tier * 0.25)) % 1.0;
          final tangent = metric.getTangentForOffset(length * particleT);

          if (tangent != null) {
            final particleColor =
                isPathSelected ? Colors.white : node.tierColor;
            final particlePaint = Paint()
              ..color = particleColor.withValues(alpha: 0.9)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

            canvas.drawCircle(
                tangent.position, isPathSelected ? 3.5 : 2.2, particlePaint);

            final corePaint = Paint()..color = Colors.white;
            canvas.drawCircle(
                tangent.position, isPathSelected ? 1.8 : 1.1, corePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HierarchyConnectorsPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedMemberId != selectedMemberId ||
        oldDelegate.isDark != isDark;
  }
}
