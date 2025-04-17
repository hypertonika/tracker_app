import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isChartExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final isSystemTheme = themeProvider.useSystemTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
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
                ? 'Using system theme'
                : (isDarkMode ? 'Switch to light mode' : 'Switch to dark mode'),
          ),
          if (!isSystemTheme)
            IconButton(
              icon: const Icon(Icons.settings_brightness),
              onPressed: () {
                themeProvider.useSystemSettings();
              },
              tooltip: 'Use system theme',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isSmallScreen = screenWidth < 600;
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 120.0;

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
                          _buildBalanceCard(l10n),
                          _buildMonthSelector(l10n),
                          if (!isSmallScreen) _buildSummaryChart(l10n),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildRecentTransactions(l10n),
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
                          _buildBalanceCard(l10n),
                          _buildMonthSelector(l10n),
                          if (screenHeight > 600) _buildSummaryChart(l10n),
                          _buildRecentTransactions(l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: content,
            );
          },
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
                  label: Text(l10n.income),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'expense',
                  onPressed: () => _showAddTransactionDialog(context, TransactionType.expense),
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.remove),
                  label: Text(l10n.expense),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations l10n) {
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
                    l10n.welcome,
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

  Widget _buildMonthSelector(AppLocalizations l10n) {
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

  Widget _buildSummaryChart(AppLocalizations l10n) {
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
              l10n.monthlySummary,
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
                        l10n.noTransactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(l10n.income, income, Colors.green),
                _buildSummaryItem(l10n.expense, expenses, Colors.red),
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

  Widget _buildRecentTransactions(AppLocalizations l10n) {
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
              l10n.recentTransactions,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          monthlyTransactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      l10n.noTransactions,
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
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCategory;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.add} ${type == TransactionType.income ? l10n.income : l10n.expense}'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.title),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterTitle;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText: '₸ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (amount <= 0) {
                    return l10n.amountMustBeGreaterThanZero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.category),
                value: selectedCategory,
                items: [
                  'Food',
                  'Transport',
                  'Shopping',
                  'Bills',
                  'Entertainment',
                  'Salary',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
                onChanged: (String? newValue) {
                  selectedCategory = newValue;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && selectedCategory != null) {
                final title = titleController.text;
                final amount = double.parse(amountController.text);

                final transaction = Transaction(
                  id: DateTime.now().toString(),
                  title: title,
                  amount: amount,
                  date: DateTime.now(),
                  type: type,
                  category: selectedCategory,
                );

                context.read<TransactionProvider>().addTransaction(transaction);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
} 