import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('tasks');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      title: ' To-do App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFFF0F2F5),
        cardColor: Colors.white,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage>
    with TickerProviderStateMixin {
  final Box taskBox = Hive.box('tasks');
  String filter = 'All';
  bool showInput = false;
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  int? editingKey;

  List<Map> getTasks() {
    final tasks = taskBox.keys.map((key) {
      final item = taskBox.get(key);
      return {
        "key": key,
        "title": item['title'],
        "desc": item['desc'],
        "done": item['done']
      };
    }).toList();

    if (filter == 'Completed') {
      return tasks.where((item) => item['done'] == true).toList();
    } else if (filter == 'Incomplete') {
      return tasks.where((item) => item['done'] == false).toList();
    }
    return tasks;
  }

  void addOrUpdateTask() {
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    if (title.isEmpty) return;
    final task = {"title": title, "desc": desc, "done": false};
    if (editingKey == null) {
      taskBox.add(task);
    } else {
      taskBox.put(editingKey, task);
    }
    titleCtrl.clear();
    descCtrl.clear();
    editingKey = null;
    setState(() => showInput = false);
  }

  void deleteTask(int key) {
    taskBox.delete(key);
    setState(() {});
  }

  void toggleComplete(int key, bool done) {
    final task = taskBox.get(key);
    taskBox
        .put(key, {"title": task['title'], "desc": task['desc'], "done": done});
    setState(() {});
  }

  void editTask(Map task) {
    titleCtrl.text = task['title'];
    descCtrl.text = task['desc'];
    editingKey = task['key'];
    setState(() => showInput = true);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = getTasks();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'To-do App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            elevation: 20,
            iconColor: Colors.black,
            onSelected: (value) => setState(() => filter = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Completed', child: Text('Completed')),
              PopupMenuItem(value: 'Incomplete', child: Text('Incomplete')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          AnimatedCrossFade(
            duration: Duration(milliseconds: 300),
            crossFadeState: showInput
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26.0, vertical: 16.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Task Title',
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 2.0, color: Colors.indigo),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 2.0, color: Colors.indigo),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: addOrUpdateTask,
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text('Save Task',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                titleCtrl.clear();
                                descCtrl.clear();
                                editingKey = null;
                                setState(() => showInput = false);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.1),
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                              ),
                              child: Text('Cancel'),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            secondChild: SizedBox.shrink(),
          ),
          Expanded(
            
            child: tasks.isEmpty
                ? Center(
                  
                    child:
                        Text('No tasks found', style: TextStyle(fontSize: 18)))
                : ReorderableListView(
                    padding: EdgeInsets.all(8),
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      final items = taskBox.keys.toList();
                      final item = taskBox.get(items[oldIndex]);
                      taskBox.delete(items[oldIndex]);
                      final entries = taskBox.toMap().entries.toList();
                      taskBox.clear();
                      entries.insert(newIndex, MapEntry(items[oldIndex], item));
                      for (var entry in entries) {
                        taskBox.put(entry.key, entry.value);
                      }
                      setState(() {});
                    },
                    children: tasks.map((task) {
                      return Dismissible(
                        key: ValueKey(task["key"]),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          color: Colors.redAccent,
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => deleteTask(task['key']),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin:
                              EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            color:
                                task['done'] ? Colors.grey[200] : Colors.white,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              title: AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: task['done']
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                child: Text(task['title']),
                              ),
                              subtitle: task['desc'].toString().isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(task['desc']),
                                    )
                                  : null,
                              leading: AnimatedSwitcher(
                                duration: Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                        scale: animation, child: child),
                                child: Checkbox(
                                  key: ValueKey(task['done']),
                                  value: task['done'],
                                  onChanged: (val) =>
                                      toggleComplete(task['key'], val!),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.edit, color: Colors.indigo),
                                    onPressed: () => editTask(task),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    onPressed: () => deleteTask(task['key']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => showInput = !showInput),
        child: Icon(showInput ? Icons.close : Icons.add),
      ),
    );
  }
}
