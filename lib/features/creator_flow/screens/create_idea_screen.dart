import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cthree/core/api/idea_repository.dart';

class LocalInspoPreview {
  final Map<String, dynamic> apiPayload;
  final String? previewUrl;
  final bool isLocalFile;
  final String? originalLink;

  LocalInspoPreview({
    required this.apiPayload,
    this.previewUrl,
    this.isLocalFile = false,
    this.originalLink,
  });
}

class CreateIdeaScreen extends StatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  State<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends State<CreateIdeaScreen> {
  final IdeaRepository _ideaRepo = IdeaRepository();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  final List<LocalInspoPreview> _inspos = [];
  
  bool _isUploadingInspo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editorFocusNode.addListener(() {
      if (_editorFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _showUnifiedAddInspoForm() {
    final TextEditingController linkController = TextEditingController();
    bool isFetching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Add Inspiration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("External URL", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: linkController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "e.g., YouTube or Instagram link",
                            hintStyle: const TextStyle(color: Color(0xFF6F7685)),
                            filled: true,
                            fillColor: const Color(0xFF1E222A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isFetching ? null : () async {
                          final url = linkController.text.trim();
                          if (url.isEmpty) return;

                          setModalState(() => isFetching = true);
                          
                          final payload = await _ideaRepo.generateLinkInspoPayload(url);
                          
                          if (payload != null && mounted) {
                            final previewUrl = payload['external_thumbnail_url'] ?? payload['temporary_thumbnail_url'];
                            
                            setState(() {
                              _inspos.add(LocalInspoPreview(
                                apiPayload: payload,
                                previewUrl: previewUrl,
                                originalLink: url,
                              ));
                            });
                            Navigator.pop(context);
                          } else {
                            setModalState(() => isFetching = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to parse link")));
                            }
                          }
                        },
                        child: isFetching
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Add Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(child: Text("OR", style: TextStyle(color: Color(0xFF6F7685), fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleImageUpload();
                      },
                      icon: Icon(Icons.upload, color: Theme.of(context).primaryColor, size: 20),
                      label: const Text("Upload Custom Image", style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _handleImageUpload() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploadingInspo = true);

    final payload = await _ideaRepo.generateDirectUploadInspoPayload(image);

    setState(() => _isUploadingInspo = false);

    if (payload != null) {
      setState(() {
        _inspos.add(LocalInspoPreview(
          apiPayload: payload,
          previewUrl: image.path,
          isLocalFile: true,
        ));
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
      }
    }
  }

  Future<void> _saveIdea() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
      return;
    }

    setState(() => _isSaving = true);

    final deltaJson = _quillController.document.toDelta().toJson();
    final descriptionPayload = {'ops': deltaJson};

    final insposPayload = _inspos.map((i) => i.apiPayload).toList();

    final newIdea = await _ideaRepo.createIdea(
      title: title,
      description: descriptionPayload,
      inspos: insposPayload,
    );

    setState(() => _isSaving = false);

    if (newIdea != null && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create idea")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color pinkAccent = Theme.of(context).colorScheme.secondary;
    final String? appFontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('New Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus(); 
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Workspace Title",
                      labelStyle: const TextStyle(color: Color(0xFF6F7685), fontSize: 14),
                      floatingLabelStyle: TextStyle(color: pinkAccent),
                      hintText: "e.g., Summer Workout Merch Drop",
                      hintStyle: const TextStyle(color: Color(0xFF6F7685), fontSize: 16, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFF1E222A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Inspirations", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      TextButton.icon(
                        onPressed: _isUploadingInspo ? null : _showUnifiedAddInspoForm,
                        icon: Icon(Icons.add_circle_rounded, size: 18, color: pinkAccent),
                        label: Text("Add", style: TextStyle(color: pinkAccent, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          backgroundColor: pinkAccent.withValues(alpha: 0.15),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_inspos.isNotEmpty || _isUploadingInspo)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._inspos.map((inspo) => _buildInspoThumbnail(inspo)),
                          if (_isUploadingInspo)
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E222A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: CircularProgressIndicator(color: pinkAccent)),
                            )
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  const Text("Canvas", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(primary: pinkAccent),
                      iconTheme: const IconThemeData(color: Colors.white70),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: quill.QuillSimpleToolbar(
                        controller: _quillController,
                        config: const quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showFontFamily: false,
                          showFontSize: false,
                          showSearchButton: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showInlineCode: false,
                          showCodeBlock: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showStrikeThrough: false,
                          showIndent: false,
                          showClearFormat: false,
                          showAlignmentButtons: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.copyWith(
                        bodyMedium: TextStyle(color: Colors.white, fontSize: 16, fontFamily: appFontFamily),
                        titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontFamily: appFontFamily),
                        titleLarge: TextStyle(color: Colors.white, fontSize: 16, fontFamily: appFontFamily),
                      ),
                    ),
                    child:DefaultTextStyle(
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.6, fontFamily: appFontFamily),
                      child: Container(
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E222A)),
                        ),
                        child: quill.QuillEditor.basic(
                          controller: _quillController,
                          focusNode: _editorFocusNode,
                          config: quill.QuillEditorConfig(
                            placeholder: "Start typing your master plan...",
                            customStyles: quill.DefaultStyles(
                              color: Colors.white,
                              paragraph: quill.DefaultTextBlockStyle(
                                TextStyle(color: Colors.white, fontSize: 16, height: 1.6, fontFamily: appFontFamily),
                                const quill.HorizontalSpacing(0, 0),
                                const quill.VerticalSpacing(0, 0),
                                const quill.VerticalSpacing(0.1, 0.1),
                                null
                              ),
                              placeHolder: quill.DefaultTextBlockStyle(
                                TextStyle(color: Color(0xFF6F7685), fontSize: 16, height: 1.6, fontFamily: appFontFamily),
                                const quill.HorizontalSpacing(0, 0),
                                const quill.VerticalSpacing(0, 0),
                                const quill.VerticalSpacing(0.1, 0.1),
                                null,
                              ),
                              h1: quill.DefaultTextBlockStyle(
                                TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: appFontFamily),
                                const quill.HorizontalSpacing(16, 0),
                                const quill.VerticalSpacing(0, 0),
                                const quill.VerticalSpacing(0.1, 0.1),
                                null,
                              ),
                              h2: quill.DefaultTextBlockStyle(
                                TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: appFontFamily),
                                const quill.HorizontalSpacing(12, 0),
                                const quill.VerticalSpacing(0, 0),
                                const quill.VerticalSpacing(0.1, 0.1),
                                null,
                              ),
                              // lists: quill.DefaultListBlockStyle(
                              //   TextStyle(color: Colors.white),
                              //   const quill.HorizontalSpacing(0, 0),
                              //   const quill.VerticalSpacing(0, 0),
                              //   const quill.VerticalSpacing(0, 0),
                              //   null,
                              //   null,
                              // ),
                              
                              
                            ),
                            
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
          
          Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF12151C),
              border: Border(top: BorderSide(color: Color(0xFF1E222A))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // Keeps your main brand blue
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveIdea,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Create Workspace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInspoThumbnail(LocalInspoPreview inspo) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A),
        borderRadius: BorderRadius.circular(12),
        image: inspo.previewUrl != null
            ? DecorationImage(
                image: inspo.isLocalFile 
                    ? FileImage(File(inspo.previewUrl!)) as ImageProvider
                    : NetworkImage(inspo.previewUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (inspo.previewUrl == null)
            const Center(child: Icon(Icons.link, color: Color(0xFF6F7685))),
          
          if (inspo.originalLink != null)
            Positioned(
              bottom: 4, left: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inspo.apiPayload['source_type'] ?? 'link',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            )
        ],
      ),
    );
  }
}