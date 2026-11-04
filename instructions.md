# Session 7 · State Management

**One brain for your app**

AUCA Innovation Center · Mobile Programming · Flutter & Provider

Your mini project works: accounts, cloud data, live updates. Tonight you learn how professional apps are organised, and you rebuild your mini project that way: the data in one place, the screens only drawing it. Then you add a new feature and feel the difference.

**Tonight in one sentence.** You will move your mini project's data out of the screens into one state class that every screen watches, using the Provider package, and you will understand every line of it.

## Done when

- Your project has four folders: `models`, `repositories`, `state`, `screens`.
- Only your model and your repository import `cloud_firestore`.
- Your app works exactly as after Session 6: login, live list, add, edit, delete, privacy.
- Your add screen shows live data from the brain (step 16), and your list has a filter (step 18).
- You can explain every line of your state class in your own words.

**Deadline:** start in class, finish before Session 8 (Wednesday for Group A, Thursday for Group B). Take your time: understanding matters more than speed.

## How to read this guide

Every step has the same parts: the **Goal**, the **idea** (with an everyday example), **code to try** (Part 2, in DartPad) or **to do in your own mini project** (Part 3), **👀 You should see**, **Your turn** for your own project, and a **question to check yourself**: answer it first, then open the answer. Stuck? See *When something goes wrong* at the end.

## Before you start

Commit and push your mini project. You are about to move files around; this is your safety net:

```bash
git add -A
git commit -m "before state management"
git push
```

**Type, don't paste.** Tonight is about understanding where code lives. You must be able to explain any line you write.

The examples come from **MoMo Wallet**, the Session 6 example. In step 4 you make a table that translates every MoMo Wallet name into your own project's names.

## Tonight's ladder

**Part 1 · Understand**
1. Feel the problem
2. What is state?
3. One source of truth
4. The four layers

**Part 2 · The Dart you need**
5. Getters (DartPad)
6. Listening to a stream yourself (DartPad)
7. How ChangeNotifier works (DartPad)
8. The widget tree: who is above whom

**Part 3 · Build it in your mini project**
9. Make the folders
10. The repository
11. The state class: the brain
12. Give the brain to your screens
13. The list screen watches
14. Buttons read
15. Clean up, and prove nothing broke

**Part 4 · See it, break it, use it**
16. See one source of truth
17. Break it on purpose
18. The payoff: a filter

**Part 5 · Beyond Provider**
19. Riverpod and BLoC compared

Words to know · When something goes wrong

---

# Part 1 · Understand

No code to keep yet. You look at your own app and learn the four ideas the rest of the night is built on.

## 1. Feel the problem (EXERCISE)

**Goal:** discover, in your own code, why apps need state management, before anyone tells you.

### The exercise

MoMo Wallet's add screen (`TxnForm`) has a new requirement: at the top, show **"Your balance: 11,500 RWF"**, so the user knows how much they have before sending money. **Do not write the code.** Open your project and answer these questions on paper or in a comment:

1. Where does the balance exist right now? In which file, and inside which function?
2. Find two different ways the form could get the balance.
3. For each way: what could go wrong?

### The idea

Both ways are bad for the same reason: the data lives inside one screen. As your app grows, three problems appear:

| Problem | What it looks like in your code |
|---|---|
| Data trapped in a widget | A second screen needs the same list: you copy it (copies disagree) or load it twice (slow, and it costs reads). |
| Passing through constructors | Screen → tab → list → tile: every widget in between carries data it never uses, just to hand it down. Add one field and you edit five files. |
| UI and logic tangled | Firestore calls, sums and ifs inside `build` methods. When the balance is wrong, the bug could be anywhere, because everything is everywhere. |

None of this is a bug today. It is what makes the tenth screen of your capstone impossible to build. Tonight you learn the fix, and in step 16 you solve this exact exercise in one line.

### Your turn

Find the same problem in your mini project: which data does your main screen hold that another screen could need? (Bus booking: the seats left. Course planner: the total credits. Shop: the cart count.) **Write it down:** you will use it in step 16.

## 2. What is state? (UNDERSTAND)

**Goal:** know the three kinds of data in an app, and where each one belongs.

### The idea

**State** is every piece of data your app needs to draw the screen right now. If it changed, the screen would look different. MoMo Wallet's state: the transactions, the signed-in user, the text typed in the amount field, whether the IN or OUT button is selected, whether "Saving..." is showing.

Not all state is the same. Ask one question: **how many screens care about it?**

| | Ephemeral state | App state | Computed state |
|---|---|---|---|
| Who cares? | One widget only | Several screens | Anyone who reads it |
| MoMo Wallet | Text typed in the amount field, IN/OUT before saving, `_saving` | The transactions, the signed-in user | The balance |
| Where it lives | Inside the widget, changed with `setState` | In one state class that screens watch | Nowhere: worked out from app state every time it is read |
| Tonight | Stays exactly as it is | Moves out of the screens | Moves with the app state |

**`setState` is not the enemy.** `setState` is perfect for ephemeral state: it is local by design. The problem is app state pretending to be local, like the transactions living inside `WalletScreen`. Tonight you keep `setState` in your forms and login screen; you only move the app state.

**Computed state is Habit 2.** In Session 6 you learned: save facts, compute the rest. The balance is computed from the transactions. Tonight it gets a proper home: inside the state class, computed every time someone asks.

### Your turn

List six pieces of state in your mini project and sort them into the three columns. Include at least one of each kind.

### Check your understanding

Which tab is selected in a bottom navigation bar: ephemeral or app state? What if a badge on the tab must show the number of unread messages?

