import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_repository.dart';
import '../services/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  User? _user;
  UserProfile? _profile;
  late FirestoreRepository _repository;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'No hay una sesión activa.';
      });
      return;
    }

    _user = user;
    _repository = FirestoreRepository(uid: user.uid);
    try {
      var profile = await _repository.loadProfile();
      if (profile == null) {
        final email = user.email ?? '';
        final fallbackName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (email.contains('@') ? email.split('@').first : 'Usuario');
        profile = UserProfile(
          userId: user.uid,
          displayName: fallbackName,
          email: email,
          createdAt: user.metadata.creationTime,
        );
        await _repository.saveProfile(profile);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile!.displayName;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el perfil desde Firestore: $error';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _profile == null ||
        _user == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim();
      await _user!.updateDisplayName(name);
      final updated = _profile!.copyWith(
        displayName: name,
        email: _user!.email ?? _profile!.email,
      );
      await _repository.saveProfile(updated);
      if (!mounted) return;
      setState(() => _profile = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message ?? 'No se pudo actualizar el nombre.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el perfil: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    final user = _user;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviamos el correo de verificación.')),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message ?? 'No se pudo enviar el correo.',
        );
      }
    }
  }

  Future<void> _refreshVerificationStatus() async {
    final user = _user;
    if (user == null) return;
    try {
      await user.reload();
      if (!mounted) return;
      setState(() => _user = FirebaseAuth.instance.currentUser);
      if (_user?.emailVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo verificado correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase aún indica que el correo no está verificado.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error.message ?? 'No se pudo actualizar el estado del correo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _user;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundImage: user?.photoURL == null
                              ? null
                              : NetworkImage(user!.photoURL!),
                          child: user?.photoURL == null
                              ? Text(
                                  (profile?.displayName.isNotEmpty == true
                                          ? profile!.displayName[0]
                                          : 'F')
                                      .toUpperCase(),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile?.displayName ?? 'Perfil',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile?.email ?? user?.email ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Información personal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre visible',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Ingresa tu nombre'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _ReadOnlyProfileField(
                              label: 'Correo electrónico',
                              value:
                                  profile?.email ??
                                  user?.email ??
                                  'No disponible',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 12),
                            _ReadOnlyProfileField(
                              label: 'País',
                              value: profile?.country ?? 'Chile',
                              icon: Icons.public,
                            ),
                            const SizedBox(height: 12),
                            _ReadOnlyProfileField(
                              label: 'Moneda',
                              value:
                                  '${profile?.currency ?? 'CLP'} · Peso chileno',
                              icon: Icons.payments_outlined,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Guardar perfil'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (user != null && !user.emailVerified) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.mark_email_unread_outlined,
                                color: colorScheme.primary,
                              ),
                              title: const Text('Correo sin verificar'),
                              subtitle: const Text(
                                'Verifica tu correo para proteger tu cuenta.',
                              ),
                              trailing: TextButton(
                                onPressed: _sendVerificationEmail,
                                child: const Text('Enviar'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _refreshVerificationStatus,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Ya lo verifiqué'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (user?.emailVerified == true) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.verified_user,
                          color: colorScheme.tertiary,
                        ),
                        title: const Text('Correo verificado'),
                      ),
                    ),
                  ],
                  if (profile?.createdAt != null) ...[
                    const SizedBox(height: 12),
                    _ReadOnlyProfileField(
                      label: 'Cuenta creada',
                      value: Formatters.date(profile!.createdAt!),
                      icon: Icons.calendar_today,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => AuthService().signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
