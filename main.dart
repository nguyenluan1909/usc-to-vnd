import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const USCApp());

class USCApp extends StatelessWidget {
  const USCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USC to VND Converter',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA544)),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _uscController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: "263");
  String _resultFormatted = "";
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _calculate() {
    double usc = double.tryParse(_uscController.text) ?? 0;
    double rate = double.tryParse(_rateController.text) ?? 0;
    double result = usc * rate;
    
    setState(() {
      _resultFormatted = usc > 0 
          ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(result)
          : "";
    });
    
    if (usc > 0) _saveToHistory(usc.toString(), _resultFormatted);
  }

  void _saveToHistory(String usc, String result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String now = DateFormat('dd/MM HH:mm').format(DateTime.now());
    if (_history.isNotEmpty && _history[0]['usc'] == usc) return;

    setState(() {
      _history.insert(0, {'usc': usc, 'vnd': result, 'time': now});
      if (_history.length > 5) _history.removeLast();
    });
    await prefs.setString('usc_history', json.encode(_history));
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedHistory = prefs.getString('usc_history');
    if (storedHistory != null) {
      setState(() {
        _history = List<Map<String, String>>.from(json.decode(storedHistory).map((item) => Map<String, String>.from(item)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    children: [
                      TextSpan(text: "USC ", style: TextStyle(color: Color(0xFF0EA544))),
                      TextSpan(text: "to VND Converter"),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text("BY NGUYỄN LUÂN ICT • MARKETING PRO", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 24),
                _buildField("Số tiền (USC Cent)", _uscController, "Ví dụ: 8108"),
                _buildField("Tỷ giá hiện tại (1 USC = ? VND)", _rateController, ""),
                _label("Tổng nhận dự kiến"),
                Container(
                  width: double.infinity,
                  height: 55,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0EA544), width: 1.5),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_resultFormatted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0EA544))),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_resultFormatted.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: _resultFormatted.replaceAll(RegExp(r'[^0-9]'), '')));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã sao chép số tiền!")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Sao chép VND", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() { _uscController.clear(); _resultFormatted = ""; }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF475569),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Xóa trắng", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lịch sử rút gần đây", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    GestureDetector(
                      onTap: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.remove('usc_history');
                        setState(() => _history = []);
                      },
                      child: const Text("Xóa sạch", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Chưa có giao dịch nào được ghi lại", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  )
                else
                  ..._history.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${item['usc']} USC", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(item['vnd']!, style: const TextStyle(color: Color(0xFF0EA544), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                const SizedBox(height: 20),
                const Text("Dữ liệu lưu cục bộ trên thiết bị của bạn", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String title, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => _calculate(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
  );
}