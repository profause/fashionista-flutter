import 'package:fashionista/core/auth/account_deletion_state.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/auth/session_cleanup_service.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/domain/usecases/account/delete_account_usecase.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionScreen extends StatefulWidget {
  final DeleteAccountUsecase? deleteAccountUsecase;
  final SessionCleanupService? sessionCleanup;
  final AccountDeletionState? deletionState;
  final String? privacyPolicyUrl;

  /// Test seam for the local cleanup step; production uses [sessionCleanup].
  final Future<void> Function(BuildContext context)? cleanupOverride;

  /// Test seam for the post-deletion navigation.
  final void Function(BuildContext context)? onDeletionComplete;

  const AccountDeletionScreen({
    super.key,
    this.deleteAccountUsecase,
    this.sessionCleanup,
    this.deletionState,
    this.privacyPolicyUrl,
    this.cleanupOverride,
    this.onDeletionComplete,
  });

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  static const _confirmation = 'DELETE';
  static const _fallbackPrivacyUrl = 'https://fashionista.app/privacy';

  final TextEditingController _controller = TextEditingController();
  bool _isDeleting = false;
  bool _canDelete = false;
  String? _error;

  AccountDeletionState get _deletionState =>
      widget.deletionState ?? sl<AccountDeletionState>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onConfirmationChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onConfirmationChanged)
      ..dispose();
    super.dispose();
  }

  void _onConfirmationChanged() {
    final canDelete = _controller.text == _confirmation;
    if (canDelete == _canDelete) return;
    setState(() => _canDelete = canDelete);
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting || !_canDelete) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    _deletionState.begin();

    String? failure;
    try {
      final result =
          await (widget.deleteAccountUsecase ?? sl<DeleteAccountUsecase>())
              .call(const DeleteAccountParams(confirmation: _confirmation));

      failure = result.fold((error) => error, (_) => null);
    } catch (_) {
      failure =
          'We could not delete your account. Please try again or contact '
          'support.';
    }

    if (!mounted) return;

    // The Auth user is deleted last on the server. If the call reports a
    // network/error response but the local credential is already gone, the
    // deletion did finish; continue with local cleanup instead of stranding the
    // user on a screen they can no longer authenticate from.
    if (failure != null && await _localAuthUserStillExists()) {
      _deletionState.end();
      setState(() {
        _isDeleting = false;
        _error = failure;
      });
      return;
    }

    await _finishDeletion();
  }

  Future<bool> _localAuthUserStillExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await user.reload();
      return FirebaseAuth.instance.currentUser != null;
    } on FirebaseAuthException catch (error) {
      return error.code != 'user-not-found';
    } catch (_) {
      // Firebase may not be initialised in widget tests; keep the error visible.
      return true;
    }
  }

  Future<void> _finishDeletion() async {
    try {
      if (widget.cleanupOverride != null) {
        await widget.cleanupOverride!(context);
      } else {
        await (widget.sessionCleanup ?? sl<SessionCleanupService>())
            .clearLocalSession(
              userBloc: context.read<UserBloc>(),
              authProviderCubit: context.read<AuthProviderCubit>(),
              signOut: false,
            );
      }
    } catch (_) {
      // Local cleanup is best-effort; the server account is already gone.
    }

    if (!mounted) return;
    if (widget.onDeletionComplete != null) {
      widget.onDeletionComplete!(context);
    } else {
      context.go('/sign-in?deleted=1');
    }
  }

  String get _privacyUrl {
    if (widget.privacyPolicyUrl != null) return widget.privacyPolicyUrl!;

    try {
      final configured = appConfig.get('privacy_policy_url');
      if (configured is String && configured.trim().isNotEmpty) {
        return configured.trim();
      }
    } catch (_) {
      // Remote Config may not be initialised in tests.
    }
    return _fallbackPrivacyUrl;
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.tryParse(_privacyUrl);
    if (uri == null || uri.scheme != 'https') {
      AppToast.error(context, 'The privacy policy is unavailable right now.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        AppToast.error(context, 'Could not open the privacy policy.');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not open the privacy policy.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: context.canvasBackground,
        appBar: AppBar(
          backgroundColor: context.canvasBackground,
          foregroundColor: context.onCanvasText,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: !_isDeleting,
          shape: Border(bottom: BorderSide(color: context.hairline)),
          title: const AppBarTitle(title: 'Delete account'),
        ),
        body: SafeArea(
          child: _isDeleting
              ? _buildProgress()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    Text(
                      'This will permanently delete your account',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This cannot be undone. The following data will be '
                      'removed from Fashionista:',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: context.accent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Consequence(
                      icon: Icons.person_outline,
                      text: 'Your profile, phone number and account settings',
                    ),
                    const _Consequence(
                      icon: Icons.photo_library_outlined,
                      text: 'Your posts, photos, videos and uploaded media',
                    ),
                    const _Consequence(
                      icon: Icons.favorite_border,
                      text: 'Your likes, comments, follows and reviews',
                    ),
                    const _Consequence(
                      icon: Icons.checkroom_outlined,
                      text: 'Your closet, outfits, clients and measurements',
                    ),
                    const _Consequence(
                      icon: Icons.notifications_none,
                      text: 'Your notifications and device registrations',
                    ),
                    const _Consequence(
                      icon: Icons.storefront_outlined,
                      text: 'Your designer profile, services and collections',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.hairline),
                      ),
                      child: Text(
                        'Active bookings and work orders will be cancelled. '
                        'Completed business records may be kept in an '
                        'anonymised form, without your name, contact details '
                        'or measurements.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: context.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openPrivacyPolicy,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Privacy Policy'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.accent,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Type DELETE to confirm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _canDelete ? _deleteAccount : null,
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _canDelete ? _deleteAccount : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          disabledBackgroundColor: colorScheme.error.withValues(
                            alpha: 0.25,
                          ),
                          disabledForegroundColor: colorScheme.onError
                              .withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete my account',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You will be signed out immediately after deletion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.placeholderText,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 22),
            Text(
              'Deleting your account…',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Please keep the app open. This can take a few moments for '
              'accounts with lots of posts or media.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: context.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Consequence({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: context.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.onCanvasText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
