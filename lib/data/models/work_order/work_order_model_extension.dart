import 'package:fashionista/data/models/work_order/work_order_model.dart';

extension WorkOrderModelX on WorkOrderModel {
  WorkOrderModel copyWithModel(WorkOrderModel other) {
    return copyWith(
      uid: uid ?? other.uid,
      title: other.title,
      description: description ?? other.description,
      status: status ?? other.status,
      createdAt: createdAt ?? other.createdAt,
      updatedAt: updatedAt ?? other.updatedAt,
      createdBy: other.createdBy,
      featuredMedia: featuredMedia ?? other.featuredMedia,
      isBookmarked: other.isBookmarked,
      tags: tags ?? other.tags,
      client: client ?? other.client,
      startDate: startDate ?? other.startDate,
      dueDate: dueDate ?? other.dueDate,
    );
  }
}
