import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../l10n/translations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/connectivity_service.dart';
import '../services/offline_storage_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.isGuest});

  final bool isGuest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isChartExpanded = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isSystemTheme = themeProvider.useSystemTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final connectivityService = context.read<ConnectivityService>();
    final offlineStorageService = OfflineStorageService();
    final isGuest = widget.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('appTitle')),
        actions: [
          IconButton(
            icon: Icon(
              isSystemTheme
                  ? Icons.brightness_auto
                  : (isDarkMode ? Icons.light_mode : Icons.dark_mode),
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: isSystemTheme
                ? t.translate('systemDefault')
                : (isDarkMode ? t.translate('lightTheme') : t.translate('darkTheme')),
          ),
          if (!isSystemTheme)
            IconButton(
              icon: const Icon(Icons.settings_brightness),
              onPressed: () {
                themeProvider.useSystemSettings();
              },
              tooltip: t.translate('systemDefault'),
            ),
          StreamBuilder<bool>(
            stream: connectivityService.connectionStatus,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return IconButton(
                icon: Icon(isConnected ? Icons.cloud_done : Icons.cloud_off),
                onPressed: () async {
                  if (isConnected) {
                    if (!mounted) return;
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(t.translate('syncingData'))),
                    );
                    await offlineStorageService.syncWithFirestore('user_id');
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(t.translate('dataSynced'))),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.translate('offlineMode'))),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (user == null && isGuest)
              MaterialBanner(
                content: Text(t.translate('guestMode')),
                backgroundColor: Colors.amber,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(t.translate('login')),
                  ),
                ],
              ),
            Expanded(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final isLandscape = orientation == Orientation.landscape;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isSmallScreen = screenWidth < 600;

                  Widget content;
                  if (isLandscape) {
                    content = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.4,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildBalanceCard(t),
                                _buildMonthSelector(t),
                                if (!isSmallScreen) _buildSummaryChart(t),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildRecentTransactions(t),
                        ),
                      ],
                    );
                  } else {
                    content = Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildBalanceCard(t),
                                _buildMonthSelector(t),
                                if (screenHeight > 600) _buildSummaryChart(t),
                                _buildRecentTransactions(t),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return content;
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = MediaQuery.of(context).size.width < 600;
            if (isSmallScreen) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'income',
                    onPressed: () => _showAddTransactionDialog(context, TransactionType.income),
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'expense',
                    onPressed: () => _showAddTransactionDialog(context, TransactionType.expense),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.remove),
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'income',
                  onPressed: () => _showAddTransactionDialog(context, TransactionType.income),
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.add),
                  label: Text(t.translate('income')),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'expense',
                  onPressed: () => _showAddTransactionDialog(context, TransactionType.expense),
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.remove),
                  label: Text(t.translate('expense')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Translations t) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final balance = transactions.fold<double>(
      0,
      (sum, transaction) => sum + (transaction.type == TransactionType.income ? transaction.amount : -transaction.amount),
    );

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isChartExpanded = !_isChartExpanded;
        });
      },
      child: Card(
        margin: const EdgeInsets.all(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isChartExpanded ? 200 : 100,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.translate('welcome'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₸${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(Translations t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        title: Text(
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildSummaryChart(Translations t) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final monthlyTransactions = transactions.where((t) =>
        t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();

    final income = monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expenses = monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final total = income + expenses;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('monthlySummary'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          if (income > 0)
                            PieChartSectionData(
                              color: Colors.green,
                              value: income,
                              title: '${((income / total) * 100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (expenses > 0)
                            PieChartSectionData(
                              color: Colors.red,
                              value: expenses,
                              title: '${((expenses / total) * 100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    )
                  : Center(
                      child: Text(
                        t.translate('noTransactions'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(t.translate('income'), income, Colors.green),
                _buildSummaryItem(t.translate('expense'), expenses, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '₸${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(Translations t) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final monthlyTransactions = transactions.where((t) =>
        t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.translate('recentTransactions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          monthlyTransactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      t.translate('noTransactions'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: monthlyTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = monthlyTransactions[index];
                    return Dismissible(
                      key: Key(transaction.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        context.read<TransactionProvider>().removeTransaction(transaction.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                            child: Icon(
                              transaction.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            transaction.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                              ),
                              if (transaction.category != null)
                                Text(
                                  transaction.category!,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₸${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, TransactionType type) {
    final t = Translations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t.translate('add')} ${type == TransactionType.income ? t.translate('income') : t.translate('expense')}'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: t.translate('title')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.translate('pleaseEnterTitle');
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: t.translate('amount'),
                    prefixText: '₸ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.translate('pleaseEnterAmount');
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return t.translate('pleaseEnterValidNumber');
                    }
                    if (amount <= 0) {
                      return t.translate('amountMustBeGreaterThanZero');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: t.translate('category')),
                  value: _selectedCategory,
                  items: [
                    t.translate('food'),
                    t.translate('transport'),
                    t.translate('shopping'),
                    t.translate('bills'),
                    t.translate('entertainment'),
                    t.translate('salary'),
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.translate('pleaseSelectCategory');
                    }
                    return null;
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _addTransaction(type);
              }
            },
            child: Text(t.translate('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _addTransaction(TransactionType type) async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text;
    final amount = double.parse(_amountController.text);
    final category = _selectedCategory;

    final transactionId = const Uuid().v4();

    final transaction = Transaction(
      id: transactionId,
      title: title,
      amount: type == TransactionType.expense ? -amount : amount,
      category: category,
      date: DateTime.now(),
      type: type,
    );

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    provider.addTransaction(transaction);

    if (!mounted) return;

    _titleController.clear();
    _amountController.clear();
    setState(() {
      _selectedCategory = null;
    });
    Navigator.pop(context);
  }
} 