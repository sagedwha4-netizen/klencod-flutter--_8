import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DhikriApp());
}

const Color _ink = Color(0xFF102A2A);
const Color _teal = Color(0xFF0E8F83);
const Color _mint = Color(0xFFB9E8D9);
const List<String> _adhkar = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'اللَّهُ أَكْبَرُ',
  'لَا إِلَهَ إِلَّا اللَّهُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
];

class DhikriApp extends StatefulWidget {
  const DhikriApp({super.key});

  @override
  State<DhikriApp> createState() => _DhikriAppState();
}

class _DhikriAppState extends State<DhikriApp> {
  bool _dark = false;

  void _toggleTheme() => setState(() => _dark = !_dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ذكري | Dhikri',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.light,
          surface: const Color(0xFFF1F7F4),
        ),
        fontFamily: 'sans-serif',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.dark,
          surface: const Color(0xFF101D1C),
        ),
      ),
      home: DhikriHome(onToggleTheme: _toggleTheme, isDark: _dark),
    );
  }
}

class DhikriHome extends StatefulWidget {
  const DhikriHome({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<DhikriHome> createState() => _DhikriHomeState();
}

class _DhikriHomeState extends State<DhikriHome>
    with TickerProviderStateMixin {
  int _count = 0;
  int _total = 0;
  int _today = 0;
  int _goal = 33;
  int _selected = 0;
  bool _vibration = true;
  bool _loading = true;
  String _savedDate = '';
  final List<int> _undoStack = [];
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 0.045,
    );
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('saved_date') ?? '';
      final isSameDay = savedDate == _todayKey;
      if (!mounted) return;
      setState(() {
        _count = prefs.getInt('count') ?? 0;
        _total = prefs.getInt('total') ?? 0;
        _today = isSameDay ? (prefs.getInt('today') ?? 0) : 0;
        _goal = prefs.getInt('goal') ?? 33;
        _selected = (prefs.getInt('selected') ?? 0).clamp(0, _adhkar.length - 1).toInt();
        _vibration = prefs.getBool('vibration') ?? true;
        _savedDate = _todayKey;
        _loading = false;
      });
      if (!isSameDay) {
        await prefs.setInt('today', 0);
        await prefs.setString('saved_date', _todayKey);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('count', _count);
      await prefs.setInt('total', _total);
      await prefs.setInt('today', _today);
      await prefs.setInt('goal', _goal);
      await prefs.setInt('selected', _selected);
      await prefs.setBool('vibration', _vibration);
      await prefs.setString('saved_date', _todayKey);
    } catch (_) {
      // The counter remains usable even if local storage is temporarily unavailable.
    }
  }

  Future<void> _tapDhikr() async {
    if (_loading) return;
    setState(() {
      _count++;
      _total++;
      _today++;
      _undoStack.add(1);
    });
    _pulseController.forward(from: 0).then((_) {
      if (mounted) _pulseController.reverse();
    });
    if (_vibration) HapticFeedback.selectionClick();
    await _saveData();
    if (mounted && _count == _goal) _showGoalDialog();
  }

  Future<void> _undo() async {
    if (_count <= 0 || _undoStack.isEmpty) return;
    setState(() {
      _undoStack.removeLast();
      _count--;
      if (_total > 0) _total--;
      if (_today > 0) _today--;
    });
    await _saveData();
  }

