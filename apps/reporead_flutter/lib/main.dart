import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

void main() {
  runApp(const RepoReadApp());
}

class RepoReadApp extends StatelessWidget {
  const RepoReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepoRead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const _kRepoPath = 'reporead.lastRepoPath';
  static const _kSplitMainLog = 'reporead.split.mainLog';
  static const _kSplitLeftRight = 'reporead.split.leftRight';
  static const _kSplitPackagesActions = 'reporead.split.packagesActions';

  final TextEditingController _repoCtrl = TextEditingController();
  final TextEditingController _commitCtrl =
      TextEditingController(text: '🤖 Update package list');

  final List<String> _packages = ['provider', 'http', 'path'];
  final List<String> _log = [];

  // Tab controller for Log panel
  late TabController _tabController;

  // Split ratios (0..1)
  double _splitMainLog = 0.78; // main vs log
  double _splitLeftRight = 0.48; // left col vs preview
  double _splitPackagesActions = 0.68; // packages vs actions (left column)

  // Live preview = generated README (läge B)
  String _generatedReadme = '';

  // Panel layout management
  String _topLeftPanel = 'workspace';  // workspace contains packages+actions
  String _topRightPanel = 'preview';
  String _topPanel = 'repo';
  String _bottomPanel = 'log';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generatedReadme = _buildReadmeMarkdown();
    _restoreSettings();
    _logAdd('✅ RepoRead startad');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _repoCtrl.dispose();
    _commitCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _repoCtrl.text = prefs.getString(_kRepoPath) ?? _repoCtrl.text;
      _splitMainLog = (prefs.getDouble(_kSplitMainLog) ?? _splitMainLog).clamp(0.15, 0.9);
      _splitLeftRight = (prefs.getDouble(_kSplitLeftRight) ?? _splitLeftRight).clamp(0.2, 0.8);
      _splitPackagesActions =
          (prefs.getDouble(_kSplitPackagesActions) ?? _splitPackagesActions).clamp(0.2, 0.8);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRepoPath, _repoCtrl.text);
    await prefs.setDouble(_kSplitMainLog, _splitMainLog);
    await prefs.setDouble(_kSplitLeftRight, _splitLeftRight);
    await prefs.setDouble(_kSplitPackagesActions, _splitPackagesActions);
  }

  void _logAdd(String msg) {
    final ts = DateFormat('HH:mm:ss').format(DateTime.now());
    setState(() => _log.add('[$ts] $msg'));
  }

  String _buildReadmeMarkdown() {
    final pkgs = [..._packages]..sort();
    final lines = <String>[
      '# 📦 RepoRead (Generated)',
      '',
      'My published packages on pub.dev',
      '',
      '| Package | Version | Pub Points | Popularity | Link |',
      '|---------|---------|------------|------------|------|',
      ...pkgs.map((name) => '| **$name** | '
          '![version](https://img.shields.io/pub/v/$name.svg) | '
          '![points](https://img.shields.io/pub/points/$name) | '
          '![popularity](https://img.shields.io/pub/popularity/$name) | '
          '[pub.dev](https://pub.dev/packages/$name) |'),
      '',
      '---',
      '*Generated locally by RepoRead.*',
    ];
    return lines.join('\n');
  }

  void _regenPreview() {
    setState(() => _generatedReadme = _buildReadmeMarkdown());
  }

  void _sortAZ() {
    setState(() => _packages.sort());
    _regenPreview();
    _logAdd('🔤 Sort A–Z');
  }

  void _detectDuplicates() {
    final seen = <String>{};
    final dups = <String>{};
    for (final p in _packages) {
      if (!seen.add(p)) dups.add(p);
    }
    if (dups.isEmpty) {
      _logAdd('✅ Inga dubletter hittades');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inga dubletter 🎉')),
      );
    } else {
      _logAdd('⚠️ Dubletter: ${dups.join(', ')}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dubletter: ${dups.join(', ')}')),
      );
    }
  }

  void _copyBadgeRow(String pkg) {
    // Här skulle du egentligen lägga detta på clipboard (Clipboard.setData).
    // Jag loggar bara i prototypen.
    final row =
        '![version](https://img.shields.io/pub/v/$pkg.svg) '
        '![points](https://img.shields.io/pub/points/$pkg) '
        '![popularity](https://img.shields.io/pub/popularity/$pkg)';
    _logAdd('📋 Copy badge row: $pkg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(row), duration: const Duration(seconds: 2)),
    );
  }

  void _swapPanels(String droppedPanelId, String targetPosition) {
    setState(() {
      // Find which position has the dropped panel
      String? droppedPosition;
      
      if (_topLeftPanel == droppedPanelId) {
        droppedPosition = 'topLeft';
      } else if (_topRightPanel == droppedPanelId) {
        droppedPosition = 'topRight';
      } else if (_topPanel == droppedPanelId) {
        droppedPosition = 'top';
      } else if (_bottomPanel == droppedPanelId) {
        droppedPosition = 'bottom';
      }
      
      if (droppedPosition == null) return;
      
      // Get target panel
      String targetPanel = '';
      switch (targetPosition) {
        case 'topLeft': targetPanel = _topLeftPanel; break;
        case 'topRight': targetPanel = _topRightPanel; break;
        case 'top': targetPanel = _topPanel; break;
        case 'bottom': targetPanel = _bottomPanel; break;
      }
      
      // Swap
      switch (droppedPosition) {
        case 'topLeft': _topLeftPanel = targetPanel; break;
        case 'topRight': _topRightPanel = targetPanel; break;
        case 'top': _topPanel = targetPanel; break;
        case 'bottom': _bottomPanel = targetPanel; break;
      }
      
      switch (targetPosition) {
        case 'topLeft': _topLeftPanel = droppedPanelId; break;
        case 'topRight': _topRightPanel = droppedPanelId; break;
        case 'top': _topPanel = droppedPanelId; break;
        case 'bottom': _bottomPanel = droppedPanelId; break;
      }
      
      // Reset splitter ratios to safe defaults based on new layout
      _resetSplittersForLayout();
      
      _logAdd('🔄 Swapped: $droppedPanelId ↔ $targetPanel');
    });
  }

  void _resetSplittersForLayout() {
    // Reset workspace internal splitter if workspace is in a constrained position
    if (_topPanel == 'workspace') {
      _splitPackagesActions = 0.5; // 50/50 split for top position
    } else if (_topLeftPanel == 'workspace' || _topRightPanel == 'workspace') {
      _splitPackagesActions = 0.6; // 60/40 split for side positions
    } else {
      _splitPackagesActions = 0.68; // Default 68/32 split
    }
    
    // Adjust main/log split based on what's in bottom
    if (_bottomPanel == 'workspace') {
      _splitMainLog = 0.5; // Give workspace more room in bottom
    } else if (_bottomPanel == 'preview') {
      _splitMainLog = 0.65; // Preview needs decent space
    } else if (_bottomPanel == 'log') {
      _splitMainLog = 0.78; // Default - log takes less space
    } else {
      _splitMainLog = 0.75; // Balanced default
    }
    
    // Adjust left/right split based on content
    if (_topLeftPanel == 'workspace' && _topRightPanel == 'log') {
      _splitLeftRight = 0.7; // Workspace needs more room than log
    } else if (_topLeftPanel == 'repo' && _topRightPanel == 'preview') {
      _splitLeftRight = 0.3; // Preview needs more room than repo
    } else {
      _splitLeftRight = 0.48; // Balanced default
    }
    
    // Save new ratios
    _saveSettings();
  }

  Widget _buildPanelById(String panelId) {
    switch (panelId) {
      case 'workspace':
        return _WorkspaceCard(
          packages: _packages,
          commitCtrl: _commitCtrl,
          splitRatio: _splitPackagesActions,
          onSplitChanged: (r) {
            setState(() => _splitPackagesActions = r);
            _saveSettings();
          },
          onAddPackage: (name) {
            setState(() => _packages.add(name));
            _regenPreview();
            _logAdd('➕ Added package: $name');
          },
          onRemovePackage: (name) {
            setState(() => _packages.remove(name));
            _regenPreview();
            _logAdd('🗑 Removed package: $name');
          },
          onReorderPackages: (oldIndex, newIndex) {
            setState(() {
              final temp = _packages[oldIndex];
              _packages[oldIndex] = _packages[newIndex];
              _packages[newIndex] = temp;
            });
            _regenPreview();
            _logAdd('🔄 Swapped: ${_packages[newIndex]} ↔ ${_packages[oldIndex]}');
          },
          onSort: _sortAZ,
          onDetectDuplicates: _detectDuplicates,
          onCopyBadgeRow: _copyBadgeRow,
          onGenerate: () {
            _regenPreview();
            _logAdd('📝 Generate README (preview uppdaterad)');
          },
          onForcePush: () {
            _logAdd('🚀 Force push (placeholder)');
          },
        );
      
      case 'preview':
        return _TabbedPreviewPanel(
          tabController: _tabController,
          markdown: _generatedReadme,
        );
      
      case 'repo':
        return _Panel(
          title: 'Repo',
          panelId: 'repo',
          accentColor: Colors.cyanAccent,
          child: _RepoPanel(
            repoCtrl: _repoCtrl,
            onChanged: () {
              _saveSettings();
              _logAdd('📂 Repo path ändrad');
            },
            onReload: () {
              _logAdd('🔄 Reload (placeholder)');
            },
          ),
        );
      
      case 'log':
        return _Panel(
          title: 'Log',
          panelId: 'log',
          accentColor: Colors.yellowAccent,
          child: _LogPanel(lines: _log),
        );
      
      default:
        return const Center(child: Text('Unknown panel'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build panels dynamically based on layout state
    final topPanelWidget = _buildPanelById(_topPanel);
    final bottomPanelWidget = _buildPanelById(_bottomPanel);
    final topLeftPanelWidget = _buildPanelById(_topLeftPanel);
    final topRightPanelWidget = _buildPanelById(_topRightPanel);

    // Dynamic height for top panel based on content type
    final topPanelHeight = switch (_topPanel) {
      'workspace' => 400.0,  // Needs space for packages + actions with splitter
      'preview' => 300.0,    // Preview needs space for rendered content
      'repo' => 96.0,        // Repo is compact - just a text field
      'log' => 200.0,        // Log needs space to show multiple entries
      _ => 96.0,             // Default fallback
    };

    // Wrap each position with DragTarget for swapping
    final topPanel = DragTarget<String>(
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        if (droppedData.startsWith('panel_')) {
          final panelId = droppedData.replaceFirst('panel_', '');
          _swapPanels(panelId, 'top');
        } else if (droppedData == 'workspace_packages_actions') {
          _swapPanels('workspace', 'top');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.any((data) => data?.startsWith('panel_') ?? false) ||
                          candidateData.any((data) => data == 'workspace_packages_actions');
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.purpleAccent : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: topPanelWidget,
        );
      },
    );

    final leftColumn = DragTarget<String>(
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        if (droppedData.startsWith('panel_')) {
          final panelId = droppedData.replaceFirst('panel_', '');
          _swapPanels(panelId, 'topLeft');
        } else if (droppedData == 'workspace_packages_actions') {
          _swapPanels('workspace', 'topLeft');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.any((data) => data?.startsWith('panel_') ?? false) ||
                          candidateData.any((data) => data == 'workspace_packages_actions');
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.purpleAccent : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: topLeftPanelWidget,
        );
      },
    );

    final previewPanel = DragTarget<String>(
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        if (droppedData.startsWith('panel_')) {
          final panelId = droppedData.replaceFirst('panel_', '');
          _swapPanels(panelId, 'topRight');
        } else if (droppedData == 'workspace_packages_actions') {
          _swapPanels('workspace', 'topRight');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.any((data) => data?.startsWith('panel_') ?? false) ||
                          candidateData.any((data) => data == 'workspace_packages_actions');
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.purpleAccent : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: topRightPanelWidget,
        );
      },
    );

    final logPanel = DragTarget<String>(
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        if (droppedData.startsWith('panel_')) {
          final panelId = droppedData.replaceFirst('panel_', '');
          _swapPanels(panelId, 'bottom');
        } else if (droppedData == 'workspace_packages_actions') {
          _swapPanels('workspace', 'bottom');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.any((data) => data?.startsWith('panel_') ?? false) ||
                          candidateData.any((data) => data == 'workspace_packages_actions');
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.purpleAccent : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: bottomPanelWidget,
        );
      },
    );

    // Main: left/right split with splitter
    final mainSplit = SplitPane(
      direction: Axis.horizontal,
      ratio: _splitLeftRight,
      minA: 260,
      minB: 280,
      onRatioChanged: (r) {
        setState(() => _splitLeftRight = r);
        _saveSettings();
      },
      a: leftColumn,
      b: previewPanel,
    );

    // Whole: main vs log split with splitter
    final wholeSplit = SplitPane(
      direction: Axis.vertical,
      ratio: _splitMainLog,
      minA: 260,
      minB: 140,
      onRatioChanged: (r) {
        setState(() => _splitMainLog = r);
        _saveSettings();
      },
      a: mainSplit,
      b: logPanel,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('RepoRead'),
        actions: [
          // Status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '${_packages.length} packages',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(height: topPanelHeight, child: topPanel),
            const SizedBox(height: 12),
            Expanded(child: wholeSplit),
          ],
        ),
      ),
    );
  }
}

