import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/db/database_service.dart';
import '../../services/db/storage_service.dart';
import '../../constants/app_constants.dart';
import '../../models/child_profile.dart';
import '../games_menu_screen.dart';
import '../activities/screening/screening_test_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;

  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isCheckingConnection = true;
  late AnimationController _animationController;
  final _db = DatabaseService();
  final _storage = StorageService();
  List<ChildProfile> _children = [];
  ChildProfile? _selectedChild;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _checkConnection();
    _loadChildren();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    final apiService = context.read<ApiService>();
    final connected = await apiService.checkHealth();
    setState(() {
      _isConnected = connected;
      _isCheckingConnection = false;
    });

    // Ya no se habla automáticamente al entrar
    // Solo hablará cuando el usuario seleccione una opción
  }

  Future<void> _loadChildren() async {
    if (widget.userId == null) return;

    try {
      // Asegurar que StorageService esté inicializado
      await _storage.initialize();

      _children = await _db.getChildrenByTutor(widget.userId!);

      // Cargar el niño seleccionado guardado o seleccionar el primero
      final savedChildId = _storage.prefs.getString('selected_child_id');
      if (savedChildId != null && _children.isNotEmpty) {
        try {
          _selectedChild = _children.firstWhere(
            (child) => child.id == savedChildId,
          );
        } catch (e) {
          // Si no se encuentra el niño guardado, seleccionar el primero
          _selectedChild = _children.first;
          await _storage.prefs.setString(
            'selected_child_id',
            _selectedChild!.id,
          );
        }
      } else if (_children.isNotEmpty) {
        _selectedChild = _children.first;
        await _storage.prefs.setString('selected_child_id', _selectedChild!.id);
      } else {
        _selectedChild = null;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Manejar error silenciosamente
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _selectChild() async {
    if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes crear un perfil de niño'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<ChildProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Niño'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _children.map((child) {
            return ListTile(
              leading: Icon(
                Icons.child_care,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(child.name),
              subtitle: Text('Edad: ${child.age} años'),
              selected: _selectedChild?.id == child.id,
              onTap: () => Navigator.pop(context, child),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _selectedChild = selected);
      await _storage.prefs.setString('selected_child_id', selected.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Niño seleccionado: ${selected.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _checkChildProfileBeforeActivity(VoidCallback onProceed) {
    // Validación estricta: debe haber niños Y debe haber uno seleccionado
    if (_children.isEmpty || _selectedChild == null) {
      showDialog(
        context: context,
        barrierDismissible: false, // No permitir cerrar tocando fuera
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 64,
          ),
          title: const Text(
            'Perfil de Niño Requerido',
            textAlign: TextAlign.center,
          ),
          content: Text(
            _children.isEmpty
                ? 'No tienes ningún perfil de niño creado.\n\nDebes crear al menos un perfil de niño antes de iniciar cualquier actividad. Los resultados se guardarán en el perfil del niño seleccionado.'
                : 'No hay ningún niño seleccionado.\n\nDebes seleccionar un perfil de niño antes de iniciar las actividades.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/profile-management',
                  arguments: widget.userId,
                ).then((_) {
                  _loadChildren();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Ir a Perfiles'),
            ),
          ],
        ),
      );
      return; // Importante: detener ejecución aquí
    }

    // Si pasa la validación, ejecutar la actividad
    onProceed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isCheckingConnection
                    ? _buildLoadingView()
                    : _buildActivityGrid(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón de selección de niño
          FloatingActionButton.extended(
            onPressed: _children.isEmpty ? null : _selectChild,
            icon: Icon(
              _children.isEmpty ? Icons.child_care_outlined : Icons.child_care,
            ),
            label: Text(
              _selectedChild?.name ?? 'Sin perfil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: _children.isEmpty
                ? Colors.grey
                : Theme.of(context).colorScheme.secondary,
            heroTag: 'child_selector',
          ),
          const SizedBox(height: 12),
          // Botón de perfil
          FloatingActionButton.extended(
            onPressed: () {
              if (widget.userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: No se encontró el ID de usuario'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                '/profile-management',
                arguments: widget.userId,
              ).then((_) => _loadChildren());
            },
            icon: const Icon(Icons.people),
            label: const Text('Perfiles'),
            heroTag: 'profile_button',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DyslexiaApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detección Inteligente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _checkConnection,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? Colors.green : Colors.red).withOpacity(
                    0.5,
                  ),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isConnected
                  ? 'Backend conectado - Modelo listo'
                  : 'Backend no disponible',
              style: TextStyle(
                color: _isConnected
                    ? Colors.green.shade900
                    : Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isConnected)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Conectando con el servidor...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        // Título sección
        Text(
          '¿Qué deseas hacer?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Test de Cribado
        _buildMainMenuCard(
          context,
          title: 'Test de Cribado',
          subtitle: '32 mini-tareas • ~15 minutos',
          description: 'Detección rápida de dislexia con IA',
          color: Colors.red,
          gradient: [Colors.red.shade700, Colors.red.shade900],
          icon: Icons.assignment_turned_in,
          onTap: () {
            _checkChildProfileBeforeActivity(() {
              if (!_isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Backend no disponible. Verifica la conexión.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreeningTestScreen(
                    userId: widget.userId!,
                    childId: _selectedChild!.id,
                  ),
                ),
              );
            });
          },
        ),

        const SizedBox(height: 16),

        // Juegos Educativos
        _buildMainMenuCard(
          context,
          title: 'Juegos Educativos',
          subtitle: '5 actividades interactivas',
          description: 'Practica y mejora tus habilidades',
          color: Colors.blue,
          gradient: [Colors.blue.shade700, Colors.blue.shade900],
          icon: Icons.sports_esports,
          onTap: () {
            _checkChildProfileBeforeActivity(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GamesMenuScreen(
                    userId: widget.userId!,
                    childId: _selectedChild!.id,
                  ),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildMainMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required List<Color> gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
