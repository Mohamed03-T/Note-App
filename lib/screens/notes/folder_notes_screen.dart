import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// recording and audio playback packages were removed to avoid build issues on some SDKs.

import '../../models/folder_model.dart';
import '../../models/note_model.dart';
// conditional audio service (mobile implementation uses native packages)
import '../../core/audio/audio.dart' as audio_service;

  // Light wrapper around the conditional audio service. Uses dynamic to avoid
  // hard dependency errors if mobile packages are not present until you
  // add them to pubspec.yaml and run `flutter pub get`.
  dynamic _audioSvc;

  void _initAudioService() {
    if (_audioSvc != null) return;
    try {
      _audioSvc = audio_service.createAudioService();
    } catch (_) {
      _audioSvc = null;
    }
  }

class FolderNotesScreen extends StatefulWidget {
  final FolderModel folder;
  final List<NoteModel> notes;

  const FolderNotesScreen({super.key, required this.folder, required this.notes});

  @override
  State<FolderNotesScreen> createState() => _FolderNotesScreenState();
}

class _FolderNotesScreenState extends State<FolderNotesScreen> {
  late List<NoteModel> _notes;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textCtl = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  List<String> _attachments = [];
  bool _isRecording = false;
  DateTime? _recordingStart;
  Timer? _recordingTimer;
  double _recordingLevel = 0.2; // for simple waveform animation

  // playback simulation state (since native audio packages were removed)
  final Map<String, double> _playbackProgress = {};
  final Map<String, bool> _isPlaying = {};
  final Map<String, int> _audioDurations = {}; // seconds
  final Map<String, Timer?> _playbackTimers = {};

