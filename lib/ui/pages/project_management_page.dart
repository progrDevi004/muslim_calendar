import 'package:Taqvimi/ui/components/platform_adaptive_scaffold_fab.dart';

class ProjectManagementPage extends StatefulWidget {
  // ... (existing code)
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      floatingActionButton: Platform.isIOS
          ? Positioned(
              right: 16,
              bottom: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showAddProjectDialog,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 30,
                  ),
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _showAddProjectDialog,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            ),
    );
  }

  // ... (rest of the existing code)
}