## 3. One source of truth (UNDERSTAND)

**Goal:** understand the one rule that every state management tool follows.

### The idea: the class WhatsApp group

Imagine the timetable changes. If every student keeps a printed copy, half the class will come to the wrong room: some copies are old. So the class rep posts the timetable in the class WhatsApp group. Nobody keeps a copy; when it changes, the rep posts once, and everyone in the group gets the update at the same moment.

That is the rule:

> **One source of truth.** Each piece of app state lives in exactly one place. Screens never keep their own copy: they *watch* it, and when it changes, every watching screen redraws.

| WhatsApp group | Session 6 (Firestore) | Tonight (your state class) |
|---|---|---|
| The timetable, in the group | The documents, in Firestore | The transactions, in the state class |
| Joining the group | `StreamBuilder` on `snapshots()` | `context.watch<WalletState>()` |
| The rep posts a change | A new delivery arrives | `notifyListeners()` |
| Everyone's phone buzzes | The `StreamBuilder` rebuilds | Every watching screen rebuilds |

A printed copy is a screen keeping its own list: the thing we stop doing tonight. And you already know the pattern: Session 6's stream did this for Firestore; tonight you give your own class the same power.

### Check your understanding

After tonight, `WalletScreen` and `TxnForm` both watch the state class. You delete a transaction in the Firebase console. How many times does Firestore send data to the app? How many screens redraw?

## 4. The four layers (UNDERSTAND)

**Goal:** know the four layers of a professional app, the one job of each, and which of your files goes where.

### The idea: a restaurant

In a good restaurant, the waiter takes your order and brings your food, but never cooks. The kitchen does the work: it cooks and decides. Only the buyer goes to the market for ingredients. And the recipe card says what each dish is. If the restaurant changes market, from Kimironko to Nyabugogo, only the buyer's route changes: the waiter and the kitchen do not even notice.

| Layer | Restaurant | Its one job | Must never | MoMo Wallet |
|---|---|---|---|---|
| **Models** | Recipe card | Say what things are: fields, `toMap`, `fromDoc` | Read or write data | `Txn` |
| **Repository** | Buyer | Talk to the backend: watch, add, update, delete. The only layer that knows which backend you use. | Know about screens or widgets | `TxnRepository` |
| **State** | Kitchen | The brain: hold the data, compute values, announce every change | Use `BuildContext`, widgets, `Navigator`, or the backend package | `WalletState` |
| **Screens** | Waiter | Just draw: watch the state, show it, call its methods when tapped | Import `cloud_firestore`, compute app values, own app data | `WalletScreen`, `TxnForm` |

```
calls go this way: add · edit · remove →

  SCREENS        just draw
     ↓
  STATE          the brain
     ↓
  REPOSITORY     talks to the backend
     ↓
  BACKEND        Firestore, Supabase, or your own server

← data comes back this way: stream → notifyListeners() → screens redraw
```

Each layer only talks to its neighbours. Screens never talk to the backend.

**Why this matters for your capstone.** Because only the repository knows the backend, you can choose any backend for your capstone. With Supabase or your own REST API (the `http` package from Session 5), you write a different repository with the same kind of methods. The state class and every screen stay almost the same. And every bug has one home: a wrong balance can only be in state, a failing query only in repositories, an ugly button only in screens.

### Your turn: your translation table

Copy this table into a comment at the top of your `main.dart` and fill in the last column. From now on, when the guide says a MoMo Wallet name, you use yours.

| MoMo Wallet | What it is | Example: bus booking | Yours |
|---|---|---|---|
| `Txn`, `txn.dart` | Your model | `Booking`, `booking.dart` | ? |
| `transactions` collection | Your Firestore collection | `bookings` | ? |
| `TxnRepository` | Your repository | `BookingRepository` | ? |
| `WalletState` | Your state class, named after your app | `BookingState` | ? |
| `balance` | Your computed value (Habit 2) | `upcomingCount`, `totalSpent` | ? |
| `WalletScreen`, `TxnForm` | Your list screen and your form | `BookingsScreen`, `BookingForm` | ? |

---

# Part 2 · The Dart you need

Four new tools appear in tonight's code. You try each one alone, in **DartPad** (dartpad.dev, in your browser), so that when you meet it in your project you already know it.

## 5. Getters (DARTPAD)

**Goal:** write a value that is computed every time it is read, and data that others can read but not replace.

### The idea

A **getter** looks like a variable from outside, but it is code that runs every time someone reads it. You write it with the word `get` and no brackets:

```dart
int get balance => /* code that works out the balance */;
```

Tonight you use getters for two things:

- **Computed values.** `balance` is never stored: each time a screen reads `wallet.balance`, it is worked out again from the transactions. It can never be out of date. Habit 2.
- **Read-only data.** A name that starts with `_` is private: other files cannot touch it. A getter lets them *read* it without being able to *replace* it. So only the state class can change its own data.

### Try it

Open dartpad.dev, delete what is there, type this and press Run:

```dart
class Wallet {
  final List<int> _amounts = [10000, -2500, 4000];

  // Read-only from outside: you can read it, but not replace it.
  List<int> get amounts => _amounts;

  // Computed fresh every time someone reads it.
  int get balance => _amounts.fold<int>(0, (total, a) => total + a);

  void add(int amount) => _amounts.add(amount);
}

void main() {
  final wallet = Wallet();
  print(wallet.balance); // no () : it reads like a variable
  wallet.add(-1500);
  print(wallet.balance); // nobody updated "balance": it was computed again
}
```

**👀 You should see:**

```
11500
10000
```

### What just happened

