import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/comment_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';

class DesignerFeedbackPage extends StatefulWidget {
  final Designer designer;
  const DesignerFeedbackPage({super.key, required this.designer});

  @override
  State<DesignerFeedbackPage> createState() => _DesignerFeedbackPageState();
}

class _DesignerFeedbackPageState extends State<DesignerFeedbackPage>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _feedbackController = TextEditingController();
  bool addFeedbackLoading = false;

  @override
  void initState() {
    context.read<DesignerFeedbackBloc>().add(
      LoadDesignerFeedback(widget.designer.uid),
    );
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: //commemts
      BlocBuilder<DesignerFeedbackBloc, DesignerFeedbackBlocState>(
        builder: (context, state) {
          switch (state) {
            case DesignerFeedbackLoading():
              return const Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(),
                ),
              );
            case DesignerFeedbackError(:final message):
              //debugPrint(message);
              return Center(child: Text("Error: $message"));
            case DesignerFeedbacksLoaded(:final comments):
              return ListView.separated(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(
                  height: .1,
                  thickness: .1,
                  indent: 40,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentWidget(
                    comment: comment,
                    onDelete: () async {
                      debugPrint("Delete feedback");
                      _deleteFeedback(comment);
                    },
                  );
                },
              );
            case DesignerFeedbackEmpty():
              return Center(
                child: PageEmptyWidget(
                  title: "No feedback yet",
                  subtitle: "Add new feedback to see them here.",
                  icon: Icons.comment_outlined,
                  iconSize: 48,
                  fontSize: 16,
                ),
              );
            default:
              return Center(
                child: PageEmptyWidget(
                  title: "No feedback yet",
                  subtitle: "Add new feedback to see them here.",
                  icon: Icons.comment_outlined,
                  iconSize: 48,
                  fontSize: 16,
                ),
              );
          }
        },
      ),

      /// 🟢 WhatsApp-style input
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Leave a feedback...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                addFeedbackLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addFeedback,
                        icon: Icon(Icons.send, color: colorScheme.primary),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFeedback(CommentModel comment) async {
    try {
      final result = await sl<FirebaseDesignersService>()
          .deleteFeedbackForDesigner(comment);

      result.fold(
        (failure) {
          setState(() {
            addFeedbackLoading = false;
          });
        },
        (comment) {
          context.read<DesignerFeedbackBloc>().add(
            LoadDesignerFeedback(widget.designer.uid),
          );
          setState(() {
            addFeedbackLoading = false;
          });
          _feedbackController.clear();
          FocusScope.of(context).unfocus();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ comment deleted successfully!")),
          );
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  Future<void> _addFeedback() async {
    try {
      final text = _feedbackController.text.trim();
      if (text.isNotEmpty) {
        setState(() {
          addFeedbackLoading = true;
        });
        // Dispatch your bloc event or call API here print("Send comment: $text");
        UserBloc userBloc = context.read<UserBloc>();
        User user = userBloc.state;
        String createdBy =
            user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
        //_buttonLoadingStateCubit.setLoading(true);
        final author = AuthorModel.empty().copyWith(
          uid: createdBy,
          name: user.fullName,
          avatar: user.profileImage,
        );

        final cId = Uuid().v4();

        final comment = CommentModel.empty().copyWith(
          uid: cId,
          text: text,
          author: author,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          refId: widget.designer.uid,
        );

        final result = await sl<FirebaseDesignersService>()
            .addFeedbackForDesigner(comment);

        result.fold(
          (failure) {
            setState(() {
              addFeedbackLoading = false;
            });
          },
          (comment) {
            context.read<DesignerFeedbackBloc>().add(
              LoadDesignerFeedback(widget.designer.uid),
            );
            setState(() {
              addFeedbackLoading = false;
            });
            _feedbackController.clear();
            FocusScope.of(context).unfocus();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ comment added successfully!")),
            );
          },
        );
      }
    } on firebase_auth.FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackController.dispose();
    super.dispose();
  }
}
