import 'dart:io';

mixin Timestamped {
  DateTime? _createdAt;

  void stampCreated() {
    _createdAt = DateTime.now();
  }

  String get createdLabel {
    final DateTime? time = _createdAt;
    if (time == null) {
      return 'N/A';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}

enum Membership {
  regular('Regular', 0.0),
  premium('Premium', 0.20);

  final String label;
  final double discountRate;

  const Membership(this.label, this.discountRate);
}

abstract class CenterRecord with Timestamped {
  final String _id;

  CenterRecord(this._id) {
    stampCreated();
  }

  String get id => _id;

  String get recordType;

  String getSummary();

  void display() {
    print('[$recordType] ${getSummary()} | Created: $createdLabel');
  }
}

class LearningResource extends CenterRecord {
  static int _nextNumber = 1;

  String _title;
  String _category;
  int _totalCopies;
  int _availableCopies;
  double _ratePerDay;

  LearningResource(
      String title, String category, int totalCopies, double ratePerDay)
      : _title = title,
        _category = category,
        _totalCopies = totalCopies,
        _availableCopies = totalCopies,
        _ratePerDay = ratePerDay,
        super(_generateId());

  static String _generateId() {
    final String id = 'R${_nextNumber.toString().padLeft(3, '0')}';
    _nextNumber++;
    return id;
  }

  String get title => _title;
  String get category => _category;
  int get totalCopies => _totalCopies;
  int get availableCopies => _availableCopies;
  double get ratePerDay => _ratePerDay;
  bool get isAvailable => _availableCopies > 0;

  set title(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty.');
    }
    _title = value.trim();
  }

  set ratePerDay(double value) {
    if (value < 0) {
      throw ArgumentError('Rate cannot be negative.');
    }
    _ratePerDay = value;
  }

  bool borrowCopy() {
    if (_availableCopies <= 0) {
      return false;
    }
    _availableCopies--;
    return true;
  }

  void returnCopy() {
    if (_availableCopies < _totalCopies) {
      _availableCopies++;
    }
  }

  @override
  String get recordType => 'Resource';

  @override
  String getSummary() {
    return '$id | $_title ($_category) | '
        'Available: $_availableCopies/$_totalCopies | '
        'Rate: ${formatMoney(_ratePerDay)}/day';
  }
}

class Participant extends CenterRecord {
  static int _nextNumber = 1;
  static const int maxActiveLoans = 3;

  String _name;
  Membership _membership;
  int _activeLoans = 0;

  Participant(String name, Membership membership)
      : _name = name,
        _membership = membership,
        super(_generateId());

  static String _generateId() {
    final String id = 'P${_nextNumber.toString().padLeft(3, '0')}';
    _nextNumber++;
    return id;
  }

  String get name => _name;
  Membership get membership => _membership;
  int get activeLoans => _activeLoans;
  double get discountRate => _membership.discountRate;
  bool get canBorrow => _activeLoans < maxActiveLoans;

  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    _name = value.trim();
  }

  void addLoan() {
    _activeLoans++;
  }

  void removeLoan() {
    if (_activeLoans > 0) {
      _activeLoans--;
    }
  }

  @override
  String get recordType => 'Participant';

  @override
  String getSummary() {
    return '$id | $_name | ${_membership.label} member '
        '(${(discountRate * 100).toStringAsFixed(0)}% discount) | '
        'Active loans: $_activeLoans/$maxActiveLoans';
  }
}

class Transaction extends CenterRecord {
  static int _nextNumber = 1;

  final String _participantId;
  final String _resourceId;
  final int _days;
  final double _fee;
  bool _returned = false;

  Transaction(
      String participantId, String resourceId, int days, double fee)
      : _participantId = participantId,
        _resourceId = resourceId,
        _days = days,
        _fee = fee,
        super(_generateId());

  static String _generateId() {
    final String id = 'T${_nextNumber.toString().padLeft(3, '0')}';
    _nextNumber++;
    return id;
  }

  String get participantId => _participantId;
  String get resourceId => _resourceId;
  int get days => _days;
  double get fee => _fee;
  bool get isReturned => _returned;

  void markReturned() {
    _returned = true;
  }

  @override
  String get recordType => 'Transaction';

  @override
  String getSummary() {
    return '$id | $_participantId borrowed $_resourceId for $_days day(s) | '
        'Fee: ${formatMoney(_fee)} | '
        'Status: ${_returned ? 'Returned' : 'Borrowed'}';
  }
}

class LearningCenter {
  final Map<String, LearningResource> _resources = {};
  final List<Participant> _participants = [];
  final List<Transaction> _transactions = [];

  bool get hasResources => _resources.isNotEmpty;
  bool get hasParticipants => _participants.isNotEmpty;
  bool get hasTransactions => _transactions.isNotEmpty;