`fold` walks through the list and carries a running total. It starts with 0, then for each amount does `total + a`: 0 → 10000 → 7500 → 11500.

After `add(-1500)`, nobody wrote a new balance anywhere. The second `print` read the getter again, the getter ran `fold` again, and the answer was right. That is why a computed value can never disagree with its data.

### Your turn

1. Add `int get count => _amounts.length;` and print it.
2. Add a getter `moneyIn` that adds up only the positive amounts. (Hint: `_amounts.where((a) => a > 0)` first, then `fold`.)
3. In `main`, try `wallet.amounts = [];` and press Run. Read the error.

## 6. Listening to a stream yourself (DARTPAD)

**Goal:** receive a stream's deliveries in your own code, change them on the way, and stop them when you are done.

### The idea

In Session 6, `StreamBuilder` listened to Firestore for you, and stopped when its screen closed. Tonight the state class listens itself, so you need three new words:

| Word | Meaning | Everyday picture |
|---|---|---|
| `stream.listen(...)` | Start receiving. The function you give runs at every delivery. | Subscribing to a newspaper |
| `StreamSubscription` | What `listen` gives back: your subscription | Your subscription card |
| `subscription.cancel()` | Stop receiving | Cancelling the subscription |
| `stream.map(...)` | Change every delivery on its way through the pipe | A translator who rewrites each newspaper before it reaches you |

### Try it

```dart
import 'dart:async';

Future<void> main() async {
  // A stream that delivers 1, 2, 3, ... one per second.
  final ticks = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);

  // map: change every delivery on its way through the pipe.
  final amounts = ticks.map((n) => n * 1000);

  // listen: start receiving. You get back a subscription.
  final StreamSubscription<int> subscription =
      amounts.listen((a) => print('Received $a RWF'));

  await Future.delayed(const Duration(milliseconds: 3500));
  await subscription.cancel(); // deliveries stop
  print('Cancelled: no more deliveries');
}
```

**👀 You should see:**

```
Received 1000 RWF
Received 2000 RWF
Received 3000 RWF
Cancelled: no more deliveries
```

### Why this matters tonight

Your repository will use `map` to turn Firestore's raw snapshots into a `List<Txn>` at every delivery. Your state class will `listen` to that, and `cancel` when the user logs out. Without `cancel`, the app keeps listening to the old user's data after logout: wasted reads, and a *permission denied* error, because the security rules no longer let anyone in.

### Your turn

1. Change the `map` so it delivers text like `'Transaction number 1'` (the subscription type becomes `StreamSubscription<String>`).
2. Delete the `cancel()` line and run. What happens? (Press Stop when you have seen enough.)

## 7. How ChangeNotifier works (DARTPAD)

**Goal:** build a tiny version of `ChangeNotifier` yourself, so that `notifyListeners()` is never magic again.

### Try it: a notice board

This class keeps a list of listeners: functions to call when something changes. `void Function()` means "a function that takes nothing and returns nothing".

```dart
class NoticeBoard {
  final List<void Function()> _listeners = [];
  String _message = 'No announcements yet';

  String get message => _message;

  // Someone asks: "tell me when something changes".
  void addListener(void Function() listener) => _listeners.add(listener);

  void post(String newMessage) {
    _message = newMessage;
    // Tell everyone who asked. This loop is notifyListeners().
    for (final listener in _listeners) {
      listener();
    }
  }
}

void main() {
  final board = NoticeBoard();
  board.addListener(() => print('Aline sees: ${board.message}'));
  board.addListener(() => print('Keza sees: ${board.message}'));

  board.post('Class moved to room 204');
  board.post('Bring your Figma on Wednesday');
}
```

**👀 You should see:**

```
Aline sees: Class moved to room 204
Keza sees: Class moved to room 204
Aline sees: Bring your Figma on Wednesday
Keza sees: Bring your Figma on Wednesday
```

### The idea

You just wrote a `ChangeNotifier`. Flutter's real one does exactly this, so you never write the list or the loop yourself:

| Your `NoticeBoard` | Flutter's `ChangeNotifier` |
|---|---|
| `_listeners` and `addListener` | Built in. Provider calls `addListener` for every widget that watches. |
| The loop in `post` | `notifyListeners()` |
| Each listener prints | Each listener means "rebuild this widget" |
| `class NoticeBoard` | `class WalletState extends ChangeNotifier` |

So the rule of every state class is simple: **change your data, then call `notifyListeners()`.** Change without notifying, and nobody finds out.

### Your turn

1. Add a third listener for Eric.
2. Add a method `void clear() { _message = ''; }` that forgets the loop. Call `board.clear();` then `print(board.message);`. Do the listeners hear about it? Is the message cleared?

## 8. The widget tree: who is above whom (UNDERSTAND)

**Goal:** understand where Provider puts the brain, and why a screen sometimes cannot find it.

### The idea

Every widget sits inside a parent, so your app is a **tree**. The `context` you get in `build(BuildContext context)` is that widget's place in the tree. When a widget calls `context.watch<WalletState>()`, Provider walks **up** the tree from that place, looking for a `ChangeNotifierProvider<WalletState>`. Above: found. Not above: error.

In step 12 you put the provider in your gate, right above `WalletScreen`. Here is MoMo Wallet's tree after that:

```
MaterialApp
└─ Navigator                      (holds the screens, like a stack of cards)
   ├─ AuthGate
   │  └─ ChangeNotifierProvider<WalletState>     ← the brain lives here
   │     └─ WalletScreen          ✓ the brain is above it
   │        └─ Card, ListView, ListTile…   ✓ above them too
   └─ TxnForm                     ✗ pushed: NOT under the provider
```