  Future<void> _resetCounter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفير العدّاد؟'),
        content: const Text('سيتم تصفير عدّاد الذكر الحالي فقط، ولن تُحذف إحصائياتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() {
        _count = 0;
        _undoStack.clear();
      });
      await _saveData();
    }
  }

  Future<void> _showGoalDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, color: _teal, size: 38),
        title: const Text('أحسنت!'),
        content: Text('أكملت هدفك $_goal من ذكر ${_adhkar[_selected]}. تقبّل الله منك.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('الحمد لله'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseDhikr(int index) async {
    setState(() {
      _selected = index;
      _count = 0;
      _undoStack.clear();
    });
    await _saveData();
  }

  Future<void> _chooseGoal(int goal) async {
    setState(() => _goal = goal);
    await _saveData();
  }

  Future<void> _toggleVibration(bool value) async {
    setState(() => _vibration = value);
    await _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _ink;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ذِكري', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Dhikri', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تغيير المظهر',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: _showSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  _welcomeCard(isDark),
                  const SizedBox(height: 18),
                  _dhikrSelector(isDark),
                  const SizedBox(height: 20),
                  _counterCard(isDark, textColor),
                  const SizedBox(height: 18),
                  _statsRow(isDark),
                  const SizedBox(height: 18),
                  _achievements(isDark),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'اجعل لسانك رطبًا بذكر الله',
                      style: TextStyle(color: textColor.withOpacity(.58), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _welcomeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0E8F83), Color(0xFF145B58)],
        ),
        boxShadow: [
          BoxShadow(color: _teal.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السلام عليك', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 7),
                Text('ابدأ ذكرك بقلبٍ حاضر', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('لحظات قصيرة… وأجر عظيم بإذن الله', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.spa_rounded, color: Color(0xFFD5F5E8), size: 48),
        ],
      ),
    );
  }

  Widget _dhikrSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر الذكر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _adhkar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _selected;
              return ChoiceChip(
                label: Text(_adhkar[index], textDirection: TextDirection.rtl),
                selected: selected,
                onSelected: (_) => _chooseDhikr(index),
                selectedColor: _teal.withOpacity(.18),
                side: BorderSide(color: selected ? _teal : Colors.grey.withOpacity(.25)),
                labelStyle: TextStyle(
                  color: selected ? _teal : Theme.of(context).colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _counterCard(bool isDark, Color textColor) {
    final progress = (_count / _goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B29) : Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? .10 : .045), blurRadius: 24, offset: const Offset(0, 9)),
        ],
      ),
      child: Column(
        children: [
          Text(_adhkar[_selected], style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text('اضغط على الدائرة للتسبيح', style: TextStyle(color: textColor.withOpacity(.55), fontSize: 12)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _tapDhikr,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.045).animate(_pulse),
              child: SizedBox(
                width: 226,
                height: 226,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _teal.withOpacity(.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                      ),
                    ),
                    Container(
                      width: 194,
                      height: 194,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const [Color(0xFF284B46), Color(0xFF172E2B)]
                              : const [Color(0xFFE8F8F1), Color(0xFFD3EFE4)],
                        ),
                        boxShadow: [
                          BoxShadow(color: _teal.withOpacity(.12), blurRadius: 22, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$_count', style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w800, color: _teal, height: 1.1)),
                          Text('من $_goal', style: TextStyle(color: textColor.withOpacity(.6), fontSize: 14)),
                          const SizedBox(height: 7),
                          const Icon(Icons.touch_app_rounded, color: _teal, size: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _goalButton(33),
              const SizedBox(width: 8),
              _goalButton(99),
              const SizedBox(width: 8),
              _goalButton(100),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('تراجع'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _resetCounter,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تصفير'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalButton(int value) {
    final selected = _goal == value;
    return OutlinedButton(
      onPressed: () => _chooseGoal(value),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        backgroundColor: selected ? _teal.withOpacity(.12) : Colors.transparent,
        side: BorderSide(color: selected ? _teal : Colors.grey.withOpacity(.3)),
        foregroundColor: selected ? _teal : null,
      ),
      child: Text('$value'),
    );
  }

  Widget _statsRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _statCard('ذكر اليوم', _today, Icons.today_rounded, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('إجمالي الأذكار', _total, Icons.auto_awesome_rounded, isDark)),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B29) : Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievements(bool isDark) {
    final milestones = [33, 99, 500, 1000];
    final labels = ['بداية طيبة', 'مُثابر', 'ذاكر', 'همة عالية'];
    final icons = [Icons.eco_rounded, Icons.local_fire_department_rounded, Icons.stars_rounded, Icons.workspace_premium_rounded];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B29) : Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFC99A37)),
              SizedBox(width: 8),
              Text('إنجازاتك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: List.generate(milestones.length, (i) {
              final unlocked = _total >= milestones[i];
              return Container(
                width: 138,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unlocked ? _teal.withOpacity(.12) : Colors.grey.withOpacity(.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: unlocked ? _teal.withOpacity(.35) : Colors.grey.withOpacity(.12)),
                ),
                child: Row(
                  children: [
                    Icon(icons[i], color: unlocked ? _teal : Colors.grey, size: 22),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labels[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${milestones[i]} ذكر', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الإعدادات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('الاهتزاز عند التسبيح'),
                  value: _vibration,
                  onChanged: (value) {
                    setSheetState(() {});
                    _toggleVibration(value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('حول التطبيق'),
                  subtitle: const Text('ذكري | Dhikri — مسبحة إلكترونية تعمل دون إنترنت'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}