  LearningResource addResource(
      String title, String category, int copies, double ratePerDay) {
    final resource = LearningResource(title, category, copies, ratePerDay);
    _resources[resource.id] = resource;
    return resource;
  }

  Participant registerParticipant(String name, Membership membership) {
    final participant = Participant(name, membership);
    _participants.add(participant);
    return participant;
  }

  LearningResource? findResource(String id) {
    return _resources[id.trim().toUpperCase()];
  }

  Participant? findParticipant(String id) {
    final String wanted = id.trim().toUpperCase();
    for (final Participant p in _participants) {
      if (p.id == wanted) {
        return p;
      }
    }
    return null;
  }

  Transaction? findActiveTransaction(String id) {
    final String wanted = id.trim().toUpperCase();
    for (final Transaction t in _transactions) {
      if (t.id == wanted && !t.isReturned) {
        return t;
      }
    }
    return null;
  }

  Transaction? borrow(
      Participant participant, LearningResource resource, int days) {
    if (!participant.canBorrow) {
      print('Cannot borrow: ${participant.name} already has '
          '${Participant.maxActiveLoans} active loans.');
      return null;
    }
    if (!resource.borrowCopy()) {
      print('Cannot borrow: "${resource.title}" has no copies available.');
      return null;
    }
    final double fee =
        computeFee(resource.ratePerDay, days, participant.discountRate);
    final transaction = Transaction(participant.id, resource.id, days, fee);
    _transactions.add(transaction);
    participant.addLoan();
    return transaction;
  }

  void completeReturn(Transaction transaction) {
    transaction.markReturned();
    findResource(transaction.resourceId)?.returnCopy();
    findParticipant(transaction.participantId)?.removeLoan();
  }

  List<CenterRecord> get resourceRecords => _resources.values.toList();
  List<CenterRecord> get participantRecords => List.of(_participants);
  List<CenterRecord> get transactionRecords => List.of(_transactions);

  List<CenterRecord> get allRecords => [
        ...resourceRecords,
        ...participantRecords,
        ...transactionRecords,
      ];

  double get totalRevenue {
    double total = 0;
    for (final Transaction t in _transactions) {
      total += t.fee;
    }
    return total;
  }

  Map<String, int> get resourcesPerCategory {
    final Map<String, int> counts = {};
    for (final LearningResource r in _resources.values) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    return counts;
  }

  int get activeLoanCount =>
      _transactions.where((t) => !t.isReturned).length;
}

double computeFee(double ratePerDay, int days, double discountRate) {
  final double gross = ratePerDay * days;
  final double discount = gross * discountRate;
  return gross - discount;
}

String formatMoney(double amount) {
  return 'PHP ${amount.toStringAsFixed(2)}';
}

void displayRecords(String heading, List<CenterRecord> records) {
  print('\n=== $heading ===');
  if (records.isEmpty) {
    print('No records to display.');
    return;
  }
  for (int i = 0; i < records.length; i++) {
    stdout.write('${i + 1}. ');
    records[i].display();
  }
  print('Total records: ${records.length}');
}

String? _readLine(String prompt) {
  stdout.write(prompt);
  final String? line = stdin.readLineSync();
  if (line == null) {
    print('\nInput closed. Goodbye!');
    exit(0);
  }
  return line.trim();
}

String readText(String prompt) {
  while (true) {
    final String input = _readLine(prompt) ?? '';
    if (input.isNotEmpty) {
      return input;
    }
    print('Input cannot be empty. Please try again.');
  }
}

int readInt(String prompt, {required int min, required int max}) {
  while (true) {
    final String input = _readLine(prompt) ?? '';
    try {
      final int value = int.parse(input);
      if (value < min || value > max) {
        print('Please enter a number from $min to $max.');
        continue;
      }
      return value;
    } on FormatException {
      print('Invalid input. Please enter a whole number.');
    }
  }
}

double readDouble(String prompt) {
  while (true) {
    final String input = _readLine(prompt) ?? '';
    try {
      final double value = double.parse(input);
      if (value.isNaN || value.isInfinite || value < 0) {
        print('Please enter a valid amount of 0 or more.');
        continue;
      }
      return value;
    } on FormatException {
      print('Invalid input. Please enter a number (e.g., 25 or 12.50).');
    }
  }
}

const List<String> resourceCategories = [
  'Book',
  'Course',
  'Workshop',
  'Equipment',
];

void addResourceAction(LearningCenter center) {
  print('\n--- Add Learning Resource ---');
  final String title = readText('Title: ');

  print('Categories:');
  for (int i = 0; i < resourceCategories.length; i++) {
    print('  ${i + 1}. ${resourceCategories[i]}');
  }
  final int categoryChoice = readInt('Choose category: ',
      min: 1, max: resourceCategories.length);
  final String category = resourceCategories[categoryChoice - 1];

  final int copies = readInt('Number of copies (1-100): ', min: 1, max: 100);
  final double rate = readDouble('Rental rate per day (PHP): ');

  final LearningResource resource =
      center.addResource(title, category, copies, rate);
  print('\nResource added successfully!');
  resource.display();
}