**The surprise:** a screen you open with `Navigator.push` is *not* inside the screen that opened it. The Navigator puts it *beside*, like a new card on the stack. So `TxnForm` cannot find the brain, and you get `Could not find the correct Provider<WalletState> above this TxnForm Widget`.

### The fix: hand over the same brain

When you push the form, wrap it in `ChangeNotifierProvider.value`. `.value` means: do not create a new brain; share this one. You write the full code in step 14:

```dart
ChangeNotifierProvider<WalletState>.value(
  value: wallet,          // the brain we already have
  child: TxnForm(txn: txn),
)
```

```
   └─ ChangeNotifierProvider<WalletState>.value   ← same brain, handed over
      └─ TxnForm                  ✓ now it can watch and read
```

### Check your understanding

Why not wrap `TxnForm` in `ChangeNotifierProvider(create: (_) => WalletState(...))` instead?

---

# Part 3 · Build it in your mini project

Now the real work, in your own app. Each step leaves the app running. After each one, run it: if it no longer works, fix it before you continue.

## 9. Make the folders (BUILD)

**Goal:** give every file its layer, and add the Provider package.

### Do it

**1. Add Provider.** In your project's terminal:

```bash
flutter pub add provider
```

**2. Create four folders** inside `lib/`: right-click `lib` → New → Directory (Android Studio) or New Folder (VS Code).

**3. Move your files.** Use the editor to move them, so it fixes the imports for you: in Android Studio right-click the file → Refactor → Move; in VS Code drag it into the folder and accept *Update imports*. MoMo Wallet ends up like this:

```
lib/
├── main.dart                 stays here
├── models/
│   └── txn.dart
├── repositories/             empty for now: step 10
├── state/                    empty for now: step 11
└── screens/
    ├── auth_gate.dart
    ├── login_screen.dart
    ├── wallet_screen.dart
    └── txn_form.dart
```

**👀 You should see:** Run the app. It works exactly as before. Nothing changed except where the files live.

### Your turn

Every Dart file in your project now belongs to one folder. A file that is not a screen, not a model, and has no backend code (a helper, a list of colors)? Make a `widgets/` or `utils/` folder for it: that is fine.

## 10. The repository (BUILD)

**Goal:** put every Firestore operation of your app into one class: the only place that talks to the backend.

### The idea

Look at your Session 6 code: `myTransactions()` in `txn.dart`, `.add` and `.update` in the form, `.delete` in the wallet screen, the stream in the wallet screen, the sample data in `txn.dart`. Firestore code in four files. The repository gathers all of it in one place.

### Do it

Create `lib/repositories/txn_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/txn.dart';

class TxnRepository {
  TxnRepository(this.uid);

  final String uid;

  // users/{uid}/transactions: the path your security rules protect.
  CollectionReference<Map<String, dynamic>> get _transactions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions');

  // The pipe: the list now, and again after every change.
  Stream<List<Txn>> watchAll() => _transactions
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Txn.fromDoc).toList());

  Future<void> add(Txn txn) => _transactions.add({
        ...txn.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> update(String id, Txn txn) =>
      _transactions.doc(id).update(txn.toMap());

  Future<void> delete(String id) => _transactions.doc(id).delete();

  // Sample data for a brand new account.
  Future<void> addSamples() async {
    final samples = [
      Txn(description: 'Opening balance', amount: 10000, isIn: true),
      Txn(description: 'Sent to 0788123456', amount: 2500, isIn: false),
      Txn(description: 'Received from Keza', amount: 4000, isIn: true),
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (final t in samples) {
      batch.set(_transactions.doc(), {
        ...t.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
```

### Line by line

| Code | What it does | Where it was in Session 6 |
|---|---|---|
| `TxnRepository(this.uid)` | One repository belongs to one user. It is given the uid once, when it is created. | `myTransactions()` asked `FirebaseAuth` every time |
| `get _transactions` | A private getter (step 5) for the user's collection. Private: no other file needs the path. | `myTransactions()` in `txn.dart` |
| `watchAll()` | The live pipe. `.map` (step 6) turns every raw snapshot into a ready `List<Txn>`, so nobody else ever sees Firestore's types. | The `stream:` of the `StreamBuilder`, and `docs.map(Txn.fromDoc)` in its builder |
| `add` | Saves a new transaction and stamps the server time. The form no longer needs to know about `FieldValue`. | `txn_form.dart` |
| `update`, `delete` | Change or remove one document by its id. | `txn_form.dart`, `wallet_screen.dart` |
| `addSamples` | The sample data for a new account. | `addSampleTransactions()` in `txn.dart` |

**👀 You should see:** Run the app: it works exactly as before. Nothing calls the repository yet. Keep `myTransactions()` and `addSampleTransactions()` in `txn.dart` for now: your screens still use them. You delete them in step 15, once nothing calls them.

### Your turn

Write your repository: your collection name, your model, your sample data. Search your project for `FirebaseFirestore` and `myTransactions` (or whatever you named it): every operation you find needs a method here. If your app has two collections (bookings and buses, say), write two repositories.

### With another backend

A capstone on Supabase or your own REST API has the same repository with different insides. With a REST API and `http` (Session 5), `watchAll` usually becomes `Future<List<Txn>> fetchAll()`, and the state class calls it again after every add or delete. Supabase's Flutter package can also give you a live stream. The layers do not change.

### Check your understanding

Why does the repository receive the `uid` in its constructor, instead of asking `FirebaseAuth` inside each method?

## 11. The state class: the brain (BUILD)

**Goal:** write the class that holds the transactions, computes the balance, and tells every screen when something changes.

### Do it

