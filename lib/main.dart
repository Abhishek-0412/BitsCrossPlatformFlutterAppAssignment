import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'afvuhJkel8bgIrrCQXD08CrPO7R8EpGhBfBcwRpU';
  final keyClientKey = 'K4ZJFLUeu6OcVvG9qxSJ63Xaff9l4ttkOooDZje6';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(
    home: TodoApp(),
    theme: ThemeData.dark(),
  ));
}

class TodoApp extends StatefulWidget {
  @override
  _TodoAppState createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<ParseObject>? _todos;
  List<ParseObject> _selectedTodos = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Todo'))
      ..orderByDescending('createdAt');

    try {
      final response = await queryBuilder.query();
      if (response.success) {
        final results = response.results;
        if (results != null) {
          setState(() {
            _todos = results.cast<ParseObject>();
          });
        } else {
          print('Error loading todos: Results are null');
        }
      } else {
        print('Error loading todos: ${response.error?.message}');
      }
    } catch (e) {
      print('Error loading todos: $e');
    }
  }

  Future<void> _addTodo() async {
    if (_todoController.text.trim().isNotEmpty) {
      final todo = ParseObject('Todo')
        ..set('title', _todoController.text)
        ..set('done', false)
        ..set('tag', _tagController.text);

      try {
        await todo.save();
        _loadTodos();
        _todoController.clear();
        _tagController.clear();
      } catch (e) {
        print('Error adding todo: $e');
      }
    }
  }

  Future<void> _toggleTodo(ParseObject todo) async {
    final newDoneValue = !(todo.get<bool>('done') ?? false);
    todo.set('done', newDoneValue);

    try {
      await todo.save();
      _loadTodos();
    } catch (e) {
      print('Error updating todo: $e');
    }
  }

  Future<void> _deleteTodo(ParseObject todo) async {
    try {
      await todo.delete();
      _loadTodos();
    } catch (e) {
      print('Error deleting todo: $e');
    }
  }

  void _toggleSelect(ParseObject todo) {
    setState(() {
      if (_selectedTodos.contains(todo)) {
        _selectedTodos.remove(todo);
      } else {
        _selectedTodos.add(todo);
      }
    });
  }

  Future<void> _deleteSelectedTodos() async {
    try {
      await Future.wait(_selectedTodos.map((todo) => todo.delete()));
      _loadTodos();
      setState(() {
        _selectedTodos.clear();
      });
    } catch (e) {
      print('Error deleting selected todos: $e');
    }
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
    });

    if (query.isNotEmpty) {
      final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Todo'))
        ..whereContains('title', query)
        ..orderByDescending('createdAt');

      try {
        final response = await queryBuilder.query();
        if (response.success) {
          final results = response.results;
          if (results != null) {
            setState(() {
              _todos = results.cast<ParseObject>();
            });
          } else {
            print('Error searching todos: Results are null');
          }
        } else {
          print('Error searching todos: ${response.error?.message}');
        }
      } catch (e) {
        print('Error searching todos: $e');
      }
    } else {
      _loadTodos();
    }

    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              )
            : Text('Todo App'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
                _loadTodos();
              },
            ),
        ],
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoController,
                decoration: InputDecoration(
                  hintText: 'Enter a new todo',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Enter a tag',
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addTodo,
                child: Text('Add Todo'),
              ),
              SizedBox(height: 16),
              _todos != null
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _todos!.length,
                      itemBuilder: (context, index) {
                        final todo = _todos![index];
                        final title = todo.get<String>('title') ?? '';
                        final done = todo.get<bool>('done') ?? false;
                        final tag = todo.get<String>('tag') ?? '';

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          child: ListTile(
                            title: Row(
                              children: [
                                Checkbox(
                                  value: _selectedTodos.contains(todo),
                                  onChanged: (_) => _toggleSelect(todo),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        decoration: done ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (tag.isNotEmpty) Text('Tag: $tag'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTodo(todo),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedTodos.isEmpty ? null : _deleteSelectedTodos,
                child: Text('Delete Selected'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
