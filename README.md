# Community Learning Center Management System

**Name:** Villahermosa, Jeth Sislie C.  
**Section:** BSIT-3.8  
**Course:** Mobile Development – Midterm Laboratory Examination (Weeks 7–10, CO3)

## Short Description

A Dart console application that manages a community learning center. It registers
learning resources (books, courses, workshops, equipment) and participants,
processes borrowing and return transactions with membership discounts, and
displays organized records and a summary report.

## Implemented Features

- **Menu-driven interface** with 10 options, running in a loop until the user chooses Exit.
- **Add learning resource** – title, category, number of copies, daily rental rate.
- **Register participant** – name and membership (Regular or Premium, 20% discount).
- **Borrow resource** – fee is computed as `rate × days`, minus the membership discount. A participant may hold at most 3 active loans, and resources with no copies left cannot be borrowed.
- **Return resource** – restores stock and the participant's loan allowance.
- **View** resources, participants, transactions, or all records together.
- **Summary report** – totals, active loans, revenue, and resources per category.
- **Input validation and error handling** – invalid menu choices, empty text, non-numeric values, out-of-range numbers, unknown IDs, and closed input are handled with messages; the program never crashes (`try`/`on FormatException`, outer `try`/`catch`).

### Object-Oriented Design

| Concept | Where it is used |
|---|---|
| Abstract class | `CenterRecord` (abstract `getSummary()` and `recordType`) |
| Inheritance / overriding | `LearningResource`, `Participant`, `Transaction` each extend `CenterRecord` and implement `getSummary()` |
| Polymorphism | `displayRecords()` accepts a `List<CenterRecord>` and each object prints itself |
| Mixin | `Timestamped` gives every record a creation time |
| Encapsulation | Private fields (`_title`, `_activeLoans`, …) with getters and validated setters |
| Constructors | Every class has a constructor that also generates its unique ID (R001, P001, T001) |
| List and Map | `Map<String, LearningResource>` for resources; `List<Participant>` and `List<Transaction>`; a Map counts resources per category |
| Enum | `Membership` (Regular / Premium) with its discount rate |
| User-defined functions | `computeFee()`, `formatMoney()`, `displayRecords()`, `readInt()`, `readDouble()`, `readText()`, and menu action functions |

## Sample Test Scenarios

**Scenario 1 – Normal flow (add, register, borrow)**
1. Choose `1` → Title `Dart Basics`, category `1` (Book), copies `2`, rate `20`.
2. Choose `2` → Name `Ana Cruz`, membership `2` (Premium).
3. Choose `3` → participant `P001`, resource `R001`, days `5`.
   Expected: base fee PHP 100.00, discount 20%, amount due **PHP 80.00**; available copies become 1/2.

**Scenario 2 – Return and summary**
1. Choose `4` → transaction `T001`. Expected: status changes to *Returned*; copies return to 2/2.
2. Choose `9`. Expected: 1 resource, 1 participant, 1 transaction (0 active), revenue PHP 80.00, `Book: 1`.

**Scenario 3 – Invalid input and error conditions**
- Menu choice `abc` or `15` → "Invalid choice" message; menu is shown again.
- Add resource with copies `abc` → "Invalid input. Please enter a whole number."; copies `0` → "Please enter a number from 1 to 100."
- Rate `-5` → "Please enter a valid amount of 0 or more."
- Empty title → "Input cannot be empty."
- Borrow with participant ID `P999` → "Participant not found. Transaction cancelled."
- Borrow when no copies remain, or a 4th active loan → clear refusal message.
- Choose `3` before any records exist → message explaining a participant and resource are needed (try this by emptying `demoInputs` and starting with `'3'`).

## How to Run

**DartPad (dartpad.dev)**
1. Open [dartpad.dev](https://dartpad.dev) and start a new Dart project.
2. Replace all code with the contents of `main.dart` and click **Run**.
3. DartPad cannot read the keyboard, so `main.dart` feeds the three test scenarios above through the `demoInputs` list (see "Console Input Helpers" in the code). All prompts, validation, calculations and output come from the program logic; edit `demoInputs` to try other inputs.

**Interactive keyboard input (Dart SDK)**
1. Install the [Dart SDK](https://dart.dev/get-dart).
2. Use the same program with real keyboard input: `dart run main_stdin.dart`
   (identical logic; only the input helper reads from `stdin`).

Requires Dart 2.17 or newer (uses an enhanced enum).
