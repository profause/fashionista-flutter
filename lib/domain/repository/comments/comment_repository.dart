import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';

abstract class CommentRepository {
  Future<Either> addCommentToTrend(CommentModel comment);
  Future<Either> deleteCommentToTrend(CommentModel comment);
  Future<Either> findTrendComments(String uid);
}
