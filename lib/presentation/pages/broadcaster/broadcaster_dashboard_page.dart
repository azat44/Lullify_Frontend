import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/repositories/broadcaster_repository.dart';
import 'package:lullify_mobile/presentation/providers/broadcaster_provider.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';
import 'package:lullify_mobile/presentation/widgets/vaporwave_text_field.dart';

class BroadcasterDashboardPage extends ConsumerStatefulWidget {
  const BroadcasterDashboardPage({super.key});

  @override
  ConsumerState<BroadcasterDashboardPage> createState() =>
      _BroadcasterDashboardPageState();
}

class _BroadcasterDashboardPageState
    extends ConsumerState<BroadcasterDashboardPage> {
  final _streamTitle = TextEditingController();
  final _mountPoint = TextEditingController();
  final _trackTitle = TextEditingController();
  final _trackArtist = TextEditingController();

  String? _selectedPlaylistId;
  String? _pickedFilePath;
  String? _pickedFileName;
  Uint8List? _pickedFileBytes;

  @override
  void dispose() {
    _streamTitle.dispose();
    _mountPoint.dispose();
    _trackTitle.dispose();
    _trackArtist.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac'],
      withData: true, // charge les bytes en mémoire : indispensable sur web
    );
    final file = result?.files.single;
    if (file != null) {
      setState(() {
        _pickedFilePath = file.path;   // null sur web, présent sur mobile/desktop
        _pickedFileBytes = file.bytes; // rempli sur web
        _pickedFileName = file.name;
        if (_trackTitle.text.isEmpty) {
          _trackTitle.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  String _formatFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return 'mp3';
    return name.substring(dot + 1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(broadcasterProvider);
    final notifier = ref.read(broadcasterProvider.notifier);

    ref.listen<BroadcasterState>(broadcasterProvider, (prev, next) {
      final msg = next.error ?? next.notice;
      if (msg != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor:
                next.error != null ? AppColors.hotPink : AppColors.surfaceLight,
          ));
        notifier.consumeMessages();
      }
    });

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Diffuseur'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StreamSection(
            state: state,
            titleController: _streamTitle,
            mountController: _mountPoint,
            onCreate: () {
              if (_streamTitle.text.trim().isEmpty ||
                  _mountPoint.text.trim().isEmpty) {
                return;
              }
              notifier.createStream(
                title: _streamTitle.text.trim(),
                description: '',
                mountPoint: _mountPoint.text.trim(),
              );
            },
            onToggleLive: notifier.toggleLive,
          ),
          const SizedBox(height: 28),
          _UploadSection(
            state: state,
            selectedPlaylistId: _selectedPlaylistId,
            pickedFileName: _pickedFileName,
            titleController: _trackTitle,
            artistController: _trackArtist,
            onSelectPlaylist: (id) => setState(() => _selectedPlaylistId = id),
            onPickFile: _pickFile,
            onNewPlaylist: () => _askNewPlaylist(context, notifier),
            onUpload: () {
              final playlistId = _selectedPlaylistId;
              final name = _pickedFileName;
              if (playlistId == null || name == null) return;
              notifier.uploadTrack(
                playlistId: playlistId,
                filePath: _pickedFilePath,
                fileBytes: _pickedFileBytes,
                fileName: name,
                title: _trackTitle.text.trim(),
                artist: _trackArtist.text.trim(),
                format: _formatFromName(name),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _askNewPlaylist(
      BuildContext context, BroadcasterNotifier notifier) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nouvelle playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Titre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (created == true && controller.text.trim().isNotEmpty) {
      final playlist = await notifier.createPlaylist(controller.text.trim());
      if (playlist != null && mounted) {
        setState(() => _selectedPlaylistId = playlist.id);
      }
    }
  }
}

class _StreamSection extends StatelessWidget {
  const _StreamSection({
    required this.state,
    required this.titleController,
    required this.mountController,
    required this.onCreate,
    required this.onToggleLive,
  });

  final BroadcasterState state;
  final TextEditingController titleController;
  final TextEditingController mountController;
  final VoidCallback onCreate;
  final VoidCallback onToggleLive;

  @override
  Widget build(BuildContext context) {
    final stream = state.stream;

    return _GlowCard(
      child: stream == null
          ? _buildCreateForm(context)
          : _buildControl(context, stream),
    );
  }

  Widget _buildCreateForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Créer ton stream'),
        const SizedBox(height: 16),
        VaporwaveTextField(
          label: 'Titre du stream',
          controller: titleController,
          hint: 'Lo-fi late night',
          prefixIcon: Icons.radio_rounded,
        ),
        const SizedBox(height: 16),
        VaporwaveTextField(
          label: 'Mount point',
          controller: mountController,
          hint: 'lofi-night',
          prefixIcon: Icons.link_rounded,
        ),
        const SizedBox(height: 20),
        _GradientButton(
          label: 'Créer le stream',
          icon: Icons.add_rounded,
          busy: state.busy,
          onPressed: onCreate,
        ),
      ],
    );
  }

  Widget _buildControl(BuildContext context, BroadcasterStream stream) {
    final live = stream.isLive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stream.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('/${stream.mountPoint}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _StatusPill(live: live),
          ],
        ),
        const SizedBox(height: 24),
        _GradientButton(
          label: live ? 'Arrêter le direct' : 'Passer en direct',
          icon: live ? Icons.stop_rounded : Icons.play_arrow_rounded,
          busy: state.busy,
          gradient: live
              ? const LinearGradient(
                  colors: [AppColors.hotPink, AppColors.grape])
              : AppColors.primaryGradient,
          onPressed: onToggleLive,
        ),
      ],
    );
  }
}

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.state,
    required this.selectedPlaylistId,
    required this.pickedFileName,
    required this.titleController,
    required this.artistController,
    required this.onSelectPlaylist,
    required this.onPickFile,
    required this.onNewPlaylist,
    required this.onUpload,
  });

  final BroadcasterState state;
  final String? selectedPlaylistId;
  final String? pickedFileName;
  final TextEditingController titleController;
  final TextEditingController artistController;
  final ValueChanged<String?> onSelectPlaylist;
  final VoidCallback onPickFile;
  final VoidCallback onNewPlaylist;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final canUpload = selectedPlaylistId != null && pickedFileName != null;

    return _GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Uploader une track'),
          Row(
            children: [
              Expanded(child: _playlistDropdown(context)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onNewPlaylist,
                icon: const Icon(Icons.playlist_add_rounded,
                    color: AppColors.neonCyan),
                tooltip: 'Nouvelle playlist',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FilePickerTile(fileName: pickedFileName, onTap: onPickFile),
          const SizedBox(height: 16),
          VaporwaveTextField(
            label: 'Titre',
            controller: titleController,
            hint: 'Nom de la track',
            prefixIcon: Icons.music_note_rounded,
          ),
          const SizedBox(height: 16),
          VaporwaveTextField(
            label: 'Artiste',
            controller: artistController,
            hint: 'Ton nom de prod',
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),
          if (state.uploadProgress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.uploadProgress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.neonCyan),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _GradientButton(
            label: 'Uploader',
            icon: Icons.cloud_upload_rounded,
            busy: state.busy,
            enabled: canUpload,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }

  Widget _playlistDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPlaylistId,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          hint: const Text('Choisir une playlist',
              style: TextStyle(color: AppColors.textMuted)),
          items: state.playlists
              .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title,
                        style:
                            const TextStyle(color: AppColors.textPrimary)),
                  ))
              .toList(),
          onChanged: onSelectPlaylist,
        ),
      ),
    );
  }
}

Widget _sectionTitle(String text) => Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.neonCyan,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );

class _GlowCard extends StatelessWidget {
  const _GlowCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepViolet.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (live ? AppColors.live : AppColors.textMuted)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (live ? AppColors.live : AppColors.textMuted)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: live ? AppColors.live : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            live ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              color: live ? AppColors.live : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  const _FilePickerTile({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.violet.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.audiotrack_rounded : Icons.upload_file_rounded,
              color: hasFile ? AppColors.neonCyan : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? 'Choisir un fichier audio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      hasFile ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool busy;
  final bool enabled;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Opacity(
      opacity: active ? 1 : 0.5,
      child: InkWell(
        onTap: active ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textPrimary),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.textPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}