void registerParticipantAction(LearningCenter center) {
  print('\n--- Register Participant ---');
  final String name = readText('Full name: ');

  print('Membership types:');
  print('  1. Regular (no discount)');
  print('  2. Premium (20% discount on fees)');
  final int choice = readInt('Choose membership: ', min: 1, max: 2);
  final Membership membership =
      choice == 1 ? Membership.regular : Membership.premium;

  final Participant participant =
      center.registerParticipant(name, membership);
  print('\nParticipant registered successfully!');
  participant.display();
}

void borrowResourceAction(LearningCenter center) {
  print('\n--- Borrow Resource ---');
  if (!center.hasParticipants || !center.hasResources) {
    print('You need at least one registered participant and one '
        'resource before borrowing.');
    return;
  }

  displayRecords('Participants', center.participantRecords);
  final Participant? participant =
      center.findParticipant(readText('Enter participant ID (e.g., P001): '));
  if (participant == null) {
    print('Participant not found. Transaction cancelled.');
    return;
  }

  displayRecords('Resources', center.resourceRecords);
  final LearningResource? resource =
      center.findResource(readText('Enter resource ID (e.g., R001): '));
  if (resource == null) {
    print('Resource not found. Transaction cancelled.');
    return;
  }

  final int days = readInt('Number of days to borrow (1-30): ', min: 1, max: 30);

  final Transaction? transaction = center.borrow(participant, resource, days);
  if (transaction == null) {
    print('Transaction could not be completed.');
    return;
  }

  final double gross = resource.ratePerDay * days;
  print('\nTransaction recorded!');
  print('Base fee   : ${formatMoney(gross)} '
      '(${formatMoney(resource.ratePerDay)} x $days day(s))');
  print('Discount   : ${(participant.discountRate * 100).toStringAsFixed(0)}%');
  print('Amount due : ${formatMoney(transaction.fee)}');
  transaction.display();
}

void returnResourceAction(LearningCenter center) {
  print('\n--- Return Resource ---');
  if (center.activeLoanCount == 0) {
    print('There are no active loans to return.');
    return;
  }

  displayRecords('All Transactions', center.transactionRecords);
  final Transaction? transaction = center
      .findActiveTransaction(readText('Enter transaction ID to return: '));
  if (transaction == null) {
    print('No active transaction with that ID was found.');
    return;
  }

  center.completeReturn(transaction);
  print('Return processed successfully.');
  transaction.display();
}

void showSummaryReport(LearningCenter center) {
  print('\n=== Center Summary Report ===');
  print('Resources     : ${center.resourceRecords.length}');
  print('Participants  : ${center.participantRecords.length}');
  print('Transactions  : ${center.transactionRecords.length} '
      '(${center.activeLoanCount} active)');
  print('Total revenue : ${formatMoney(center.totalRevenue)}');

  final Map<String, int> perCategory = center.resourcesPerCategory;
  if (perCategory.isEmpty) {
    print('Resources per category: none yet');
  } else {
    print('Resources per category:');
    perCategory.forEach((category, count) {
      print('  - $category: $count');
    });
  }
}

void printMenu() {
  print('\n----------------- MAIN MENU -----------------');
  print('1. Add learning resource');
  print('2. Register participant');
  print('3. Borrow resource');
  print('4. Return resource');
  print('5. View resources');
  print('6. View participants');
  print('7. View transactions');
  print('8. View all records');
  print('9. Summary report');
  print('0. Exit');
  print('---------------------------------------------');
}

void main() {
  final LearningCenter center = LearningCenter();
  bool running = true;

  print('=============================================');
  print('  COMMUNITY LEARNING CENTER MANAGEMENT SYSTEM');
  print('=============================================');

  while (running) {
    printMenu();
    final String choice = _readLine('Enter your choice (0-9): ') ?? '';

    try {
      switch (choice) {
        case '1':
          addResourceAction(center);
          break;
        case '2':
          registerParticipantAction(center);
          break;
        case '3':
          borrowResourceAction(center);
          break;
        case '4':
          returnResourceAction(center);
          break;
        case '5':
          displayRecords('Learning Resources', center.resourceRecords);
          break;
        case '6':
          displayRecords('Participants', center.participantRecords);
          break;
        case '7':
          displayRecords('Transactions', center.transactionRecords);
          break;
        case '8':
          displayRecords('All Records', center.allRecords);
          break;
        case '9':
          showSummaryReport(center);
          break;
        case '0':
          running = false;
          break;
        default:
          print('Invalid choice "$choice". Please enter a number from 0 to 9.');
      }
    } catch (e) {
      print('Something went wrong: $e');
      print('Returning to the main menu.');
    }
  }

  print('\nThank you for using the Community Learning Center '
      'Management System. Goodbye!');
}