  String _formatDuration(int seconds) {
    final s = seconds % 60;
    final m = seconds ~/ 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  void initState() {
    super.initState();
  _notes = List.from(widget.notes);
  // ensure chronological order: newest first so new notes appear at top
  _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  // audio playback not available on this build configuration
  }

  @override
  void dispose() {
    _textCtl.dispose();
  _textFocus.dispose();
    // stop any recording timer
    _recordingTimer?.cancel();
    // stop playback timers
    for (final t in _playbackTimers.values) {
      t?.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${widget.folder.title} (${_notes.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
  body: Builder(builder: (context) {
        // group notes by date (yyyy-mm-dd)
        final Map<String, List<NoteModel>> groups = {};
        for (final n in _notes) {
          final key = '${n.createdAt.year}-${n.createdAt.month.toString().padLeft(2, '0')}-${n.createdAt.day.toString().padLeft(2, '0')}';
          groups.putIfAbsent(key, () => []).add(n);
        }

        final sortedKeys = groups.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // newest first

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            for (final k in sortedKeys) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _DateHeaderDelegate(dateKey: k),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, idx) {
                    final n = groups[k]![idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Card(
                            color: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (n.title.trim().isNotEmpty) ? n.title : (n.content.length > 80 ? '${n.content.substring(0, 80)}...' : n.content),
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  // show attachments first (image/video/audio) then any text content below
                                  if (n.attachments.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: n.attachments.map((a) {
                                          final ext = a.toLowerCase();
                                          if (ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
                                                  // show sent images as thumbnails (120x80) in a wrap grid; tap to expand
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: GestureDetector(
                                                      onTap: () => _showFullScreenImage(a),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: kIsWeb
                                                            ? Image.network(a, fit: BoxFit.cover, width: 120, height: 80, errorBuilder: (c, e, s) => Container(width: 120, height: 80, color: Colors.grey.shade300))
                                                            : Image.file(File(a), fit: BoxFit.cover, width: 120, height: 80),
                                                      ),
                                                    ),
                                                  );
                                                } else if (ext.endsWith('.m4a') || ext.endsWith('.aac') || ext.endsWith('.wav') || ext.endsWith('.mp3')) {
                                            final dur = _audioDurations[a] ?? 5;
                                            final prog = _playbackProgress[a] ?? 0.0;
                                            final playing = _isPlaying[a] ?? false;
                                            return GestureDetector(
                                              onTap: () => _togglePlayback(a),
                                              child: Container(
                                                width: 220,
                                                margin: const EdgeInsets.only(top: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.blue.shade50),
                                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                  Icon(playing ? Icons.pause : Icons.play_arrow, size: 24, color: Colors.blue),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        LinearProgressIndicator(value: prog, backgroundColor: Colors.grey.shade300, color: Colors.blueAccent),
                                                        const SizedBox(height: 6),
                                                        Text('${_formatDuration((prog * dur).round())} / ${_formatDuration(dur)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                      ],
                                                    ),
                                                  ),
                                                ]),
                                              ),
                                            );
                                          }
                                          return Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.insert_drive_file, size: 24, color: Colors.grey), SizedBox(width: 8), Text('File', style: TextStyle(color: Colors.black54))]),
                                          );
                                        }).toList(),
                                      )
                                    ],
                                  // then the textual content (below attachments)
                                  if (n.content.trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(n.content, style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4)),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: groups[k]!.length,
                ),
              )
            ]
          ],
        );
      }),
      // bottom input bar for quick notes (always visible)
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(top: BorderSide(color: Colors.blue.shade200, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // live recording indicator (messenger-like)
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(_formatDuration(_recordingStart == null ? 0 : DateTime.now().difference(_recordingStart!).inSeconds), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          // simple waveform using bars
                          Expanded(
                            child: SizedBox(
                              height: 20,
                              child: Row(
                                children: List.generate(20, (i) {
                                  final h = 4 + (_recordingLevel * (i % 5 + 1) * 6).round();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 3,
                                      height: h.toDouble(),
                                      decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(2)),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.stop, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // quick formatting / tags bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _insertMarkdown('**', '**'),
                      icon: const Icon(Icons.format_bold, color: Colors.black),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      onPressed: () => _insertMarkdown('_', '_'),
                      icon: const Icon(Icons.format_italic, color: Colors.black),
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      onPressed: () => _insertMarkdown('- ', '\n- '),
                      icon: const Icon(Icons.format_list_bulleted, color: Colors.black),
                      tooltip: 'List',
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Container()),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text('#tags', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    )
                  ],
                ),

                // attachments preview strip (thumbnails above the input field)
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                    child: SizedBox(
                      height: 64,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _attachments.map((a) {
                            final ext = a.toLowerCase();
                            if (ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? Image.network(a, width: 96, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 96, height: 64, color: Colors.grey.shade300))
                                          : Image.file(File(a), width: 96, height: 64, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeAttachment(a),
                                        child: Container(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(2), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    IconButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.black),
                      tooltip: 'Camera',
                    ),
                    IconButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo, color: Colors.black),
                      tooltip: 'Gallery',
                    ),
                    // simple emoji picker
                    IconButton(
                      onPressed: _showEmojiPicker,
                      icon: const Text('😀', style: TextStyle(fontSize: 20)),
                      tooltip: 'Emoji',
                    ),
                    IconButton(
                      onPressed: _toggleRecording,
                      icon: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.red : Colors.black),
                      tooltip: 'Record',
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: TextField(
                                controller: _textCtl,
                                focusNode: _textFocus,
                                decoration: const InputDecoration(
                                  hintText: 'Write a note...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                minLines: 1,
                                maxLines: 6,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                            // attachments preview moved above — nothing here
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // send button
                    Container(
                      decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(28)),
                      child: IconButton(
                        onPressed: _sendNote,
                        icon: const Icon(Icons.send, color: Colors.white),
                        tooltip: 'Send',
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: InteractiveViewer(
              child: kIsWeb
                  ? Image.network(path, fit: BoxFit.contain, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade900))
                  : Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  // _attachmentsPreview removed — previews are now rendered inline in the input bar.

  Future<void> _pickImage(ImageSource src) async {
    try {
      final XFile? f = await _picker.pickImage(source: src, imageQuality: 80);
      if (f == null) return;
      if (!mounted) return; // avoid using context after async gap
      setState(() {
        _attachments.add(f.path);
      });
      // hide keyboard / unfocus so the preview strip is visible above the input
      FocusScope.of(context).unfocus();
      // ensure layout updates after return from picker
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      // ignore for now
    }
  }

  void _removeAttachment(String path) {
    setState(() {
      _attachments.remove(path);
    });
  }

  Future<void> _toggleRecording() async {
    // Start/stop simulated recording. When stopped, create a Note with an audio attachment
    if (_isRecording) {
      // stop
      _recordingTimer?.cancel();
      _initAudioService();
      final end = DateTime.now();
      final durationSec = _recordingStart == null ? 0 : end.difference(_recordingStart!).inSeconds;
      setState(() {
        _isRecording = false;
        _recordingStart = null;
        _recordingLevel = 0.2;
      });

      // create a pseudo filename (placeholder). In a real implementation this would be an actual file path.
      final filename = 'recorded_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // register playback metadata
      _audioDurations[filename] = durationSec > 0 ? durationSec : 1;
      _playbackProgress[filename] = 0.0;
      _isPlaying[filename] = false;
      _playbackTimers[filename] = null;

      // create note immediately (like messenger) showing the recorded audio
      final autoTitle = _generateAutoTitle(widget.folder.title, _notes.length + 1);
      final n = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        folderId: widget.folder.id,
        title: autoTitle,
        content: '',
        attachments: [filename],
        createdAt: DateTime.now(),
      );

      setState(() {
        _notes.insert(0, n);
      });

      // if an audio service wrote a real file path, replace the placeholder
      if (_audioSvc != null) {
        // try to stop recording using the service
        try {
          final path = await _audioSvc.stopRecording();
          if (path != null && path is String) {
            // update the note attachment to real path (only if still mounted)
            if (mounted) {
              setState(() {
                _notes[0] = NoteModel(
                  id: n.id,
                  folderId: n.folderId,
                  title: n.title,
                  content: n.content,
                  attachments: [path],
                  createdAt: n.createdAt,
                );
                // register metadata
                _audioDurations[path] = durationSec > 0 ? durationSec : 1;
                _playbackProgress[path] = 0.0;
                _isPlaying[path] = false;
              });
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording saved')));

        // scroll to top to reveal the new audio note
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    } else {
      // start
      setState(() {
        _isRecording = true;
        _recordingStart = DateTime.now();
        _recordingLevel = 0.2;
      });
      // initialize audio service and start real recording if available
      _initAudioService();
      if (_audioSvc != null) {
        try {
          await _audioSvc.startRecording();
        } catch (_) {}
      }
      // animate level (visual)
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        setState(() {
          _recordingLevel = 0.2 + (0.8 * (Random().nextDouble()));
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording started')));
    }
  }

  // Playback simulation helpers
  void _togglePlayback(String key) {
    final playing = _isPlaying[key] ?? false;
    if (playing) {
      _stopPlayback(key);
    } else {
      _startPlayback(key);
    }
  }

  void _startPlayback(String key) {
    final total = _audioDurations[key] ?? 5;
    _playbackTimers[key]?.cancel();
    _isPlaying[key] = true;
    _initAudioService();
    if (_audioSvc != null) {
      try {
        _audioSvc.play(key);
      } catch (_) {}
    }
    _playbackTimers[key] = Timer.periodic(const Duration(milliseconds: 300), (t) {
      final prog = (_playbackProgress[key] ?? 0.0) + (0.3 / (total));
      if (prog >= 1.0) {
        _stopPlayback(key);
        setState(() {
          _playbackProgress[key] = 1.0;
        });
      } else {
        setState(() {
          _playbackProgress[key] = prog;
        });
      }
    });
  }

  void _stopPlayback(String key) {
    _playbackTimers[key]?.cancel();
    _playbackTimers[key] = null;
    _isPlaying[key] = false;
    if (_audioSvc != null) {
      try {
        _audioSvc.stop();
      } catch (_) {}
    }
    // if reached end, reset progress slowly
    if ((_playbackProgress[key] ?? 0.0) >= 1.0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        setState(() {
          _playbackProgress[key] = 0.0;
        });
      });
    }
  }

  void _insertMarkdown(String left, String right) {
    final text = _textCtl.text;
    final sel = _textCtl.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);
    final newText = '$before$left$selected$right$after';
    _textCtl.text = newText;
    final newPos = (before + left + selected + right).length;
    _textCtl.selection = TextSelection.fromPosition(TextPosition(offset: newPos));
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final emojis = ['😀', '😂', '😍', '👍', '🙏', '🎉', '😅', '🤔'];
        return SizedBox(
          height: 160,
          child: GridView.count(
            crossAxisCount: 8,
            children: emojis.map((e) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertEmoji(e);
                },
                child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _insertEmoji(String emoji) {
    final text = _textCtl.text;
    final sel = _textCtl.selection;
    final pos = sel.start >= 0 ? sel.start : text.length;
    final before = text.substring(0, pos);
    final after = text.substring(pos);
    final newText = '$before$emoji$after';
    _textCtl.text = newText;
    final newPos = (before + emoji).length;
    _textCtl.selection = TextSelection.fromPosition(TextPosition(offset: newPos));
  // keep focus on the text field
  FocusScope.of(context).requestFocus(_textFocus);
  }

  void _sendNote() {
    final content = _textCtl.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return; // nothing to send

    // generate title automatically based on folder and note count
    final autoTitle = _generateAutoTitle(widget.folder.title, _notes.length + 1);
    final n = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      folderId: widget.folder.id,
      title: autoTitle,
      content: content,
      attachments: List.from(_attachments),
      createdAt: DateTime.now(),
    );

    setState(() {
      // newest first: insert at top
      _notes.insert(0, n);
      _textCtl.clear();
      _attachments.clear();
    });

    // scroll to top to show the new note
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAutoTitle(String folderTitle, int index) {
    final trimmed = folderTitle.trim();
    if (trimmed.isEmpty) return 'Note$index';
    final parts = trimmed.split(RegExp(r'\s+'));
    String raw;
    if (parts.length >= 2) {
      // take first letters of first two words
      final a = parts[0].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      final b = parts[1].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      raw = ((a.isNotEmpty ? a[0] : '') + (b.isNotEmpty ? b[0] : ''));
    } else {
      final w = parts[0].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (w.length >= 2) raw = w.substring(0, 2);
      else raw = w;
    }

    if (raw.isEmpty) return 'Note$index';

    // preserve case: if folder title is all lowercase, use lowercase prefix
    final useLower = trimmed == trimmed.toLowerCase();
    final prefix = useLower ? raw.toLowerCase() : raw.toUpperCase();
    return '$prefix$index';
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String dateKey;

  _DateHeaderDelegate({required this.dateKey});

  String _readable(String key) {
    // key is yyyy-MM-dd
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 1;
    final d = parts[2];
    // simple month short names
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final mName = months[m-1];
    return '$mName $d, $y';
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // center the date circle horizontally, draw a horizontal line through center
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: maxExtent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // horizontal line across full width
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(height: 1, color: Colors.blue.shade200),
              ),
            ),

            // centered outlined oval with black text inside
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.blue.shade600, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                // wider than tall -> oval
                width: 160,
                height: 56,
                child: Center(
                  child: Text(
                    _readable(dateKey),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