Create `lib/state/wallet_state.dart`. Everything in it comes from Part 2: a `listen` (step 6), private data with getters (step 5), and `notifyListeners()` (step 7).

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/txn.dart';
import '../repositories/txn_repository.dart';

class WalletState extends ChangeNotifier {
  WalletState(this._repo) {
    // Born: open the pipe to the backend, once.
    _subscription = _repo.watchAll().listen(
      (list) {
        _transactions = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your transactions.';
        notifyListeners();
      },
    );
  }

  final TxnRepository _repo;
  StreamSubscription<List<Txn>>? _subscription;

  // The data: private, so only the brain can change it.
  List<Txn> _transactions = [];
  bool _loading = true;
  String? _error;

  // Read-only views for the screens.
  List<Txn> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;

  // Habit 2: never saved, computed every time it is read.
  int get balance => _transactions.fold<int>(
      0, (total, t) => t.isIn ? total + t.amount : total - t.amount);

  // Actions: the brain hands the job to the repository.
  Future<void> add(Txn txn) => _repo.add(txn);
  Future<void> edit(String id, Txn txn) => _repo.update(id, txn);
  Future<void> remove(Txn txn) => _repo.delete(txn.id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### Read it like a story

1. **Born.** The constructor opens the pipe: it listens to `watchAll()`. From now on, every change in Firestore arrives here.
2. **A delivery arrives.** It stores the new list, switches `_loading` off, clears any error, and calls `notifyListeners()`: every watching screen rebuilds.
3. **Something goes wrong** (no internet, permission denied): `onError` stores a message and also notifies, so the screen can show it.
4. **A screen asks for the balance.** The getter computes it fresh from the list.
5. **A screen asks to add, edit or delete.** The brain hands the job to the repository. It does *not* touch `_transactions`: the change goes to Firestore, and the answer comes back through the pipe, like every other change.
6. **Dies** (the user logs out). `dispose()` cancels the subscription: the pipe is closed.

### Check your understanding

1. Why are `_transactions`, `_loading` and `_error` private, with getters?
2. Why doesn't `add()` do `_transactions.add(txn)` and `notifyListeners()` itself? It would feel faster…
3. Why does `_loading` start as `true`?

**👀 You should see:** Run the app: still exactly as before. The brain exists as code, but nobody creates it yet.

### Your turn

Write your state class with your names. Your computed value replaces `balance`: copy the calculation that is in your list screen today (look for `fold`, a loop, or `.length` in its `build`). Add one action method per repository method.

## 12. Give the brain to your screens (BUILD)

**Goal:** create the brain at the right moment (when a user logs in) and put it above the wallet screen in the tree.

### The idea

Your gate from Session 6 already decides: no user, login screen; a user, wallet screen. That is exactly when the brain should live. The brain belongs to one user, so it is **born when a user logs in and dies when they log out**. `ChangeNotifierProvider` does both for you: it calls `create` when it first appears, and it calls the brain's `dispose()` when it leaves the tree.

### Do it

In `lib/screens/auth_gate.dart`, add three imports, and change the end of the builder (the waiting check above it stays):

```dart
import 'package:provider/provider.dart';

import '../repositories/txn_repository.dart';
import '../state/wallet_state.dart';

// ... at the end of the StreamBuilder's builder:
final user = snapshot.data;
if (user == null) {
  return const LoginScreen();
}
// Signed in: one brain for this user, given to the wallet screen.
return ChangeNotifierProvider<WalletState>(
  create: (_) => WalletState(TxnRepository(user.uid)),
  child: const WalletScreen(),
);
```

| Code | Meaning |
|---|---|
| `ChangeNotifierProvider<WalletState>` | "I hold a `WalletState` for everything below me." |
| `create: (_) => WalletState(TxnRepository(user.uid))` | How to make the brain: a repository for this user, inside a new brain. Provider calls it the first time a screen asks. |
| `child: const WalletScreen()` | The screen that sits below, and can watch. |

**👀 You should see:** Run the app: still exactly as before. The brain is ready, but `WalletScreen` does not ask for it yet, so Provider has not created it. Next step.

### What about the login screen?

Your login screen and gate still call `FirebaseAuth` directly. That is fine tonight: login is not app data. In a bigger app, sign-in also moves into a repository (an `AuthRepository`). Your capstone can go that far.

## 13. The list screen watches (BUILD)

**Goal:** replace the `StreamBuilder` in your list screen with one line that watches the brain.

### The idea

`context.watch<WalletState>()` does two things: it finds the brain above (step 8), and it subscribes this widget (step 7): every `notifyListeners()` rebuilds it. So the screen no longer needs a `StreamBuilder`: the brain *is* the stream now.

### Do it

**1.** In `wallet_screen.dart`, add the imports and watch the brain at the top of `build`:

```dart
import 'package:provider/provider.dart';

import '../models/txn.dart';
import '../state/wallet_state.dart';

// inside build, first lines:
final user = FirebaseAuth.instance.currentUser!;
final wallet = context.watch<WalletState>();
```

**2.** Replace the whole `body: StreamBuilder(...)` with `body: _body(context, wallet, user)`, and write `_body` as a method of the class. The four states from Session 6 become four simple checks. Everything that drew the balance card and the list stays the same: only where `txns` and `balance` come from changes:

```dart
Widget _body(BuildContext context, WalletState wallet, User user) {
  if (wallet.error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(wallet.error!, textAlign: TextAlign.center),
      ),
    );
  }
  if (wallet.loading) {
    return const Center(child: CircularProgressIndicator());
  }
  final txns = wallet.transactions; // was: snapshot.data!.docs.map(...)
  final balance = wallet.balance;   // was: txns.fold(...) right here
  return Column(
    children: [
      // ... the balance Card, exactly as before ...
      // ... Expanded with the empty message or the ListView, exactly as before ...
    ],
  );
}
```

**👀 You should see:** Hot restart. The list and the balance appear as before. Add a document in the Firebase console: it appears live, with no restart. The data now travels Firestore → repository → brain → `watch` → screen.

### Your turn

Do the same in your list screen. The test: does its `build` still contain `StreamBuilder`, `snapshot`, `fold` or `Txn.fromDoc`? If yes, that work belongs to the brain or the repository.

## 14. Buttons read (BUILD)

**Goal:** make every button call the brain instead of Firestore, and hand the brain to the form.

### The idea: watch or read?

| | `context.watch<T>()` | `context.read<T>()` |
|---|---|---|
| Means | "Give me the brain, **and rebuild me** every time it changes" | "Give me the brain **once**" |
| Rebuilds? | Yes, at every `notifyListeners()` | Never |
| Use it in | `build`, for data you show | Button code: `onPressed`, `onTap`, a save method |
| WhatsApp | Joining the group | Asking the rep once |

A button does not need to rebuild when data changes: it needs the brain once, to call a method. That is `read`.

**Read before you await.** When a method has an `await` (a dialog, a save), the screen might be closed by the time the `await` finishes, and its `context` is then no longer in the tree. So: read the brain at the start, before the first `await`, and keep it in a variable. You saw `mounted` in Session 6 for the same reason: after an `await`, check the screen is still there before using `context` again.

### Do it: four changes

**1. Delete** (in `wallet_screen.dart`): read first, then await the dialog, then ask the brain:

```dart
Future<void> _delete(BuildContext context, Txn txn) async {
  final wallet = context.read<WalletState>(); // read BEFORE the await
  final sure = await showDialog<bool>(
    // ... the same dialog as before ...
  );
  if (sure == true) {
    await wallet.remove(txn);
  }
}
```

**2. Open the form** (in `wallet_screen.dart`): one method that hands over the same brain (step 8). Use it in the list's `onTap` and in the + button:

```dart
// Open the form and hand it the SAME brain.
void _openForm(BuildContext context, Txn? txn) {
  final wallet = context.read<WalletState>();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<WalletState>.value(
        value: wallet,
        child: TxnForm(txn: txn),
      ),
    ),
  );
}

// in the ListTile:
onTap: () => _openForm(context, t),

// the + button:
floatingActionButton: FloatingActionButton(
  onPressed: () => _openForm(context, null),
  child: const Icon(Icons.add),
),
```

**3. Save** (in `txn_form.dart`): replace the two Firestore calls. Imports: remove `cloud_firestore`, add `provider` and `'../state/wallet_state.dart'`.

```dart
// first line after the validate() check, BEFORE any await:
final wallet = context.read<WalletState>();

// inside the try, the two Firestore calls become:
if (widget.txn == null) {
  await wallet.add(txn);                   // was: myTransactions().add({...})
} else {
  await wallet.edit(widget.txn!.id, txn);  // was: myTransactions().doc(...).update(...)
}
```

The form keeps its controllers, `_isIn` and `_saving` with `setState`: that is ephemeral state (step 2), exactly where it belongs.

**4. Sample data** (in `login_screen.dart`): replace `import 'txn.dart';` with `import '../repositories/txn_repository.dart';` and change one line:

```dart
await TxnRepository(auth.currentUser!.uid).addSamples(); // was: addSampleTransactions()
```

This is the one place a screen talks to a repository directly, and there is a reason: at that moment the brain does not exist yet. It is born a moment later, when the gate sees the new user.

**👀 You should see:** Add, edit and delete all work as before. Create a new account: it gets its sample data.

### Your turn

Search your screens for `.add(`, `.update(`, `.delete(` and `.set(` on Firestore. Each one becomes a call on your brain, read at the start of the method. Every `Navigator.push` to a screen that needs the brain gets the `.value` wrapper.

## 15. Clean up, and prove nothing broke (BUILD)

**Goal:** remove the old Firestore code, check every layer follows its rules, and prove the app behaves exactly as in Session 6.

### Do it: the hunt

1. Search the whole project (Cmd/Ctrl + Shift + F) for `myTransactions` and `addSampleTransactions`. If nothing uses them any more, delete both functions from `txn.dart`, and delete the `firebase_auth` import there.
2. Search for `cloud_firestore`. It may appear in **exactly two files**: your model (for `DocumentSnapshot` and `Timestamp`) and your repository. Anywhere else: that Firestore code still needs to move.
3. Open each screen and check its `build`: no `StreamBuilder` on your data, no `fold`, no Firestore. Only drawing, `watch`, and method calls.

**👀 You should see:** The search for `cloud_firestore` finds 2 files. The app runs.

### Prove nothing broke: the Session 6 checklist

- [ ] Log out and log back in: your data appears.
- [ ] Add something: it appears in the list, and your computed value updates by itself.
- [ ] Add a document by hand in the Firebase console: it appears in the app, live.
- [ ] Edit and delete still work, and the computed value follows.
- [ ] Turn on Airplane mode and restart the app: you see your error or your saved data, not a crash.
- [ ] Log in with your second account: it sees only its own data.

All six pass? Commit:

```bash
git add -A
git commit -m "state management with provider"
git push
```

---

# Part 4 · See it, break it, use it

The structure is done. Now you prove to yourself that it works the way the theory said: you watch it, you break it, and you use it for a new feature.

## 16. See one source of truth (EXERCISE)

**Goal:** solve the step 1 exercise in one line, and watch two screens update from one change.

### Do it

In `txn_form.dart`, at the top of `build`, watch the balance; then show it as the first item of the form's `ListView`:

```dart
@override
Widget build(BuildContext context) {
  final balance = context.watch<WalletState>().balance;
  return Scaffold(
    // ... appBar as before ...
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your balance: $balance RWF',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // ... the IN/OUT buttons and fields, as before ...
```

### The experiment

1. Open the app and tap + to open the form. Note the balance.
2. On your computer, in the Firebase console, add a transaction document for your user (`amount` 1000, `isIn` true, `description` "Test", `createdAt` a timestamp).
3. Look at the phone, with the form still open.

**👀 You should see:** The balance on the form changes by itself, while you are on the form. Go back: the wallet screen shows the same new balance and the new transaction. One change, one delivery, two screens updated.

Compare with your step 1 answers: way 1 (passing it in) would show the old number; way 2 (a second `StreamBuilder`) would need a second listener and a second copy of the sum. Now: one line, nothing copied.

### Your turn

Take the data you wrote down in step 1 (seats left, total credits, cart count…) and show it on a second screen of your app with one `watch`. Change it from the console and watch both screens.

## 17. Break it on purpose (EXPERIMENT)

**Goal:** see with your own eyes what each piece does, by removing it. Professionals learn their tools this way.

For each experiment: **predict first** (write down what you think will happen), then do it, observe, read the explanation, and **undo** before the next one.

### Experiment A · Forget to notify

- **Do:** In `wallet_state.dart`, comment out the `notifyListeners();` in the first function of `listen` (the one that receives the list). Hot restart.
- **Observe:** The spinner turns forever. Now press hot reload: the list suddenly appears!
- **Explain:** The data arrived in the brain, but nobody was told (the notice board without the loop, step 7). Hot reload forces every widget to rebuild, so the screen finally read the data that was there all along.
- **Undo:** Uncomment the line.

### Experiment B · Read instead of watch

- **Do:** In `WalletScreen.build`, change `context.watch<WalletState>()` to `context.read<WalletState>()`. Hot restart.
- **Observe:** Same symptom: spinner forever, until a hot reload.
- **Explain:** This time the brain did notify, but the screen never joined the group: `read` does not subscribe. Same symptom, different cause: that is why the troubleshooting table lists both.
- **Undo:** Change it back to `watch`.

### Experiment C · Watch the brain be born and die

- **Do:** Add one line at the start of the constructor body: `debugPrint('Brain born for ${_repo.uid}');` and one at the start of `dispose()`: `debugPrint('Brain disposed: pipe closed');`. Hot restart, then log out, then log in with your second account. Watch the Run (or Debug Console) panel.
- **Observe:** `Brain born for` your uid → `Brain disposed` when you log out → `Brain born for` the second uid.
- **Explain:** The gate shows the provider only while someone is logged in, so each user gets a fresh brain and a fresh repository, and the old pipe is closed by `cancel()`. Without `cancel()`, the old listener would keep running after logout and hit *permission denied*.
- **Undo:** You can keep the two prints: they are harmless and useful.

### Experiment D · Forget to hand over the brain

- **Do:** In `_openForm`, replace the whole `ChangeNotifierProvider<WalletState>.value(...)` with just `TxnForm(txn: txn)`. Tap +.
- **Observe:** A red screen: `Could not find the correct Provider<WalletState> above this TxnForm Widget`.
- **Explain:** The pushed form is not under the provider (step 8): looking up the tree, it never meets the brain.
- **Undo:** Put the wrapper back.

## 18. The payoff: a filter (EXERCISE)

**Goal:** add a feature that would have touched several screens before tonight, with one variable, one method and one getter.

### The idea

MoMo Wallet gets three chips: **ALL · IN · OUT**. Where does the chosen filter live? Several screens could use it, and the visible list is computed from the transactions and the choice. So the choice goes in the brain, and the filtered list is a **getter**: never stored, never copied.

### Do it

**1.** In the brain (`wallet_state.dart`), add:

```dart
String _filter = 'all'; // 'all', 'in' or 'out'
String get filter => _filter;

void setFilter(String value) {
  _filter = value;
  notifyListeners();
}

List<Txn> get visible {
  if (_filter == 'in') return _transactions.where((t) => t.isIn).toList();
  if (_filter == 'out') return _transactions.where((t) => !t.isIn).toList();
  return _transactions;
}
```

The same pattern as everything tonight: private data, a getter to read it, a method that changes it and notifies, and a computed getter.

**2.** On the list screen, show the chips between the balance card and the list. Each chip *watches* (it is in `build`) and *reads* when tapped (it is button code):

```dart
Wrap(
  spacing: 8,
  children: ['all', 'in', 'out'].map((f) => ChoiceChip(
        label: Text(f.toUpperCase()),
        selected: wallet.filter == f,
        onSelected: (_) => context.read<WalletState>().setFilter(f),
      )).toList(),
),
```

**3.** Use the filtered list, and tell the two kinds of "empty" apart:

```dart
final txns = wallet.visible;      // was: wallet.transactions
final balance = wallet.balance;   // the balance stays on ALL transactions

// in the Expanded:
child: wallet.transactions.isEmpty
    ? const Center(child: Text('No transactions yet. Tap + to add one.'))
    : txns.isEmpty
        ? const Center(child: Text('Nothing matches this filter.'))
        : ListView.builder(
            // ... as before ...
```

**👀 You should see:** Tap IN: only money in stays. Tap ALL: everything is back. Add a transaction while IN is selected: it appears only if it is money in. The balance never changes when you filter: your money did not change, only your view of it.

### Check your understanding

Why is `visible` a getter, and not a second list `_filteredTransactions` that you update in `setFilter`?

### Your turn

Add the filter that makes sense for your data: courses by semester, bookings upcoming · past, tasks to do · done, products by category. Same three pieces: a private variable with a getter, a method that changes it and notifies, and a computed `visible` getter.

### Go further: search

Add a search box above the list that keeps only items whose description contains the typed text. You need a `_query` variable, a `setQuery` method, one more `where` in `visible`, and a `TextField` whose `onChanged` reads the brain.

Commit: `git add -A && git commit -m "filter" && git push`.

---

# Part 5 · Beyond Provider

Reading, no code. Your capstone may use Provider, Riverpod or BLoC: here is how they compare.

## 19. Riverpod and BLoC compared (READ)

**Goal:** recognise the other two tools, and choose one for your capstone with a reason.

### The idea

All three follow tonight's rule: state in one watched place, screens that redraw, actions that go through the brain. The four layers are the same; only the "brain" and the wiring change. Once you understand Provider, the others are new words for the same ideas:

| Tonight's idea | Provider | Riverpod | BLoC |
|---|---|---|---|
| The brain | A class that `extends ChangeNotifier` | A class that `extends Notifier`, declared as a provider | A `Cubit` (simple) or a `Bloc` |
| Announce a change | `notifyListeners()` | Give it a new value: `state = ...` | `emit(newState)` |
| A screen watches | `context.watch` | `ref.watch` in a `ConsumerWidget` | `BlocBuilder` |
| A button acts | `context.read<T>().method()` | `ref.read(...notifier).method()` | Cubit: `context.read<T>().method()`. Bloc: send an event: `bloc.add(Event())` |
| Put it in the tree | `ChangeNotifierProvider` | Wrap the app in `ProviderScope` once | `BlocProvider` |

| | Provider | Riverpod | BLoC |
|---|---|---|---|
| Strength | Smallest and simplest; very close to Flutter itself | Safer: many mistakes are caught before the app runs; no `BuildContext` needed to reach the state | Very predictable: every change is an event and a new state, easy to test and trace |
| Cost | Some mistakes only show when the app runs (like Experiment D) | More new concepts to learn at once | The most code to write for each feature |
| Who uses it | Many apps; a common first choice | Many modern apps | Large teams, banks, companies that want strict rules |
| Learn it | pub.dev/packages/provider | riverpod.dev | bloclibrary.dev |

### Choosing for your capstone

**Provider** if you want to spend your time on features: you already know it. **Riverpod** if you are comfortable after tonight and want the more modern tool: plan an evening with its docs first. **BLoC** only if you already like it: its extra code costs time your capstone may not have. Whatever you choose, **keep the four layers.**

---

# Words to know

| Word | Meaning |
|---|---|
| **State** | Every piece of data the app needs to draw the screen right now. |
| **App state** | State several screens care about. Lives in one state class. |
| **Repository** | The class that talks to the backend. The only layer that knows which backend you use. |
| **State class / brain** | The class that holds app state, computes values and announces changes. |
| **ChangeNotifier** | Flutter's class with a built-in list of listeners and `notifyListeners()`. |
| **watch / read** | Get the brain and subscribe to its changes / get the brain once. |
| **Getter** | A member written with `get`: looks like a variable, runs code every time it is read. |
| **Widget tree** | Every widget inside its parent. `context` is a widget's place in it. |

# When something goes wrong

| You see | It means | Fix |
|---|---|---|
| `Could not find the correct Provider<WalletState> above this … Widget` | That widget is not under the provider | For `WalletScreen`: do step 12. For a pushed screen: wrap it in `ChangeNotifierProvider.value` (steps 8 and 14). |
| Spinner forever, data appears after hot reload | Nobody told the screen | The brain must call `notifyListeners()` after changing data, and the screen must use `watch` in `build` (Experiments A and B). |
| Spinner forever, even after hot reload | No delivery ever arrived | Check `watchAll()`: the right collection name, and every document has `createdAt` (the `orderBy` skips documents without it). |
| A new transaction is saved but never appears | It has no `createdAt` | Save through the repository's `add`, which stamps `createdAt`. Documents added by hand in the console need a `createdAt` timestamp too. |
| `Tried to listen to a value exposed with provider, from outside of the widget tree` | `watch` used in button code | Inside `onPressed`, `onTap` or a save method, use `context.read` (step 14). |
| `A WalletState was used after being disposed` | The pipe outlived the brain | `dispose()` must call `_subscription?.cancel()` before `super.dispose()`. |
| `Don't use 'BuildContext's across async gaps` | Using `context` after an `await` | Read the brain before the first `await`; check `mounted` before using `context` after one. |
| `Undefined name 'myTransactions'` | You deleted it before every caller moved | Replace the remaining calls with brain methods (step 14), or put the function back until you have. |
| `'User' isn't a type` in the list screen | The `firebase_auth` import was removed | Keep `import 'package:firebase_auth/firebase_auth.dart';` in `wallet_screen.dart` (step 13). |
| Red imports after moving files | Paths are relative to the file | `'../models/txn.dart'` from a screen; `'screens/auth_gate.dart'` from `main.dart` (step 9). |
| `Target of URI doesn't exist: 'package:provider/provider.dart'` | The package is not installed | Run `flutter pub add provider`, then restart the app. |
| Edit creates an error or changes nothing | The id is empty | Call `edit(widget.txn!.id, txn)`: the form's new `txn` has no id. |

---

*AUCA Innovation Center · Mobile Programming · Session 7: State Management*