/// Tabbed Preview Panel with [Preview] and [Markdown] tabs
class _TabbedPreviewPanel extends StatelessWidget {
  final TabController tabController;
  final String markdown;

  const _TabbedPreviewPanel({
    required this.tabController,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Tab bar header
          Container(
            color: Colors.grey[900],
            child: TabBar(
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.visibility, size: 16),
                  text: 'Preview',
                  height: 40,
                ),
                Tab(
                  icon: Icon(Icons.code, size: 16),
                  text: 'Markdown',
                  height: 40,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TabBarView(
                controller: tabController,
                children: [
                  _PreviewContent(markdown: markdown),
                  _MarkdownSource(markdown: markdown),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview content widget (rendered markdown)
class _PreviewContent extends StatelessWidget {
  final String markdown;
  const _PreviewContent({required this.markdown});

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final pkg = details.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📋 Showing badges for "$pkg"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.greenAccent : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Markdown(
                data: markdown,
                selectable: true,
                onTapLink: (text, href, title) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open link: $href')),
                  );
                },
              ),
              if (isHovering)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🎯 Drop to view badges',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LogPanel extends StatelessWidget {
  final List<String> lines;
  const _LogPanel({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        itemCount: lines.length,
        itemBuilder: (context, i) {
          final line = lines[i];
          // Color code different log types
          Color textColor = Colors.white70;
          if (line.contains('✅')) {
            textColor = Colors.greenAccent;
          } else if (line.contains('⚠️')) {
            textColor = Colors.orangeAccent;
          } else if (line.contains('🚀')) {
            textColor = Colors.blueAccent;
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: textColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Markdown source viewer
class _MarkdownSource extends StatelessWidget {
  final String markdown;
  const _MarkdownSource({required this.markdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          markdown,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// A simple splitter pane: two children and a draggable divider.
/// Stores size as ratio (0..1) relative to available main axis.
class SplitPane extends StatelessWidget {
  final Axis direction;
  final double ratio;
  final double minA;
  final double minB;
  final Widget a;
  final Widget b;
  final ValueChanged<double> onRatioChanged;

  const SplitPane({
    super.key,
    required this.direction,
    required this.ratio,
    required this.minA,
    required this.minB,
    required this.a,
    required this.b,
    required this.onRatioChanged,
  });

  static const double dividerThickness = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final total = direction == Axis.horizontal ? c.maxWidth : c.maxHeight;
      final usable = math.max(0, total - dividerThickness);

      // Enforce min sizes
      final minRatio = (minA / usable).clamp(0.0, 1.0);
      final maxRatio = (1 - (minB / usable)).clamp(0.0, 1.0);
      final clamped = ratio.clamp(minRatio, maxRatio);

      final aSize = usable * clamped;
      final bSize = usable - aSize;

      final divider = _Splitter(
        direction: direction,
        onDelta: (delta) {
          final newA = (aSize + delta).clamp(minA, usable - minB);
          final newRatio = (newA / usable).clamp(minRatio, maxRatio);
          onRatioChanged(newRatio);
        },
      );

      if (direction == Axis.horizontal) {
        return Row(
          children: [
            SizedBox(width: aSize, child: a),
            SizedBox(width: dividerThickness, child: divider),
            SizedBox(width: bSize, child: b),
          ],
        );
      } else {
        return Column(
          children: [
            SizedBox(height: aSize, child: a),
            SizedBox(height: dividerThickness, child: divider),
            SizedBox(height: bSize, child: b),
          ],
        );
      }
    });
  }
}

class _Splitter extends StatefulWidget {
  final Axis direction;
  final ValueChanged<double> onDelta;

  const _Splitter({required this.direction, required this.onDelta});

  @override
  State<_Splitter> createState() => _SplitterState();
}

class _SplitterState extends State<_Splitter> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isH = widget.direction == Axis.horizontal;

    return MouseRegion(
      cursor: isH ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.resizeUpDown,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          final delta = isH ? d.delta.dx : d.delta.dy;
          widget.onDelta(delta);
        },
        child: Container(
          decoration: BoxDecoration(
            color: _hover ? Colors.white12 : Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Container(
              width: isH ? 2 : 42,
              height: isH ? 42 : 2,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Workspace Card - Contains multiple panels and can be dragged as a unit
class _WorkspaceCard extends StatelessWidget {
  final List<String> packages;
  final TextEditingController commitCtrl;
  final double splitRatio;
  final ValueChanged<double> onSplitChanged;
  final void Function(String name) onAddPackage;
  final void Function(String name) onRemovePackage;
  final void Function(int oldIndex, int newIndex) onReorderPackages;
  final VoidCallback onSort;
  final VoidCallback onDetectDuplicates;
  final void Function(String pkg) onCopyBadgeRow;
  final VoidCallback onGenerate;
  final VoidCallback onForcePush;

  const _WorkspaceCard({
    required this.packages,
    required this.commitCtrl,
    required this.splitRatio,
    required this.onSplitChanged,
    required this.onAddPackage,
    required this.onRemovePackage,
    required this.onReorderPackages,
    required this.onSort,
    required this.onDetectDuplicates,
    required this.onCopyBadgeRow,
    required this.onGenerate,
    required this.onForcePush,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[850],
      child: Column(
        children: [
          // Workspace drag handle - ONLY THIS PART IS DRAGGABLE
          Draggable<String>(
            data: 'workspace_packages_actions',
            feedbackOffset: const Offset(-100, -16),
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 200,
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildWorkspaceHeader(),
            ),
            child: _buildWorkspaceHeader(),
          ),
          // Content: Packages + Actions with splitter - NOT WRAPPED IN DRAGGABLE
          Expanded(
            child: SplitPane(
              direction: Axis.vertical,
              ratio: splitRatio,
              minA: 100,  // Reduced from 160 to allow tighter spaces
              minB: 80,   // Reduced from 140 to allow tighter spaces
              onRatioChanged: onSplitChanged,
              a: _Panel(
                title: 'Packages',
                panelId: 'packages',
                accentColor: Colors.greenAccent,
                child: _PackagesPanel(
                  packages: packages,
                  onAdd: onAddPackage,
                  onRemove: onRemovePackage,
                  onReorder: onReorderPackages,
                  onSort: onSort,
                  onDetectDuplicates: onDetectDuplicates,
                  onCopyBadgeRow: onCopyBadgeRow,
                ),
              ),
              b: _Panel(
                title: 'Actions',
                panelId: 'actions',
                accentColor: Colors.orangeAccent,
                child: _ActionsPanel(
                  commitCtrl: commitCtrl,
                  onGenerate: onGenerate,
                  onForcePush: onForcePush,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.dashboard, size: 16, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          const Text(
            'Workspace',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.purpleAccent,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.drag_handle, size: 18, color: Colors.purpleAccent.withValues(alpha: 0.7)),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? accentColor;
  final String panelId;

  const _Panel({
    required this.title, 
    required this.child,
    required this.panelId,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Colors.blueAccent;
    
    return Draggable<String>(
      data: 'panel_$panelId',
      feedbackOffset: const Offset(-100, -50), // Center feedback on cursor
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getIconForTitle(title), color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildPanelContent(color),
      ),
      child: _buildPanelContent(color),
    );
  }

  Widget _buildPanelContent(Color color) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        children: [
          // Styled header
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(_getIconForTitle(title), size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.drag_handle, size: 18, color: color.withValues(alpha: 0.7)),
                const Spacer(),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'packages':
        return Icons.inventory_2;
      case 'actions':
        return Icons.bolt;
      case 'repo':
        return Icons.folder;
      case 'log':
        return Icons.terminal;
      default:
        return Icons.article;
    }
  }
}

class _RepoPanel extends StatelessWidget {
  final TextEditingController repoCtrl;
  final VoidCallback onChanged;
  final VoidCallback onReload;

  const _RepoPanel({
    required this.repoCtrl,
    required this.onChanged,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: repoCtrl,
            decoration: const InputDecoration(
              labelText: 'Repo path',
              hintText: r'D:\Projects\dart-packages-handbook',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: () {
            // Placeholder: i riktig app öppnar du file picker här.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Browse (kommer senare)')),
            );
          },
          child: const Text('Browse'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onReload,
          child: const Text('Reload'),
        ),
      ],
    );
  }
}

class _PackagesPanel extends StatelessWidget {
  final List<String> packages;
  final void Function(String name) onAdd;
  final void Function(String name) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onSort;
  final VoidCallback onDetectDuplicates;
  final void Function(String pkg) onCopyBadgeRow;

  const _PackagesPanel({
    required this.packages,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    required this.onSort,
    required this.onDetectDuplicates,
    required this.onCopyBadgeRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(onPressed: onSort, child: const Text('Sort A–Z')),
            FilledButton.tonal(onPressed: onDetectDuplicates, child: const Text('Detect duplicates')),
            FilledButton(
              onPressed: () async {
                final name = await _askPackageName(context);
                if (name != null) onAdd(name);
              },
              child: const Text('Add package'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate columns based on width
              final columnCount = (constraints.maxWidth / 200).floor().clamp(1, 3);
              
              return LayoutGrid(
                columnSizes: List.generate(columnCount, (_) => 1.fr),
                rowSizes: List.generate(
                  (packages.length / columnCount).ceil(),
                  (_) => auto,
                ),
                columnGap: 8,
                rowGap: 8,
                children: packages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  
                  return DragTarget<String>(
                    onAcceptWithDetails: (details) {
                      final droppedPkg = details.data;
                      
                      // Swap positions
                      final droppedIndex = packages.indexOf(droppedPkg);
                      final currentIndex = i;
                      
                      if (droppedIndex != -1 && currentIndex != droppedIndex) {
                        onReorder(droppedIndex, currentIndex);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;
                      
                      return Draggable<String>(
                        data: p,
                        feedbackOffset: const Offset(-100, -30), // Center on cursor
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  p,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _PackageCard(
                            packageName: p,
                            onCopyBadgeRow: onCopyBadgeRow,
                            onRemove: onRemove,
                            isHovering: false,
                          ),
                        ),
                        child: _PackageCard(
                          packageName: p,
                          onCopyBadgeRow: onCopyBadgeRow,
                          onRemove: onRemove,
                          isHovering: isHovering,
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<String?> _askPackageName(BuildContext context) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add package'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'lowercase, a-z 0-9 _',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final s = (v ?? '').trim().toLowerCase();
              final ok = RegExp(r'^[a-z0-9_]+$').hasMatch(s);
              if (s.isEmpty) return 'Skriv ett namn';
              if (!ok) return 'Endast a-z, 0-9 och _ (lowercase)';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, ctrl.text.trim().toLowerCase());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Package card widget for grid display
class _PackageCard extends StatelessWidget {
  final String packageName;
  final void Function(String pkg) onCopyBadgeRow;
  final void Function(String pkg) onRemove;
  final bool isHovering;

  const _PackageCard({
    required this.packageName,
    required this.onCopyBadgeRow,
    required this.onRemove,
    this.isHovering = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHovering ? 8 : 2,
      color: isHovering ? Colors.blueAccent.withValues(alpha: 0.2) : null,
      child: InkWell(
        onTap: () {
          // Could show package details
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2, 
                      size: 16, 
                      color: isHovering ? Colors.blueAccent : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        packageName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isHovering ? Colors.blueAccent : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Copy badge row',
                      onPressed: () => onCopyBadgeRow(packageName),
                      icon: const Icon(Icons.content_copy, size: 16),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => onRemove(packageName),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  final TextEditingController commitCtrl;
  final VoidCallback onGenerate;
  final VoidCallback onForcePush;

  const _ActionsPanel({
    required this.commitCtrl,
    required this.onGenerate,
    required this.onForcePush,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final pkg = details.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 Dropped "$pkg" on Actions - Quick generate!'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextField(
                controller: commitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Commit message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(onPressed: onGenerate, child: const Text('Generate README')),
                  FilledButton(onPressed: onForcePush, child: const Text('Force Push')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isHovering 
                  ? '🎯 Drop here for quick action!'
                  : 'Drag packages here for quick actions\n' 
                    'Git-kommandon kopplas in senare (Process.run).',
                style: TextStyle(
                  color: isHovering ? Colors.blueAccent : Colors.white54, 
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}