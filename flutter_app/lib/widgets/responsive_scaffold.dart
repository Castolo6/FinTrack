import 'package:flutter/material.dart';

class AppDestination {
  final String label;
  final IconData icon;
  final Widget screen;

  AppDestination({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

class ResponsiveScaffold extends StatefulWidget {
  final String title;
  final List<AppDestination> destinations;
  final List<AppDestination>? moreDestinations;
  final FloatingActionButton? floatingActionButton;
  final VoidCallback? onSignOut;
  final Widget? banner;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.destinations,
    this.moreDestinations,
    this.floatingActionButton,
    this.onSignOut,
    this.banner,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _selectedIndex = 0;
  final _moreNavigatorKey = GlobalKey<_MoreWrapperState>();

  bool get _hasMore => widget.moreDestinations?.isNotEmpty ?? false;
  int get _moreIndex => _hasMore ? 4 : -1;

  void _onDestinationSelected(int index) {
    if (index == _moreIndex && index == _selectedIndex) {
      // User tapped "Más" again while already in Más: return to the submenu.
      _moreNavigatorKey.currentState?.popToMenu();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 800;
    final colorScheme = Theme.of(context).colorScheme;

    final mobileDestinations = isDesktop
        ? widget.destinations
        : [
            ...widget.destinations.take(4),
            if (_hasMore)
              AppDestination(
                label: 'Más',
                icon: Icons.more_horiz,
                screen: _MoreWrapper(
                  key: _moreNavigatorKey,
                  destinations: widget.moreDestinations!,
                ),
              ),
          ];

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                mobileDestinations[_selectedIndex].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              actions: [
                if (widget.floatingActionButton != null && size.width >= 120)
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Añadir movimiento',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    onPressed: () =>
                        widget.floatingActionButton!.onPressed?.call(),
                  ),
                if (widget.onSignOut != null && size.width >= 260)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesión',
                    onPressed: widget.onSignOut,
                  ),
              ],
            ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  extended: size.width >= 1100,
                  destinations: widget.destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                ),
                VerticalDivider(width: 1, color: colorScheme.outline),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(widget.title),
                        actions: widget.onSignOut == null
                            ? null
                            : [
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  tooltip: 'Cerrar sesión',
                                  onPressed: widget.onSignOut,
                                ),
                              ],
                      ),
                      if (widget.banner != null) widget.banner!,
                      Expanded(
                        child: widget.destinations[_selectedIndex].screen,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (widget.banner != null) widget.banner!,
                Expanded(
                  child: SafeArea(
                    child: mobileDestinations[_selectedIndex].screen,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: mobileDestinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.icon),
                      label: d.label,
                      tooltip: d.label,
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: isDesktop ? widget.floatingActionButton : null,
    );
  }
}

class _MoreWrapper extends StatefulWidget {
  final List<AppDestination> destinations;

  const _MoreWrapper({super.key, required this.destinations});

  @override
  State<_MoreWrapper> createState() => _MoreWrapperState();
}

class _MoreWrapperState extends State<_MoreWrapper> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void popToMenu() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => _MoreMenu(destinations: widget.destinations),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final List<AppDestination> destinations;

  const _MoreMenu({required this.destinations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Más',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: destinations.asMap().entries.map((entry) {
                final d = entry.value;
                final isLast = entry.key == destinations.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(d.icon, color: colorScheme.primary),
                      title: Text(d.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => d.screen));
                      },
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
