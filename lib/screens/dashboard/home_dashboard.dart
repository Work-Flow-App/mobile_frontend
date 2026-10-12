import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_screen.dart';
import 'package:mobile_frontend/widgets/filter_bar.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'assigned_step_list_view.dart';
import 'package:go_router/go_router.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  void _showMenuBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    final isAdmin = authState.role == 'ADMIN';
    final username = authState.username ?? "User";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4, // Slightly larger minimum
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // 1. Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    height: 5,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // 2. Scrollable Content with Fading Edge
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white, // Fully opaque
                            Colors.white, // Fully opaque
                            Colors.white.withOpacity(0.05), // Faded out
                          ],
                          stops: const [
                            0.0,
                            0.85,
                            1.0,
                          ], // Fade happens in the last 15%
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: RawScrollbar(
                        controller: scrollController,
                        thumbColor: Colors.black26,
                        radius: const Radius.circular(8),
                        thickness: 4,
                        thumbVisibility: true, // Forces scrollbar to be visible
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            const SizedBox(height: 16),
                            // Brand Logo
                            Center(
                              child: SvgPicture.asset(
                                'assets/images/WorkFloow_text.svg',
                                height: 28,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // User Profile Section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.black.withOpacity(
                                      0.05,
                                    ),
                                    child: Text(
                                      isAdmin ? "A" : "U",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAdmin ? "Administrator" : "Staff",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          username,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Category Header: Workspace
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 8,
                              ),
                              child: Text(
                                "WORKSPACE",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),

                            // Navigation Menu Items
                            _buildMenuItem(
                              context: context,
                              icon: Icons.task_alt,
                              title: 'My Tasks',
                              isSelected: true,
                              onTap: () => Navigator.pop(context),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.analytics_outlined,
                              title: 'Task Overview',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/task-stats');
                              },
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.inventory_2_outlined,
                              title: 'My Assets',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/my-assets');
                              },
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.assignment_outlined,
                              title: 'My Forms',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/my-forms');
                              },
                            ),

                            // You can add more mock items here to test the scroll!
                            const SizedBox(
                              height: 40,
                            ), // Extra padding at bottom for the fade
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Fixed Footer (Logout)
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: _buildMenuItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(authNotifierProvider.notifier).logout();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for modern menu items
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isDestructive = false,
  }) {
    // Define colors based on item state
    final contentColor = isDestructive
        ? Colors.red.shade700
        : (isSelected ? Colors.black : Colors.grey.shade800);

    final backgroundColor = isSelected
        ? Colors.black.withOpacity(0.05)
        : (isDestructive ? Colors.red.withOpacity(0.05) : Colors.transparent);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: contentColor, size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: contentColor,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(assignedStepsFutureProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      // 1. Position the FAB at the bottom left
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // 2. Add the FAB
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _showMenuBottomSheet(context, ref, authState),
        backgroundColor: Colors.black, // Match your app branding
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.menu, size: 20),
      ),

      body: stepsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(assignedStepsFutureProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: const Center(child: Text("No steps found")),
              ),
            ],
          ),
        ),
        data: (allSteps) {
          // Wrap your layout builder in a NestedScrollView
          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                // Use SliverAppBar for the floating effect
                SliverAppBar(
                  title: const Text(
                    "My Tasks",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  floating: true, // Appears as soon as you scroll up
                  snap: true, // Snaps fully into view when scrolling up
                  pinned:
                      false, // Scrolls completely out of view when scrolling down
                  backgroundColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor, // Matches app background
                  foregroundColor:
                      Colors.black, // Ensures text and icons are visible
                  elevation: 2, // Gives a slight shadow when floating
                  shadowColor: Colors.black.withOpacity(0.3),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: AppBranding(
                        color: Colors
                            .black, // Changed to black to match the new light app bar
                        size: 24,
                        fontSize: 18,
                      ),
                    ),
                  ],
                  bottom: const PreferredSize(
                    // Adjust this height if your FilterBar is taller or shorter
                    preferredSize: Size.fromHeight(60.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: FilterBar(),
                    ),
                  ),
                ),
              ];
            },
            // The body contains your standard Mobile/Tablet layouts
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return const TabletSplitView();
                } else {
                  return const MobileStepListView();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class MobileStepListView extends StatelessWidget {
  const MobileStepListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssignedStepListView();
  }
}

class TabletSplitView extends ConsumerWidget {
  const TabletSplitView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStepId = ref.watch(selectedStepIdProvider);
    final allSteps = ref.watch(assignedStepsFutureProvider).value ?? [];

    Widget detailView;
    if (selectedStepId == null) {
      detailView = const Center(
        child: Text(
          "Select a task to view details.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else {
      final selectedJobData = allSteps.firstWhere(
        (s) => s.step.id == selectedStepId,
      );
      detailView = StepDetailScreen(jobData: selectedJobData, isEmbedded: true);
    }

    return Row(
      children: [
        const SizedBox(width: 350, child: AssignedStepListView(isTablet: true)),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(color: Colors.grey[50], child: detailView),
        ),
      ],
    );
  }
}
